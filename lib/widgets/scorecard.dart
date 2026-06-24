import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

class Scorecard extends StatelessWidget {
  const Scorecard({
    super.key,
    required this.correctCount,
    required this.totalQuestions,
    required this.wrongAttempts,
    required this.onPlayAgain,
  });

  final int correctCount;
  final int totalQuestions;
  final int wrongAttempts;
  final VoidCallback onPlayAgain;

  int get _stars {
    if (correctCount == totalQuestions && wrongAttempts == 0) return 3;
    if (correctCount == totalQuestions) return 2;
    if (correctCount >= totalQuestions ~/ 2) return 1;
    return 0;
  }

  String get _message {
    if (_stars == 3) return 'Perfect! You are a story superstar!';
    if (_stars == 2) return 'Wonderful job! Pip is so proud of you!';
    if (_stars == 1) return 'Good effort! Keep exploring with Pip!';
    return 'Nice try! Read the story again and have another go!';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary.withValues(alpha: 0.95),
              AppColors.primaryDark,
            ],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.28),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            const Icon(
              Icons.emoji_events_rounded,
              color: AppColors.accent,
              size: 52,
            ),
            const SizedBox(height: 12),
            Text(
              'Your Scorecard',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontSize: 24,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              _message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.92),
                    height: 1.5,
                  ),
            ),
            const SizedBox(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                final filled = index < _stars;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(
                    filled ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: filled ? AppColors.accent : Colors.white38,
                    size: 36,
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),
            _StatRow(
              label: 'Correct answers',
              value: '$correctCount / $totalQuestions',
            ),
            const SizedBox(height: 10),
            _StatRow(
              label: 'Wrong tries',
              value: '$wrongAttempts',
            ),
            const SizedBox(height: 26),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: onPlayAgain,
                icon: const Icon(Icons.replay_rounded),
                label: const Text('Read Another Story'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.primaryDark,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
