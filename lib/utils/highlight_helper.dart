/// Builds a short trailing word window that stays in sync with narration.
class HighlightHelper {
  HighlightHelper._();

  /// Total words in the highlight window (current word + trailing context).
  static const _windowWords = 3;

  static ({int start, int end}) smooth({
    required String text,
    required int rawEnd,
  }) {
    if (text.isEmpty || rawEnd <= 0) {
      return (start: 0, end: 0);
    }

    final end = rawEnd.clamp(0, text.length);
    final wordEnd = _snapToWordEnd(text, end);
    const lookback = _windowWords - 1;
    final start = _expandWordsBackward(text, wordEnd, lookback);

    return (
      start: start,
      end: wordEnd.clamp(start, text.length),
    );
  }

  static int _snapToWordEnd(String text, int index) {
    var i = index.clamp(0, text.length);
    while (i < text.length && text[i] != ' ' && text[i] != '\n') {
      i++;
    }
    return i;
  }

  static int _expandWordsBackward(String text, int index, int words) {
    var i = index;
    var count = 0;

    while (i > 0 && count < words) {
      while (i > 0 && text[i - 1] == ' ') {
        i--;
      }
      while (i > 0 && text[i - 1] != ' ' && text[i - 1] != '\n') {
        i--;
      }
      count++;
    }

    return i;
  }
}
