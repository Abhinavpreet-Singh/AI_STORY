import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_state.dart';
import '../models/quiz_question.dart';
import '../models/story_content.dart';
import '../services/story_read_repository.dart';
import '../services/story_services.dart';

final quizRepositoryProvider = Provider<QuizRepository>((ref) {
  return QuizRepository();
});

final storyReadRepositoryProvider = Provider<StoryReadRepository>((ref) {
  return StoryReadRepository();
});

final ttsServiceProvider = Provider<TtsService>((ref) {
  final service = TtsService();
  ref.onDispose(service.dispose);
  return service;
});

final quizSetProvider = FutureProvider<QuizSet>((ref) async {
  final storyId = ref.watch(
    storyBuddyProvider.select((state) => state.selectedStoryId),
  );
  if (storyId == null) {
    return const QuizSet(questions: []);
  }

  final repo = ref.watch(quizRepositoryProvider);
  return repo.loadQuizForStory(storyId);
});

class StoryBuddyNotifier extends StateNotifier<StoryBuddyState> {
  StoryBuddyNotifier(
    this._ttsService,
    this._readRepository,
  ) : super(const StoryBuddyState()) {
    _ttsSubscription = _ttsService.events.listen(_onTtsEvent);
    _progressSubscription = _ttsService.progress.listen(_onTtsProgress);
    _readRepository.load().then((_) {
      state = state.copyWith(readStoryIds: _readRepository.readIds);
    });
  }

  final TtsService _ttsService;
  final StoryReadRepository _readRepository;
  late final StreamSubscription<TtsPlaybackEvent> _ttsSubscription;
  late final StreamSubscription<TtsProgressEvent> _progressSubscription;

  StoryContent? get _currentStory {
    final id = state.selectedStoryId;
    if (id == null) return null;
    return StoryCatalog.byId(id);
  }

  void _onTtsProgress(TtsProgressEvent event) {
    state = state.copyWith(
      highlightStart: event.start,
      highlightEnd: event.end,
    );
  }

  void _onTtsEvent(TtsPlaybackEvent event) {
    final story = _currentStory;

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
      case TtsEventType.paused:
        state = state.copyWith(ttsState: TtsState.paused);
      case TtsEventType.resumed:
        state = state.copyWith(ttsState: TtsState.speaking);
      case TtsEventType.completed:
        if (story != null) {
          _readRepository.markRead(story.id).then((_) {
            state = state.copyWith(
              readStoryIds: _readRepository.readIds,
            );
          });
        }
        state = state.copyWith(
          ttsState: TtsState.completed,
          phase: AppPhase.storyComplete,
          showQuiz: false,
          isBuddyHappy: true,
          highlightStart: 0,
          highlightEnd: story?.text.length ?? 0,
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

  void selectStory(StoryContent story) {
    state = state.copyWith(
      selectedStoryId: story.id,
      phase: AppPhase.story,
      ttsState: TtsState.idle,
      showQuiz: false,
      errorMessage: null,
      quizAnswerState: QuizAnswerState.idle,
      selectedOption: null,
      isBuddyHappy: false,
      showConfetti: false,
      questionIndex: 0,
      correctCount: 0,
      wrongAttempts: 0,
      highlightStart: 0,
      highlightEnd: 0,
    );
  }

  void openStoryMenu() {
    state = state.copyWith(
      phase: AppPhase.storyMenu,
      showQuiz: false,
      ttsState: TtsState.idle,
      errorMessage: null,
    );
  }

  Future<void> readStory() async {
    final story = _currentStory;
    if (story == null) return;

    if (state.ttsState == TtsState.preparing ||
        state.ttsState == TtsState.speaking) {
      return;
    }

    if (state.ttsState == TtsState.paused) {
      await _ttsService.resume();
      return;
    }

    state = state.copyWith(
      ttsState: TtsState.preparing,
      errorMessage: null,
      phase: AppPhase.story,
      showQuiz: false,
      highlightStart: 0,
      highlightEnd: 0,
    );

    await _ttsService.speak(story.text);
  }

  Future<void> replayStory() async {
    await _ttsService.stop();
    state = state.copyWith(
      ttsState: TtsState.idle,
      phase: AppPhase.story,
      showQuiz: false,
      errorMessage: null,
      highlightStart: 0,
      highlightEnd: 0,
      isBuddyHappy: false,
    );
    await readStory();
  }

  void continueToQuiz() {
    state = state.copyWith(
      phase: AppPhase.quiz,
      showQuiz: true,
      questionIndex: 0,
      quizAnswerState: QuizAnswerState.idle,
      selectedOption: null,
      isBuddyHappy: false,
      showConfetti: false,
    );
  }

  Future<void> pauseStory() async {
    if (state.ttsState == TtsState.speaking) {
      await _ttsService.pause();
    }
  }

  Future<void> resumeStory() async {
    if (state.ttsState == TtsState.paused) {
      await _ttsService.resume();
    }
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
    state = StoryBuddyState(
      phase: AppPhase.storyMenu,
      readStoryIds: _readRepository.readIds,
    );
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
    this.phase = AppPhase.storyMenu,
    this.selectedStoryId,
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
    this.readStoryIds = const {},
  });

  final TtsState ttsState;
  final AppPhase phase;
  final String? selectedStoryId;
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
  final Set<String> readStoryIds;

  StoryBuddyState copyWith({
    TtsState? ttsState,
    AppPhase? phase,
    String? selectedStoryId,
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
    Set<String>? readStoryIds,
  }) {
    return StoryBuddyState(
      ttsState: ttsState ?? this.ttsState,
      phase: phase ?? this.phase,
      selectedStoryId: selectedStoryId ?? this.selectedStoryId,
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
      readStoryIds: readStoryIds ?? this.readStoryIds,
    );
  }
}

final storyBuddyProvider =
    StateNotifierProvider<StoryBuddyNotifier, StoryBuddyState>((ref) {
  final tts = ref.watch(ttsServiceProvider);
  final readRepo = ref.watch(storyReadRepositoryProvider);
  return StoryBuddyNotifier(tts, readRepo);
});

final selectedStoryProvider = Provider<StoryContent?>((ref) {
  final id = ref.watch(storyBuddyProvider).selectedStoryId;
  if (id == null) return null;
  return StoryCatalog.byId(id);
});
