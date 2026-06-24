import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_state.dart';
import '../models/quiz_question.dart';
import '../models/story_content.dart';
import '../services/story_services.dart';

final quizRepositoryProvider = Provider<QuizRepository>((ref) {
  return QuizRepository();
});

final ttsServiceProvider = Provider<TtsService>((ref) {
  final service = TtsService();
  ref.onDispose(service.dispose);
  return service;
});

final storyContentProvider = Provider<StoryContent>((ref) {
  return StoryContent.defaultStory;
});

final quizSetProvider = FutureProvider<QuizSet>((ref) async {
  final repo = ref.watch(quizRepositoryProvider);
  return repo.loadQuiz();
});

class StoryBuddyNotifier extends StateNotifier<StoryBuddyState> {
  StoryBuddyNotifier(this._ttsService, this._story)
      : super(const StoryBuddyState()) {
    _ttsSubscription = _ttsService.events.listen(_onTtsEvent);
    _progressSubscription = _ttsService.progress.listen(_onTtsProgress);
  }

  final TtsService _ttsService;
  final StoryContent _story;
  late final StreamSubscription<TtsPlaybackEvent> _ttsSubscription;
  late final StreamSubscription<TtsProgressEvent> _progressSubscription;

  void _onTtsProgress(TtsProgressEvent event) {
    state = state.copyWith(
      highlightStart: event.start,
      highlightEnd: event.end,
    );
  }

  void _onTtsEvent(TtsPlaybackEvent event) {
    switch (event.type) {
      case TtsEventType.preparing:
        state = state.copyWith(
          ttsState: TtsState.preparing,
          errorMessage: null,
          highlightStart: 0,
          highlightEnd: 0,
        );
      case TtsEventType.started:
        state = state.copyWith(ttsState: TtsState.speaking);
      case TtsEventType.completed:
        state = state.copyWith(
          ttsState: TtsState.completed,
          phase: AppPhase.quiz,
          showQuiz: true,
          questionIndex: 0,
          quizAnswerState: QuizAnswerState.idle,
          selectedOption: null,
          isBuddyHappy: false,
          showConfetti: false,
          highlightStart: 0,
          highlightEnd: _story.text.length,
        );
      case TtsEventType.error:
        state = state.copyWith(
          ttsState: TtsState.error,
          errorMessage: event.message ??
              'Oops! Could not read the story. Please try again.',
        );
      case TtsEventType.cancelled:
        state = state.copyWith(
          ttsState: TtsState.idle,
          highlightStart: 0,
          highlightEnd: 0,
        );
    }
  }

  Future<void> readStory() async {
    if (state.ttsState == TtsState.preparing ||
        state.ttsState == TtsState.speaking) {
      return;
    }

    state = state.copyWith(
      ttsState: TtsState.preparing,
      errorMessage: null,
      phase: AppPhase.story,
      showQuiz: false,
      questionIndex: 0,
      quizAnswerState: QuizAnswerState.idle,
      selectedOption: null,
      isBuddyHappy: false,
      showConfetti: false,
      correctCount: 0,
      wrongAttempts: 0,
      highlightStart: 0,
      highlightEnd: 0,
    );

    await _ttsService.speak(_story.text);
  }

  Future<void> retry() async {
    await _ttsService.stop();
    state = state.copyWith(
      ttsState: TtsState.idle,
      errorMessage: null,
      highlightStart: 0,
      highlightEnd: 0,
    );
    await readStory();
  }

  Future<void> playAgain() async {
    await _ttsService.stop();
    state = const StoryBuddyState();
  }

