/// Maps story display text to cleaner TTS input while keeping highlight indices aligned.
class SpeechTextMapper {
  SpeechTextMapper._({
    required this.displayText,
    required this.speechText,
    required List<int> speechToDisplay,
  }) : _speechToDisplay = speechToDisplay;

  final String displayText;
  final String speechText;
  final List<int> _speechToDisplay;

  factory SpeechTextMapper.fromDisplay(String display) {
    final buffer = StringBuffer();
    final speechToDisplay = <int>[];

    for (var displayIndex = 0; displayIndex < display.length; displayIndex++) {
      final ch = display[displayIndex];
      if (_isSilentForSpeech(ch)) continue;

      buffer.write(ch);
      speechToDisplay.add(displayIndex);
    }

    return SpeechTextMapper._(
      displayText: display,
      speechText: buffer.toString(),
      speechToDisplay: speechToDisplay,
    );
  }

  static bool _isSilentForSpeech(String ch) {
    switch (ch) {
      case '!':
      case '?':
      case '"':
      case '“':
      case '”':
      case '…':
        return true;
      default:
        return false;
    }
  }

  int toDisplayEnd(int speechEnd) {
    if (speechEnd <= 0 || _speechToDisplay.isEmpty) return 0;

    final index = (speechEnd - 1).clamp(0, _speechToDisplay.length - 1);
    return _speechToDisplay[index] + 1;
  }

  int toSpeechStart(int displayStart) {
    if (displayStart <= 0) return 0;

    for (var speechIndex = 0; speechIndex < _speechToDisplay.length; speechIndex++) {
      if (_speechToDisplay[speechIndex] >= displayStart) {
        return speechIndex;
      }
    }

    return _speechToDisplay.length;
  }
}
