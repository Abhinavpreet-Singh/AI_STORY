class SavedStoryProgress {
  const SavedStoryProgress({
    required this.storyId,
    required this.charIndex,
    required this.highlightStart,
    required this.highlightEnd,
  });

  final String storyId;
  final int charIndex;
  final int highlightStart;
  final int highlightEnd;

  Map<String, dynamic> toJson() => {
        'storyId': storyId,
        'charIndex': charIndex,
        'highlightStart': highlightStart,
        'highlightEnd': highlightEnd,
      };

  factory SavedStoryProgress.fromJson(Map<String, dynamic> json) {
    return SavedStoryProgress(
      storyId: json['storyId'] as String,
      charIndex: json['charIndex'] as int? ?? 0,
      highlightStart: json['highlightStart'] as int? ?? 0,
      highlightEnd: json['highlightEnd'] as int? ?? 0,
    );
  }
}
