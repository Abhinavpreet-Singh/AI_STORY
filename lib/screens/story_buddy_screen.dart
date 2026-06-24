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
import '../widgets/quiz_section.dart';
import '../widgets/read_story_button.dart';
import '../widgets/scorecard.dart';
import '../widgets/story_card.dart';
import '../widgets/welcome_banner.dart';

class StoryBuddyScreen extends ConsumerWidget {
  const StoryBuddyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(storyBuddyProvider);
    final story = ref.watch(storyContentProvider);
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

    final isSpeaking = state.ttsState == TtsState.speaking;
    final isPreparing = state.ttsState == TtsState.preparing;

    return CelebrationOverlay(
      show: state.showConfetti,
      child: Scaffold(
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
            child: quizAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (_, __) => Center(
                child: Text(
                  'Could not load quiz. Please restart.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              data: (quizSet) {
                if (state.phase == AppPhase.scorecard) {
                  return CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      const SliverToBoxAdapter(child: AppHeader()),
                      SliverToBoxAdapter(
                        child: Column(
                          children: [
                            const SizedBox(height: 12),
                            const BuddyCharacter(
                              isHappy: true,
                              isSpeaking: false,
                            ),
                            const SizedBox(height: 24),
                            Scorecard(
                              correctCount: state.correctCount,
                              totalQuestions: quizSet.questions.length,
                              wrongAttempts: state.wrongAttempts,
                              onPlayAgain: notifier.playAgain,
                            ),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ],
                  );
                }

                final currentQuestion = quizSet.questions[
                    state.questionIndex.clamp(0, quizSet.questions.length - 1)];

                return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    const SliverToBoxAdapter(child: AppHeader()),
                    SliverToBoxAdapter(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 500),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: (child, animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 0.05),
                                end: Offset.zero,
                              ).animate(animation),
                              child: child,
                            ),
                          );
                        },
                        child: state.showQuiz
                            ? _QuizPhase(
                                key: ValueKey('quiz_${state.questionIndex}'),
                                quiz: currentQuestion,
                                questionIndex: state.questionIndex + 1,
                                totalQuestions: quizSet.questions.length,
                                state: state,
                                onSelect: (option) =>
                                    notifier.selectAnswer(option, quizSet),
                              )
                            : _StoryPhase(
                                key: const ValueKey('story'),
                                story: story,
                                state: state,
                                isSpeaking: isSpeaking,
                                isPreparing: isPreparing,
                                onRead: notifier.readStory,
                                onRetry: notifier.retry,
                              ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _StoryPhase extends StatelessWidget {
  const _StoryPhase({
    super.key,
    required this.story,
    required this.state,
    required this.isSpeaking,
    required this.isPreparing,
    required this.onRead,
    required this.onRetry,
  });

  final StoryContent story;
  final StoryBuddyState state;
  final bool isSpeaking;
  final bool isPreparing;
  final VoidCallback onRead;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final showWelcome =
        state.ttsState == TtsState.idle && state.errorMessage == null;

    return Column(
      children: [
        const SizedBox(height: 8),
        BuddyCharacter(
          isHappy: state.isBuddyHappy,
          isSpeaking: isSpeaking || isPreparing,
        ),
        const SizedBox(height: 12),
        if (showWelcome) const WelcomeBanner(),
        StoryCard(
          story: story,
          isSpeaking: isSpeaking || isPreparing,
          highlightStart: state.highlightStart,
          highlightEnd: state.highlightEnd,
        ),
        const SizedBox(height: 24),
        ReadStoryButton(
          ttsState: state.ttsState,
          errorMessage: state.errorMessage,
          onPressed: onRead,
          onRetry: onRetry,
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _QuizPhase extends StatelessWidget {
  const _QuizPhase({
    super.key,
    required this.quiz,
    required this.questionIndex,
    required this.totalQuestions,
    required this.state,
    required this.onSelect,
  });

  final QuizQuestion quiz;
  final int questionIndex;
  final int totalQuestions;
  final StoryBuddyState state;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),
        BuddyCharacter(
          isHappy: state.isBuddyHappy,
          isSpeaking: false,
        ),
        const SizedBox(height: 24),
        QuizSection(
          question: quiz,
          selectedOption: state.selectedOption,
          answerState: state.quizAnswerState,
          shakeKey: state.shakeKey,
          onSelect: onSelect,
          questionIndex: questionIndex,
          totalQuestions: totalQuestions,
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}
