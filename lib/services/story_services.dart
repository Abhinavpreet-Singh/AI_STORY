import 'dart:async';
import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;

import '../models/quiz_question.dart';
import '../utils/highlight_helper.dart';

class QuizRepository {
  Future<QuizSet> loadQuizForStory(String storyId) async {
    final jsonString = await rootBundle.loadString('assets/data/quiz.json');
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    final storyQuiz = json[storyId];

    if (storyQuiz == null) {
      throw StateError('No quiz found in quiz.json for story "$storyId"');
    }

    return QuizSet.fromJson(storyQuiz);
  }
}

class ElevenLabsSpeech {
  const ElevenLabsSpeech({
    required this.audioBytes,
    required this.characterEndTimes,
  });

  final Uint8List audioBytes;
  final List<double> characterEndTimes;
}

class TtsService {
  TtsService() {
    _initNativeTts();
    _player.onPlayerComplete.listen((_) => _onPlaybackFinished());
    _player.onPlayerStateChanged.listen((state) {
      if (state == PlayerState.completed) {
        _onPlaybackFinished();
      }
    });
    _player.onPositionChanged.listen(_onAudioPositionChanged);
  }

  final AudioPlayer _player = AudioPlayer();
  final FlutterTts _nativeTts = FlutterTts();
  final _stateController = StreamController<TtsPlaybackEvent>.broadcast();
  final _progressController = StreamController<TtsProgressEvent>.broadcast();

  Stream<TtsPlaybackEvent> get events => _stateController.stream;
  Stream<TtsProgressEvent> get progress => _progressController.stream;

  bool _stoppedByUser = false;
  bool _isPaused = false;
  bool _nativeReady = false;
  bool _usingNativeTts = false;
  bool _completionSent = false;
  List<double> _characterEndTimes = [];
  String _spokenText = '';
  int _resumeCharIndex = 0;
  int _speakOffset = 0;
  int _lastEmittedStart = -1;
  int _lastEmittedEnd = -1;

  int get resumeCharIndex => _resumeCharIndex;
  bool get isPaused => _isPaused;
  bool get hasActiveSession =>
      _spokenText.isNotEmpty && !_stoppedByUser && !_completionSent;

  /// Uses your female voice from `.env` → `ELEVENLABS_VOICE_ID`.
  String get voiceId => dotenv.env['ELEVENLABS_VOICE_ID']?.trim() ?? '';

  String get _apiKey => dotenv.env['ELEVENLABS_API_KEY']?.trim() ?? '';

  Future<void> _initNativeTts() async {
    await _nativeTts.setLanguage('en-US');
    await _nativeTts.setSpeechRate(kIsWeb ? 0.72 : 0.38);
    await _nativeTts.setPitch(1.05);
    await _nativeTts.setVolume(1.0);

    _nativeTts.setStartHandler(() {
      if (_usingNativeTts) {
        _stateController.add(const TtsPlaybackEvent(TtsEventType.started));
      }
    });

    _nativeTts.setCompletionHandler(() {
      if (_usingNativeTts) {
        _emitCompletedOnce();
      }
    });

    _nativeTts.setProgressHandler((text, start, end, word) {
      if (_usingNativeTts) {
        final absoluteEnd = (_speakOffset + end).clamp(0, _spokenText.length);
        _resumeCharIndex = absoluteEnd;
        _emitSyncedProgress(absoluteEnd);
      }
    });

    _nativeTts.setErrorHandler((message) {
      if (_usingNativeTts) {
        _stateController.add(
          TtsPlaybackEvent(
            TtsEventType.error,
            message: message ?? 'Could not read the story. Please try again.',
          ),
        );
      }
    });

    _nativeReady = true;
  }

