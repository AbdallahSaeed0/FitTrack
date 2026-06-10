import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import 'achievement_model.dart';
import 'achievements_provider.dart';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(achievementsProvider);
    final unlocked = all.where((a) => a.isUnlocked).length;

    const categories = AchievementCategory.values;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withAlpha(30),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.success.withAlpha(80)),
                ),
                child: Text(
                  '$unlocked / ${all.length}',
                  style: const TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.w700,
                      fontSize: 13),
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: categories.length,
        itemBuilder: (context, catIdx) {
          final cat = categories[catIdx];
          final items = all.where((a) => a.category == cat).toList();
          if (items.isEmpty) return const SizedBox.shrink();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (catIdx > 0) const SizedBox(height: 24),
              _CategoryHeader(category: cat, items: items),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.1,
                ),
                itemCount: items.length,
                itemBuilder: (_, i) => _BadgeCard(
                  achievement: items[i],
                  delay: i * 60,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CategoryHeader extends StatelessWidget {
  final AchievementCategory category;
  final List<AchievementModel> items;

  const _CategoryHeader({required this.category, required this.items});

  String get _label {
    switch (category) {
      case AchievementCategory.consistency:
        return 'Consistency';
      case AchievementCategory.strength:
        return 'Strength';
      case AchievementCategory.milestones:
        return 'Milestones';
      case AchievementCategory.nutrition:
        return 'Nutrition';
      case AchievementCategory.dedication:
        return 'Dedication';
    }
  }

  String get _icon {
    switch (category) {
      case AchievementCategory.consistency:
        return '📆';
      case AchievementCategory.strength:
        return '💪';
      case AchievementCategory.milestones:
        return '🎯';
      case AchievementCategory.nutrition:
        return '🥗';
      case AchievementCategory.dedication:
        return '⏰';
    }
  }

  @override
  Widget build(BuildContext context) {
    final unlockedCount = items.where((a) => a.isUnlocked).length;
    return Row(
      children: [
        Text(_icon, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 8),
        Text(
          _label,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const Spacer(),
        Text(
          '$unlockedCount/${items.length}',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: AppColors.success),
        ),
      ],
    );
  }
}

class _BadgeCard extends StatelessWidget {
  final AchievementModel achievement;
  final int delay;

  const _BadgeCard({required this.achievement, required this.delay});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDetail(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: achievement.isUnlocked
                ? AppColors.success.withAlpha(120)
                : Theme.of(context).dividerColor.withAlpha(60),
            width: achievement.isUnlocked ? 1.5 : 1,
          ),
          boxShadow: achievement.isUnlocked
              ? [
                  BoxShadow(
                      color: AppColors.success.withAlpha(30),
                      blurRadius: 12,
                      spreadRadius: 2)
                ]
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: achievement.isUnlocked
                          ? AppColors.success.withAlpha(30)
                          : Colors.grey.withAlpha(20),
                    ),
                    alignment: Alignment.center,
                    child: ColorFiltered(
                      colorFilter: achievement.isUnlocked
                          ? const ColorFilter.mode(
                              Colors.transparent, BlendMode.multiply)
                          : const ColorFilter.matrix([
                              0.2, 0.7, 0.07, 0, 0,
                              0.2, 0.7, 0.07, 0, 0,
                              0.2, 0.7, 0.07, 0, 0,
                              0,   0,   0,    1, 0,
                            ]),
                      child: Text(achievement.emoji,
                          style: const TextStyle(fontSize: 28)),
                    ),
                  ),
                  if (!achievement.isUnlocked)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF475569),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(Icons.lock_rounded,
                            size: 11, color: Colors.white70),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                achievement.title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: achievement.isUnlocked
                      ? Colors.white
                      : Colors.white.withAlpha(120),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (!achievement.isUnlocked && achievement.currentProgress > 0) ...[
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: achievement.progressPercent,
                    backgroundColor: Colors.white.withAlpha(20),
                    valueColor:
                        const AlwaysStoppedAnimation(AppColors.primaryBlue),
                    minHeight: 4,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${achievement.currentProgress}/${achievement.targetProgress}',
                  style: TextStyle(
                      fontSize: 10, color: Colors.white.withAlpha(100)),
                ),
              ],
            ],
          ),
        ),
      )
          .animate()
          .fadeIn(delay: Duration(milliseconds: delay), duration: 400.ms)
          .scale(
              begin: const Offset(0.9, 0.9),
              end: const Offset(1, 1),
              delay: Duration(milliseconds: delay),
              duration: 300.ms,
              curve: Curves.easeOut),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _BadgeDetail(achievement: achievement),
    );
  }
}

class _BadgeDetail extends StatelessWidget {
  final AchievementModel achievement;
  const _BadgeDetail({required this.achievement});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MMMM d, yyyy');
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: achievement.isUnlocked
                  ? AppColors.success.withAlpha(30)
                  : Colors.grey.withAlpha(20),
              border: Border.all(
                  color: achievement.isUnlocked
                      ? AppColors.success
                      : Colors.grey.withAlpha(80)),
            ),
            alignment: Alignment.center,
            child: Text(achievement.emoji,
                style: const TextStyle(fontSize: 40)),
          ),
          const SizedBox(height: 16),
          Text(
            achievement.title,
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            achievement.description,
            style:
                TextStyle(fontSize: 14, color: Colors.white.withAlpha(170)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          if (achievement.isUnlocked && achievement.unlockedDate != null)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.success.withAlpha(30),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: AppColors.success, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Unlocked ${fmt.format(achievement.unlockedDate!)}',
                    style: const TextStyle(
                        color: AppColors.success,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            )
          else if (!achievement.isUnlocked) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: achievement.progressPercent,
                backgroundColor: Colors.white.withAlpha(20),
                valueColor:
                    const AlwaysStoppedAnimation(AppColors.primaryBlue),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${achievement.currentProgress} / ${achievement.targetProgress}',
              style: TextStyle(
                  fontSize: 13, color: Colors.white.withAlpha(120)),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
