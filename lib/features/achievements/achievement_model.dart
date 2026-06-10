enum AchievementCategory { consistency, strength, milestones, nutrition, dedication }

class AchievementModel {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final AchievementCategory category;
  final bool isUnlocked;
  final DateTime? unlockedDate;
  final int currentProgress;
  final int targetProgress;

  const AchievementModel({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.category,
    this.isUnlocked = false,
    this.unlockedDate,
    this.currentProgress = 0,
    required this.targetProgress,
  });

  double get progressPercent =>
      targetProgress <= 0 ? 1.0 : (currentProgress / targetProgress).clamp(0.0, 1.0);

  AchievementModel copyWith({
    bool? isUnlocked,
    DateTime? unlockedDate,
    int? currentProgress,
  }) =>
      AchievementModel(
        id: id,
        title: title,
        description: description,
        emoji: emoji,
        category: category,
        isUnlocked: isUnlocked ?? this.isUnlocked,
        unlockedDate: unlockedDate ?? this.unlockedDate,
        currentProgress: currentProgress ?? this.currentProgress,
        targetProgress: targetProgress,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'isUnlocked': isUnlocked,
        'unlockedDate': unlockedDate?.toIso8601String(),
        'currentProgress': currentProgress,
      };

  AchievementModel applyJson(Map<String, dynamic> json) => copyWith(
        isUnlocked: json['isUnlocked'] as bool? ?? false,
        unlockedDate: json['unlockedDate'] != null
            ? DateTime.parse(json['unlockedDate'] as String)
            : null,
        currentProgress: (json['currentProgress'] as num?)?.toInt() ?? 0,
      );
}
