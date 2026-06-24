import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../models/story_content.dart';

class StoryMenu extends StatelessWidget {
  const StoryMenu({
    super.key,
    required this.stories,
    required this.readStoryIds,
    required this.selectedStoryId,
    required this.onSelect,
  });

  final List<StoryContent> stories;
  final Set<String> readStoryIds;
  final String? selectedStoryId;
  final ValueChanged<StoryContent> onSelect;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      itemCount: stories.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final story = stories[index];
        final isRead = readStoryIds.contains(story.id);
        final isSelected = selectedStoryId == story.id;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onSelect(story),
            borderRadius: BorderRadius.circular(18),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : AppColors.cardBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.primary.withValues(alpha: 0.14),
                  width: isSelected ? 2 : 1.5,
                ),
                boxShadow: [
                  if (isSelected)
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                ],
              ),
              child: Row(
                children: [
                  Text(story.emoji, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          story.title,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryDark,
                                  ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          story.subtitle,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (isRead)
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: AppColors.success,
                        size: 18,
                      ),
                    )
                  else
                    Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.primary.withValues(alpha: 0.45),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
