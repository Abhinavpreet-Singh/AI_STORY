enum TtsState {
  idle,
  preparing,
  speaking,
  paused,
  completed,
  error,
}

enum AppPhase {
  storyMenu,
  story,
  storyComplete,
  quiz,
  scorecard,
}

enum QuizAnswerState {
  idle,
  wrong,
  correct,
}