  void selectAnswer(String option, QuizSet quizSet) {
    if (state.phase == AppPhase.scorecard) return;

    final question = quizSet.questions[state.questionIndex];

    if (question.isCorrect(option)) {
      final isLastQuestion =
          state.questionIndex >= quizSet.questions.length - 1;

      if (isLastQuestion) {
        state = state.copyWith(
          selectedOption: option,
          quizAnswerState: QuizAnswerState.correct,
          correctCount: state.correctCount + 1,
          isBuddyHappy: true,
          showConfetti: true,
          phase: AppPhase.scorecard,
        );
      } else {
        final currentIndex = state.questionIndex;
        state = state.copyWith(
          selectedOption: option,
          quizAnswerState: QuizAnswerState.correct,
          correctCount: state.correctCount + 1,
          isBuddyHappy: true,
          showConfetti: true,
        );

        Future.delayed(const Duration(milliseconds: 900), () {
          if (state.questionIndex == currentIndex &&
              state.quizAnswerState == QuizAnswerState.correct &&
              state.phase != AppPhase.scorecard) {
            state = state.copyWith(
              questionIndex: currentIndex + 1,
              quizAnswerState: QuizAnswerState.idle,
              selectedOption: null,
              isBuddyHappy: false,
              showConfetti: false,
            );
          }
        });
      }
    } else {
      state = state.copyWith(
        selectedOption: option,
        quizAnswerState: QuizAnswerState.wrong,
        wrongAttempts: state.wrongAttempts + 1,
        shakeKey: state.shakeKey + 1,
      );
    }
  }

  void resetWrongState() {
    if (state.quizAnswerState == QuizAnswerState.wrong) {
      state = state.copyWith(
        quizAnswerState: QuizAnswerState.idle,
        selectedOption: null,
      );
    }
  }

  @override
  void dispose() {
    _ttsSubscription.cancel();
    _progressSubscription.cancel();
    super.dispose();
  }
}

class StoryBuddyState {
  const StoryBuddyState({
    this.ttsState = TtsState.idle,
    this.phase = AppPhase.story,
    this.showQuiz = false,
    this.questionIndex = 0,
    this.errorMessage,
    this.selectedOption,
    this.quizAnswerState = QuizAnswerState.idle,
    this.isBuddyHappy = false,
    this.showConfetti = false,
    this.shakeKey = 0,
    this.highlightStart = 0,
    this.highlightEnd = 0,
    this.correctCount = 0,
    this.wrongAttempts = 0,
  });

  final TtsState ttsState;
  final AppPhase phase;
  final bool showQuiz;
  final int questionIndex;
  final String? errorMessage;
  final String? selectedOption;
  final QuizAnswerState quizAnswerState;
  final bool isBuddyHappy;
  final bool showConfetti;
  final int shakeKey;
  final int highlightStart;
  final int highlightEnd;
  final int correctCount;
  final int wrongAttempts;

  StoryBuddyState copyWith({
    TtsState? ttsState,
    AppPhase? phase,
    bool? showQuiz,
    int? questionIndex,
    String? errorMessage,
    String? selectedOption,
    QuizAnswerState? quizAnswerState,
    bool? isBuddyHappy,
    bool? showConfetti,
    int? shakeKey,
    int? highlightStart,
    int? highlightEnd,
    int? correctCount,
    int? wrongAttempts,
  }) {
    return StoryBuddyState(
      ttsState: ttsState ?? this.ttsState,
      phase: phase ?? this.phase,
      showQuiz: showQuiz ?? this.showQuiz,
      questionIndex: questionIndex ?? this.questionIndex,
      errorMessage: errorMessage,
      selectedOption: selectedOption,
      quizAnswerState: quizAnswerState ?? this.quizAnswerState,
      isBuddyHappy: isBuddyHappy ?? this.isBuddyHappy,
      showConfetti: showConfetti ?? this.showConfetti,
      shakeKey: shakeKey ?? this.shakeKey,
      highlightStart: highlightStart ?? this.highlightStart,
      highlightEnd: highlightEnd ?? this.highlightEnd,
      correctCount: correctCount ?? this.correctCount,
      wrongAttempts: wrongAttempts ?? this.wrongAttempts,
    );
  }
}

final storyBuddyProvider =
    StateNotifierProvider<StoryBuddyNotifier, StoryBuddyState>((ref) {
  final tts = ref.watch(ttsServiceProvider);
  final story = ref.watch(storyContentProvider);
  return StoryBuddyNotifier(tts, story);
});
