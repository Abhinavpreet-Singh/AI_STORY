import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../models/app_state.dart';

class ReadStoryButton extends StatelessWidget {
  const ReadStoryButton({
    super.key,
    required this.ttsState,
    required this.onPressed,
    required this.onRetry,
    this.errorMessage,
  });

  final TtsState ttsState;
  final VoidCallback onPressed;
  final VoidCallback onRetry;
  final String? errorMessage;

  bool get _isLoading =>
      ttsState == TtsState.preparing || ttsState == TtsState.speaking;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          if (errorMessage != null) ...[
            _ErrorBanner(message: errorMessage!, onRetry: onRetry),
            const SizedBox(height: 12),
          ],
          SizedBox(
            width: double.infinity,
            height: 58,
            child: ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : (errorMessage != null ? onRetry : onPressed),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor:
                    AppColors.primary.withValues(alpha: 0.6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isLoading
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          ttsState == TtsState.preparing
                              ? 'Preparing story...'
                              : 'Reading aloud...',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          errorMessage != null
                              ? Icons.refresh_rounded
                              : Icons.volume_up_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          errorMessage != null
                              ? 'Try Again'
                              : 'Read Me a Story',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.sentiment_dissatisfied_rounded,
            color: AppColors.error.withValues(alpha: 0.8),
            size: 22,
          ),
          const SizedBox(width: 10),
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
