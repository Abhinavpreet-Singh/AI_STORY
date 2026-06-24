import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../models/story_content.dart';

class StoryCard extends StatelessWidget {
  const StoryCard({
    super.key,
    required this.story,
    required this.isSpeaking,
    required this.highlightStart,
    required this.highlightEnd,
  });

  final StoryContent story;
  final bool isSpeaking;
  final int highlightStart;
  final int highlightEnd;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.cardBg,
            AppColors.buddyBg.withValues(alpha: 0.45),
          ],
        ),
        border: Border.all(
          color: isSpeaking
              ? AppColors.accent.withValues(alpha: 0.7)
              : AppColors.primary.withValues(alpha: 0.14),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: isSpeaking ? 0.12 : 0.06),
            blurRadius: isSpeaking ? 22 : 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        story.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppColors.primaryDark,
                              fontSize: 18,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        story.subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                              fontStyle: FontStyle.italic,
                            ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isSpeaking
                        ? Icons.graphic_eq_rounded
                        : Icons.menu_book_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _HighlightedStoryText(
              text: story.text,
              highlightStart: highlightStart,
              highlightEnd: highlightEnd,
              isSpeaking: isSpeaking,
            ),
          ],
        ),
      ),
    );
  }
}

class _HighlightedStoryText extends StatelessWidget {
  const _HighlightedStoryText({
    required this.text,
    required this.highlightStart,
    required this.highlightEnd,
    required this.isSpeaking,
  });

  final String text;
  final int highlightStart;
  final int highlightEnd;
  final bool isSpeaking;

  @override
  Widget build(BuildContext context) {
    final baseStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
          fontSize: 15.5,
          height: 1.75,
          color: AppColors.textPrimary.withValues(alpha: 0.88),
        );

    final highlightStyle = baseStyle?.copyWith(
      color: AppColors.primaryDark,
      fontWeight: FontWeight.w600,
      backgroundColor: AppColors.accent.withValues(alpha: 0.35),
    );

    if (!isSpeaking || highlightEnd <= highlightStart) {
      return Text(
        text,
        textAlign: TextAlign.justify,
        style: baseStyle,
      );
    }

    final safeStart = highlightStart.clamp(0, text.length);
    final safeEnd = highlightEnd.clamp(safeStart, text.length);

    return Text.rich(
      TextSpan(
        style: baseStyle,
        children: [
          if (safeStart > 0) TextSpan(text: text.substring(0, safeStart)),
          TextSpan(
            text: text.substring(safeStart, safeEnd),
            style: highlightStyle,
          ),
          if (safeEnd < text.length) TextSpan(text: text.substring(safeEnd)),
        ],
      ),
      textAlign: TextAlign.justify,
    );
  }
}
