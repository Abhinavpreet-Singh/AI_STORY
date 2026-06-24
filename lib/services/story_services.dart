import 'dart:async';
import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;

import '../models/quiz_question.dart';

class QuizRepository {
  Future<QuizSet> loadQuiz() async {
    final jsonString = await rootBundle.loadString('assets/data/quiz.json');
    final json = jsonDecode(jsonString);
    return QuizSet.fromJson(json);
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
  bool _nativeReady = false;
  bool _usingNativeTts = false;
  bool _completionSent = false;
  List<double> _characterEndTimes = [];
  String _spokenText = '';

  /// Uses your female voice from `.env` → `ELEVENLABS_VOICE_ID`.
  String get voiceId => dotenv.env['ELEVENLABS_VOICE_ID']?.trim() ?? '';

  String get _apiKey => dotenv.env['ELEVENLABS_API_KEY']?.trim() ?? '';

  Future<void> _initNativeTts() async {
    await _nativeTts.setLanguage('en-US');
    await _nativeTts.setSpeechRate(kIsWeb ? 0.92 : 0.48);
    await _nativeTts.setPitch(1.08);
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
        _progressController.add(TtsProgressEvent(start: start, end: end));
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
            'model_id': 'eleven_turbo_v2_5',
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

  Future<void> _speakWithElevenLabs(String text) async {
    final speech = await _fetchElevenLabsSpeech(text);
    _spokenText = text;
    _characterEndTimes = speech.characterEndTimes;

    await _player.setReleaseMode(ReleaseMode.stop);
    await _player.setVolume(1.0);

    _stateController.add(const TtsPlaybackEvent(TtsEventType.started));
    _progressController.add(const TtsProgressEvent(start: 0, end: 0));
    await _player.play(BytesSource(speech.audioBytes, mimeType: 'audio/mpeg'));
  }

  Future<void> _speakWithNative(String text) async {
    if (!_nativeReady) {
      await _initNativeTts();
    }

    _usingNativeTts = true;
    _spokenText = text;
    _characterEndTimes = [];
    _stateController.add(const TtsPlaybackEvent(TtsEventType.started));
    _progressController.add(const TtsProgressEvent(start: 0, end: 0));

    final result = await _nativeTts.speak(text);
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
    final startIndex = (endIndex - 24).clamp(0, endIndex);

    _progressController.add(
      TtsProgressEvent(start: startIndex, end: endIndex),
    );
  }

  Future<void> speak(String text) async {
    _stoppedByUser = false;
    _usingNativeTts = false;
    _completionSent = false;
    _spokenText = '';
    _characterEndTimes = [];
    _stateController.add(const TtsPlaybackEvent(TtsEventType.preparing));

    try {
      if (_apiKey.isNotEmpty && voiceId.isNotEmpty) {
        await _speakWithElevenLabs(text);
        return;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ElevenLabs unavailable, using device TTS: $e');
      }
    }

    try {
      await _speakWithNative(text);
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

  Future<void> stop() async {
    _stoppedByUser = true;
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

enum TtsEventType { preparing, started, completed, error, cancelled }

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
