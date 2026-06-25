import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../models/app_state.dart';
import '../models/quiz_question.dart';
import '../models/story_content.dart';
import '../providers/story_buddy_provider.dart';
import '../widgets/app_header.dart';
import '../widgets/buddy_character.dart';
import '../widgets/celebration_overlay.dart';
import '../widgets/mobile_shell.dart';
import '../widgets/quiz_section.dart';
import '../widgets/scorecard.dart';
import '../widgets/story_card.dart';
import '../widgets/story_controls_bar.dart';
import '../widgets/story_menu.dart';

class StoryBuddyScreen extends ConsumerWidget {
  const StoryBuddyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(storyBuddyProvider);
    final story = ref.watch(selectedStoryProvider);
    final quizAsync = ref.watch(quizSetProvider);
    final notifier = ref.read(storyBuddyProvider.notifier);

    ref.listen<StoryBuddyState>(storyBuddyProvider, (previous, next) {
      if (next.quizAnswerState == QuizAnswerState.wrong &&
          previous?.quizAnswerState != QuizAnswerState.wrong) {
        Future.delayed(const Duration(milliseconds: 700), () {
          notifier.resetWrongState();
        });
      }
    });

    final narrationActive = state.ttsState == TtsState.speaking ||
        state.ttsState == TtsState.paused ||
        state.ttsState == TtsState.preparing;

    if (!state.isReady) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return CelebrationOverlay(
      show: state.showConfetti,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFF3ECFF),
                AppColors.surface,
                Color(0xFFFFF8E8),
              ],
            ),
          ),
          child: SafeArea(
            child: MobileViewport(
              child: _buildBody(
                state: state,
                story: story,
                quizAsync: quizAsync,
                notifier: notifier,
                narrationActive: narrationActive,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Widget _buildBody({
  required StoryBuddyState state,
  required StoryContent? story,
  required AsyncValue<QuizSet> quizAsync,
  required StoryBuddyNotifier notifier,
  required bool narrationActive,
}) {
  if (state.phase == AppPhase.storyMenu) {
    return MobileStoryShell(
      header: const AppHeader(),
      topSlot: const SizedBox(
        height: 96,
        child: Center(
          child: BuddyCharacter(
            isHappy: true,
            isSpeaking: false,
            compact: true,
          ),
        ),
      ),
      body: StoryMenu(
        stories: StoryCatalog.stories,
        readStoryIds: state.readStoryIds,
        selectedStoryId: state.selectedStoryId,
        inProgressStoryId: state.inProgressStoryId,
        onSelect: notifier.selectStory,
      ),
    );
  }

  if (state.phase == AppPhase.story || state.phase == AppPhase.storyComplete) {
    if (story == null) {
      return const Center(child: Text('Pick a story to begin!'));
    }

    return _StoryLayout(
      story: story,
      state: state,
      narrationActive: narrationActive,
      onStart: notifier.readStory,
      onPause: notifier.pauseStory,
      onContinue: notifier.resumeStory,
      onRetry: notifier.retry,
      onContinueToQuiz: notifier.continueToQuiz,
      onReplayStory: notifier.replayStory,
      onPickAnotherStory: notifier.openStoryMenu,
    );
  }

  return quizAsync.when(
    loading: () => const Center(
      child: CircularProgressIndicator(color: AppColors.primary),
    ),
    error: (_, __) => const Center(
      child: Text('Could not load quiz. Please restart.'),
    ),
    data: (quizSet) {
      if (state.phase == AppPhase.scorecard) {
        return MobileStoryShell(
          header: AppHeader(onMenuTap: notifier.openStoryMenu),
          topSlot: const SizedBox(
            height: 96,
            child: Center(
              child: BuddyCharacter(
                isHappy: true,
                isSpeaking: false,
                compact: true,
              ),
            ),
          ),
          body: ScrollPanel(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.all(12),
              child: Scorecard(
                correctCount: state.correctCount,
                totalQuestions: quizSet.questions.length,
                wrongAttempts: state.wrongAttempts,
                onPlayAgain: notifier.playAgain,
                embedButton: false,
              ),
            ),
          ),
          bottomBar: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: notifier.playAgain,
                icon: const Icon(Icons.library_books_rounded),
                label: const Text('Pick Another Story'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ),
        );
      }

      if (state.showQuiz) {
        final currentQuestion = quizSet.questions[
            state.questionIndex.clamp(0, quizSet.questions.length - 1)];

        return MobileStoryShell(
          header: AppHeader(onMenuTap: notifier.openStoryMenu),
          topSlot: SizedBox(
            height: 96,
            child: Center(
              child: BuddyCharacter(
                isHappy: state.isBuddyHappy,
                isSpeaking: false,
                compact: true,
              ),
            ),
          ),
          body: ScrollPanel(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: QuizSection(
                question: currentQuestion,
                selectedOption: state.selectedOption,
                answerState: state.quizAnswerState,
                shakeKey: state.shakeKey,
                onSelect: (o) => notifier.selectAnswer(o, quizSet),
                questionIndex: state.questionIndex + 1,
                totalQuestions: quizSet.questions.length,
              ),
            ),
          ),
        );
      }

      return const Center(child: Text('Pick a story to begin!'));
    },
  );
}

class _StoryLayout extends StatelessWidget {
  const _StoryLayout({
    required this.story,
    required this.state,
    required this.narrationActive,
    required this.onStart,
    required this.onPause,
    required this.onContinue,
    required this.onRetry,
    required this.onContinueToQuiz,
    required this.onReplayStory,
    required this.onPickAnotherStory,
  });

  final StoryContent story;
  final StoryBuddyState state;
  final bool narrationActive;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onContinue;
  final VoidCallback onRetry;
  final VoidCallback onContinueToQuiz;
  final VoidCallback onReplayStory;
  final VoidCallback onPickAnotherStory;

  @override
  Widget build(BuildContext context) {
    final storyFinished = state.phase == AppPhase.storyComplete;

    return MobileStoryShell(
      header: AppHeader(onMenuTap: onPickAnotherStory),
      topSlot: SizedBox(
        height: 96,
        child: Center(
          child: BuddyCharacter(
            isHappy: state.isBuddyHappy || storyFinished,
            isSpeaking: narrationActive,
            compact: true,
          ),
        ),
      ),
      body: StoryCard(
        story: story,
        isSpeaking: narrationActive,
        highlightStart: state.highlightStart,
        highlightEnd: state.highlightEnd,
        topBanner: storyFinished ? const _StoryFinishedBanner() : null,
      ),
      bottomBar: StoryControlsBar(
        ttsState: state.ttsState,
        phase: state.phase,
        errorMessage: state.errorMessage,
        onStart: onStart,
        onPause: onPause,
        onContinue: onContinue,
        onRetry: onRetry,
        onContinueToQuiz: onContinueToQuiz,
        onReplayStory: onReplayStory,
        onPickAnotherStory: onPickAnotherStory,
      ),
    );
  }
}

class _StoryFinishedBanner extends StatelessWidget {
  const _StoryFinishedBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.35)),
      ),
      child: const Row(
        children: [
          Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Story finished! Continue to quiz below.',
              style: TextStyle(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
