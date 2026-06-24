import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_theme.dart';
import '../models/app_state.dart';
import '../models/quiz_question.dart';

class QuizSection extends StatelessWidget {
  const QuizSection({
    super.key,
    required this.question,
    required this.selectedOption,
    required this.answerState,
    required this.shakeKey,
    required this.onSelect,
    this.questionIndex = 1,
    this.totalQuestions = 1,
  });

  final QuizQuestion question;
  final String? selectedOption;
  final QuizAnswerState answerState;
  final int shakeKey;
  final ValueChanged<String> onSelect;
  final int questionIndex;
  final int totalQuestions;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (answerState == QuizAnswerState.wrong) ...[
          _WrongBanner(),
          const SizedBox(height: 14),
        ],
        if (answerState == QuizAnswerState.correct) ...[
          _MiniSuccessBanner(),
          const SizedBox(height: 14),
        ],
        _QuizShakeWrapper(
          shakeKey: answerState == QuizAnswerState.wrong ? shakeKey : 0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.12),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.05),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      if (totalQuestions > 1)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.buddyBg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Question $questionIndex of $totalQuestions',
                            style:
                                Theme.of(context).textTheme.labelLarge?.copyWith(
                                      color: AppColors.primary,
                                      fontSize: 12,
                                    ),
                          ),
                        ),
                      if (totalQuestions > 1) const SizedBox(height: 12),
                      Text(
                        question.question,
                        textAlign: TextAlign.center,
                        style:
                            Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryDark,
                                  height: 1.4,
                                ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              ...List.generate(question.options.length, (index) {
                final option = question.options[index];
                final isSelected = selectedOption == option;

                return Padding(
                  padding:
                      const EdgeInsets.only(left: 20, right: 20, bottom: 12),
                  child: _QuizOptionCard(
                    key: ValueKey('${option}_$shakeKey'),
                    label: option,
                    isSelected: isSelected,
                    isWrong:
                        isSelected && answerState == QuizAnswerState.wrong,
                    shakeKey: isSelected ? shakeKey : 0,
                    enabled: answerState != QuizAnswerState.correct,
                    onTap: () => onSelect(option),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}

class _WrongBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.sentiment_dissatisfied_rounded,
            color: AppColors.error.withValues(alpha: 0.9),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Not quite! Give it another try.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniSuccessBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.celebration_rounded, color: AppColors.success),
          const SizedBox(width: 8),
          Text(
            'Yes! Great answer!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _QuizShakeWrapper extends StatefulWidget {
  const _QuizShakeWrapper({
    required this.shakeKey,
    required this.child,
  });

  final int shakeKey;
  final Widget child;

  @override
  State<_QuizShakeWrapper> createState() => _QuizShakeWrapperState();
}

class _QuizShakeWrapperState extends State<_QuizShakeWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _shake;
  int _lastShakeKey = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _shake = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -12.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -12.0, end: 12.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 12.0, end: -10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _lastShakeKey = widget.shakeKey;
  }

  @override
  void didUpdateWidget(_QuizShakeWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shakeKey > 0 && widget.shakeKey != _lastShakeKey) {
      _lastShakeKey = widget.shakeKey;
      HapticFeedback.heavyImpact();
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shake,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shake.value, 0),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _QuizOptionCard extends StatefulWidget {
  const _QuizOptionCard({
    super.key,
    required this.label,
    required this.isSelected,
    required this.isWrong,
    required this.shakeKey,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final bool isWrong;
  final int shakeKey;
  final bool enabled;
  final VoidCallback onTap;

  @override
  State<_QuizOptionCard> createState() => _QuizOptionCardState();
}

class _QuizOptionCardState extends State<_QuizOptionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void didUpdateWidget(_QuizOptionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isWrong && !oldWidget.isWrong) {
      _pulseController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Color get _borderColor {
    if (widget.isWrong) return AppColors.error;
    if (widget.isSelected) return AppColors.primary;
    return AppColors.primary.withValues(alpha: 0.15);
  }

  Color get _bgColor {
    if (widget.isWrong) return AppColors.error.withValues(alpha: 0.12);
    if (widget.isSelected) return AppColors.primary.withValues(alpha: 0.06);
    return AppColors.cardBg;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final scale = widget.isWrong
            ? 1.0 + (_pulseController.value * 0.03)
            : 1.0;
        return Transform.scale(scale: scale, child: child);
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.enabled ? widget.onTap : null,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              color: _bgColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _borderColor, width: 2.5),
              boxShadow: widget.isWrong
                  ? [
                      BoxShadow(
                        color: AppColors.error.withValues(alpha: 0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.label,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                  ),
                ),
                _SelectionIndicator(
                  isSelected: widget.isSelected,
                  isWrong: widget.isWrong,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectionIndicator extends StatelessWidget {
  const _SelectionIndicator({
    required this.isSelected,
    required this.isWrong,
  });

  final bool isSelected;
  final bool isWrong;

  @override
  Widget build(BuildContext context) {
    if (isWrong) {
      return Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.15),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.error, width: 2),
        ),
        child: const Icon(Icons.close_rounded, color: AppColors.error, size: 16),
      );
    }

    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected
              ? AppColors.primary
              : AppColors.primary.withValues(alpha: 0.3),
          width: 2,
        ),
        color: isSelected
            ? AppColors.primary.withValues(alpha: 0.15)
            : Colors.transparent,
      ),
      child: isSelected
          ? Center(
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            )
          : null,
    );
  }
}
