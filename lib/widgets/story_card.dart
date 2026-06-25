import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../models/story_content.dart';

class StoryCard extends StatefulWidget {
  const StoryCard({
    super.key,
    required this.story,
    required this.isSpeaking,
    required this.highlightStart,
    required this.highlightEnd,
    this.topBanner,
  });

  final StoryContent story;
  final bool isSpeaking;
  final int highlightStart;
  final int highlightEnd;
  final Widget? topBanner;

  @override
  State<StoryCard> createState() => _StoryCardState();
}

class _StoryCardState extends State<StoryCard> {
  final _scrollController = ScrollController();
  int _lastScrollStart = -1;
  DateTime? _lastScrollAt;

  @override
  void didUpdateWidget(StoryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSpeaking &&
        widget.highlightStart != oldWidget.highlightStart &&
        widget.highlightEnd > 0) {
      _autoScrollToHighlight();
    }
  }

  void _autoScrollToHighlight() {
    if (_lastScrollStart == widget.highlightStart) return;

    final now = DateTime.now();
    if (_lastScrollAt != null &&
        now.difference(_lastScrollAt!) < const Duration(milliseconds: 450)) {
      return;
    }

    _lastScrollStart = widget.highlightStart;
    _lastScrollAt = now;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;

      final style = Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontSize: 15,
            height: 1.7,
          );

      final textBefore = widget.story.text.substring(
        0,
        widget.highlightStart.clamp(0, widget.story.text.length),
      );

      final painter = TextPainter(
        text: TextSpan(text: textBefore, style: style),
        textAlign: TextAlign.justify,
        textDirection: TextDirection.ltr,
        maxLines: null,
      );

      final width = _scrollController.position.viewportDimension;
      if (width <= 0) return;

      painter.layout(maxWidth: width - 36);
      final highlightY = painter.height;
      final viewportH = _scrollController.position.viewportDimension;
      final target = (highlightY - viewportH * 0.28).clamp(
        0.0,
        _scrollController.position.maxScrollExtent,
      );

      _scrollController.jumpTo(target);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.isSpeaking;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.cardBg,
            AppColors.buddyBg.withValues(alpha: 0.45),
          ],
        ),
        border: Border.all(
          color: active
              ? AppColors.accent.withValues(alpha: 0.7)
              : AppColors.primary.withValues(alpha: 0.14),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: active ? 0.1 : 0.05),
            blurRadius: active ? 16 : 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Text(widget.story.emoji, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.story.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppColors.primaryDark,
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                      Text(
                        widget.story.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  active ? Icons.graphic_eq_rounded : Icons.menu_book_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
              ],
            ),
          ),
          if (widget.topBanner != null) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: widget.topBanner!,
            ),
          ],
          const SizedBox(height: 10),
          Expanded(
            child: Scrollbar(
              thumbVisibility: true,
              controller: _scrollController,
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: _HighlightedStoryText(
                  text: widget.story.text,
                  highlightStart: widget.highlightStart,
                  highlightEnd: widget.highlightEnd,
                  isSpeaking: active,
                ),
              ),
            ),
          ),
        ],
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
          fontSize: 15,
          height: 1.7,
          color: AppColors.textPrimary.withValues(alpha: 0.92),
        );

    final readStyle = baseStyle?.copyWith(
      color: AppColors.textPrimary.withValues(alpha: 0.45),
    );

    final highlightStyle = baseStyle?.copyWith(
      color: AppColors.primaryDark,
      fontWeight: FontWeight.w600,
      backgroundColor: AppColors.accent.withValues(alpha: 0.42),
      height: 1.75,
    );

    if (!isSpeaking || highlightEnd <= 0) {
      return Text(text, textAlign: TextAlign.justify, style: baseStyle);
    }

    final safeStart = highlightStart.clamp(0, text.length);
    final safeEnd = highlightEnd.clamp(safeStart, text.length);

    return Text.rich(
      TextSpan(
        style: baseStyle,
        children: [
          if (safeStart > 0)
            TextSpan(text: text.substring(0, safeStart), style: readStyle),
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