  Future<ElevenLabsSpeech> _fetchElevenLabsSpeech(String text) async {
    if (_apiKey.isEmpty) {
      throw const _TtsConfigException('Missing ELEVENLABS_API_KEY in .env');
    }
    if (voiceId.isEmpty) {
      throw const _TtsConfigException('Missing ELEVENLABS_VOICE_ID in .env');
    }

    final response = await http
        .post(
          Uri.parse(
            'https://api.elevenlabs.io/v1/text-to-speech/$voiceId/with-timestamps',
          ),
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            'xi-api-key': _apiKey,
          },
          body: jsonEncode({
            'text': text,
            'model_id': 'eleven_multilingual_v2',
            'voice_settings': {
              'speed': 0.82,
              'stability': 0.55,
              'similarity_boost': 0.8,
            },
          }),
        )
        .timeout(const Duration(seconds: 45));

    if (response.statusCode != 200) {
      throw Exception('ElevenLabs ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final alignment = data['alignment'] as Map<String, dynamic>?;
    final endTimes = alignment == null
        ? <double>[]
        : List<double>.from(
            alignment['character_end_times_seconds'] as List? ?? [],
          );

    return ElevenLabsSpeech(
      audioBytes: base64Decode(data['audio_base64'] as String),
      characterEndTimes: endTimes,
    );
  }

  Future<void> _speakWithElevenLabs(String text, {int startIndex = 0}) async {
    final speech = await _fetchElevenLabsSpeech(text);
    _spokenText = text;
    _characterEndTimes = speech.characterEndTimes;
    _resumeCharIndex = startIndex.clamp(0, text.length);
    _resetProgressTracking();

    await _player.setReleaseMode(ReleaseMode.stop);
    await _player.setVolume(1.0);

    _stateController.add(const TtsPlaybackEvent(TtsEventType.started));
    if (startIndex > 0) {
      _emitSyncedProgress(startIndex);
    } else {
      _progressController.add(const TtsProgressEvent(start: 0, end: 0));
    }
    await _player.play(BytesSource(speech.audioBytes, mimeType: 'audio/mpeg'));
    if (startIndex > 0) {
      await _seekToCharIndex(startIndex);
    }
  }

  Future<void> _speakWithNative(String text, {int startIndex = 0}) async {
    if (!_nativeReady) {
      await _initNativeTts();
    }

    _usingNativeTts = true;
    _spokenText = text;
    _speakOffset = startIndex.clamp(0, text.length);
    _resumeCharIndex = _speakOffset;
    _characterEndTimes = [];
    _stateController.add(const TtsPlaybackEvent(TtsEventType.started));
    if (startIndex > 0) {
      _emitSyncedProgress(startIndex);
    } else {
      _progressController.add(const TtsProgressEvent(start: 0, end: 0));
    }

    final spoken = text.substring(_speakOffset);
    final result = await _nativeTts.speak(spoken);
    if (result != 1 && !kIsWeb) {
      throw Exception('Native TTS failed');
    }
  }

  void _onAudioPositionChanged(Duration position) {
    if (_usingNativeTts || _characterEndTimes.isEmpty || _spokenText.isEmpty) {
      return;
    }

    final seconds = position.inMilliseconds / 1000.0;
    var endIndex = 0;

    for (var i = 0; i < _characterEndTimes.length; i++) {
      if (_characterEndTimes[i] <= seconds) {
        endIndex = i + 1;
      } else {
        break;
      }
    }

    endIndex = endIndex.clamp(0, _spokenText.length);
    _resumeCharIndex = endIndex;
    _emitSyncedProgress(endIndex);
  }

  void _emitSyncedProgress(int rawEnd) {
    if (_spokenText.isEmpty) return;

    final window = HighlightHelper.smooth(
      text: _spokenText,
      rawEnd: rawEnd,
    );

    if (window.start == _lastEmittedStart && window.end == _lastEmittedEnd) {
      return;
    }

    _lastEmittedStart = window.start;
    _lastEmittedEnd = window.end;
    _progressController.add(
      TtsProgressEvent(start: window.start, end: window.end),
    );
  }

  void _resetProgressTracking() {
    _lastEmittedStart = -1;
    _lastEmittedEnd = -1;
  }

  Future<void> speak(String text, {int startIndex = 0}) async {
    _stoppedByUser = false;
    _isPaused = false;
    _usingNativeTts = false;
    _completionSent = false;
    _spokenText = '';
    _speakOffset = 0;
    _resumeCharIndex = startIndex.clamp(0, text.length);
    _characterEndTimes = [];
    _resetProgressTracking();
    _stateController.add(const TtsPlaybackEvent(TtsEventType.preparing));

    try {
      if (_apiKey.isNotEmpty && voiceId.isNotEmpty) {
        await _speakWithElevenLabs(text, startIndex: startIndex);
        return;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ElevenLabs unavailable, using device TTS: $e');
      }
    }

    try {
      await _speakWithNative(text, startIndex: startIndex);
    } catch (_) {
      _stateController.add(
        const TtsPlaybackEvent(
          TtsEventType.error,
          message:
              'Oops! Could not read the story. Check your connection and try again.',
        ),
      );
    }
  }

  double _timeForCharIndex(int index) {
    if (_characterEndTimes.isEmpty || index <= 0) return 0;
    final i = (index - 1).clamp(0, _characterEndTimes.length - 1);
    return _characterEndTimes[i];
  }

  Future<void> _seekToCharIndex(int charIndex) async {
    if (charIndex <= 0) return;

    final seconds = _timeForCharIndex(charIndex);
    await _player.seek(
      Duration(milliseconds: (seconds * 1000).round()),
    );
    _resumeCharIndex = charIndex;
    _emitSyncedProgress(charIndex);
  }

  void _onPlaybackFinished() {
    if (!_usingNativeTts && !_stoppedByUser) {
      _progressController.add(
        TtsProgressEvent(start: 0, end: _spokenText.length),
      );
      _emitCompletedOnce();
    }
  }

  void _emitCompletedOnce() {
    if (_completionSent || _stoppedByUser) return;
    _completionSent = true;
    _stateController.add(const TtsPlaybackEvent(TtsEventType.completed));
  }

  Future<void> pause() async {
    if (_completionSent || _isPaused) return;

    _isPaused = true;
    if (_usingNativeTts) {
      await _nativeTts.pause();
    } else {
      await _player.pause();
    }
    _stateController.add(const TtsPlaybackEvent(TtsEventType.paused));
  }

  Future<void> resume() async {
    if (!_isPaused) return;

    _isPaused = false;
    if (_usingNativeTts) {
      final offset = _resumeCharIndex.clamp(0, _spokenText.length);
      final remaining = _spokenText.substring(offset);
      if (remaining.trim().isEmpty) {
        _emitCompletedOnce();
        return;
      }
      _speakOffset = offset;
      await _nativeTts.speak(remaining);
    } else {
      await _player.resume();
    }
    _stateController.add(const TtsPlaybackEvent(TtsEventType.resumed));
  }

  Future<void> stop() async {
    _stoppedByUser = true;
    _isPaused = false;
    _usingNativeTts = false;
    await _player.stop();
    await _nativeTts.stop();
    _progressController.add(const TtsProgressEvent(start: 0, end: 0));
    _stateController.add(const TtsPlaybackEvent(TtsEventType.cancelled));
  }

  void dispose() {
    _player.dispose();
    _stateController.close();
    _progressController.close();
    _nativeTts.stop();
  }
}

class _TtsConfigException implements Exception {
  const _TtsConfigException(this.message);

  final String message;
}

enum TtsEventType {
  preparing,
  started,
  paused,
  resumed,
  completed,
  error,
  cancelled,
}

class TtsPlaybackEvent {
  const TtsPlaybackEvent(this.type, {this.message});

  final TtsEventType type;
  final String? message;
}

class TtsProgressEvent {
  const TtsProgressEvent({required this.start, required this.end});

  final int start;
  final int end;
}
