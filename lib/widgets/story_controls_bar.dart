import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../models/app_state.dart';

class StoryControlsBar extends StatelessWidget {
  const StoryControlsBar({
    super.key,
    required this.ttsState,
    required this.phase,
    required this.onStart,
    required this.onPause,
    required this.onContinue,
    required this.onRetry,
    required this.onContinueToQuiz,
    required this.onReplayStory,
    required this.onPickAnotherStory,
    this.errorMessage,
  });

  final TtsState ttsState;
  final AppPhase phase;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onContinue;
  final VoidCallback onRetry;
  final VoidCallback onContinueToQuiz;
  final VoidCallback onReplayStory;
  final VoidCallback onPickAnotherStory;
  final String? errorMessage;

  bool get _isPreparing => ttsState == TtsState.preparing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (errorMessage != null) ...[
            _ErrorBanner(message: errorMessage!),
            const SizedBox(height: 10),
          ],
          if (phase == AppPhase.storyComplete) ...[
            _ActionButton(
              label: 'Continue to Quiz',
              icon: Icons.quiz_rounded,
              onPressed: onContinueToQuiz,
              color: AppColors.primary,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    label: 'Replay Story',
                    icon: Icons.replay_rounded,
                    onPressed: onReplayStory,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ActionButton(
                    label: 'More Stories',
                    icon: Icons.library_books_rounded,
                    onPressed: onPickAnotherStory,
                    color: AppColors.accent,
                    foregroundColor: AppColors.primaryDark,
                  ),
                ),
              ],
            ),
          ] else
            _buildPlaybackButton(),
        ],
      ),
    );
  }

  Widget _buildPlaybackButton() {
    if (_isPreparing) {
      return const _ActionButton(
        label: 'Preparing story...',
        icon: null,
        loading: true,
        onPressed: null,
        color: AppColors.primary,
      );
    }

    if (ttsState == TtsState.speaking) {
      return _ActionButton(
        label: 'Pause',
        icon: Icons.pause_rounded,
        onPressed: onPause,
        color: AppColors.primaryDark,
      );
    }

    if (ttsState == TtsState.paused) {
      return _ActionButton(
        label: 'Continue Story',
        icon: Icons.play_arrow_rounded,
        onPressed: onContinue,
        color: AppColors.primary,
      );
    }

    if (errorMessage != null) {
      return _ActionButton(
        label: 'Try Again',
        icon: Icons.refresh_rounded,
        onPressed: onRetry,
        color: AppColors.primary,
      );
    }

    return _ActionButton(
      label: 'Read Me a Story',
      icon: Icons.volume_up_rounded,
      onPressed: onStart,
      color: AppColors.primary,
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.onPressed,
    required this.color,
    this.icon,
    this.loading = false,
    this.foregroundColor = Colors.white,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final IconData? icon;
  final bool loading;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: foregroundColor,
          disabledBackgroundColor: color.withValues(alpha: 0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: loading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: foregroundColor.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      color: foregroundColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: foregroundColor, size: 20),
                    const SizedBox(width: 6),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: foregroundColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.sentiment_dissatisfied_rounded,
            color: AppColors.error.withValues(alpha: 0.85),
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
