/// Builds a short highlight window around the word currently being spoken.
class HighlightHelper {
  HighlightHelper._();

  static const _forwardWords = 1;

  static ({int start, int end}) smooth({
    required String text,
    required int rawEnd,
  }) {
    if (text.isEmpty || rawEnd <= 0) {
      return (start: 0, end: 0);
    }

    final position = rawEnd.clamp(0, text.length);
    final start = _snapToWordStart(text, position);
    final wordEnd = _snapToWordEnd(text, position);
    final end = _expandWordsForward(text, wordEnd, _forwardWords);

    return (
      start: start,
      end: end.clamp(start, text.length),
    );
  }

  static int _snapToWordStart(String text, int index) {
    var i = index.clamp(0, text.length);

    if (i < text.length && (text[i] == ' ' || text[i] == '\n')) {
      while (i < text.length && (text[i] == ' ' || text[i] == '\n')) {
        i++;
      }
    }

    while (i > 0 && text[i - 1] != ' ' && text[i - 1] != '\n') {
      i--;
    }

    return i;
  }

  static int _snapToWordEnd(String text, int index) {
    var i = index.clamp(0, text.length);
    while (i < text.length && text[i] != ' ' && text[i] != '\n') {
      i++;
    }
    return i;
  }

  static int _expandWordsForward(String text, int index, int words) {
    var i = index;
    var count = 0;

    while (i < text.length && count < words) {
      while (i < text.length && (text[i] == ' ' || text[i] == '\n')) {
        i++;
      }
      while (i < text.length && text[i] != ' ' && text[i] != '\n') {
        i++;
      }
      count++;
    }

    return i;
  }
}
