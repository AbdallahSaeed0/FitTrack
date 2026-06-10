import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/exercise_model.dart';
import '../../data/models/program_model.dart';
import '../../data/models/workout_day_model.dart';
import '../programs/programs_provider.dart';
import 'template_data.dart';
import 'template_models.dart';

// ── Muscle → icon / color helpers ─────────────────────────────────────────────

IconData _muscleIcon(String muscle) {
  switch (muscle.toLowerCase()) {
    case 'chest':
      return Icons.favorite_rounded;
    case 'back':
      return Icons.airline_seat_flat_rounded;
    case 'shoulders':
      return Icons.accessibility_new_rounded;
    case 'arms':
    case 'biceps':
    case 'triceps':
      return Icons.sports_handball_rounded;
    case 'legs':
    case 'quads':
    case 'hamstrings':
      return Icons.directions_run_rounded;
    case 'calves':
      return Icons.hiking_rounded;
    case 'core':
      return Icons.crop_square_rounded;
    default:
      return Icons.fitness_center_rounded;
  }
}

Color _muscleColor(String muscle) {
  switch (muscle.toLowerCase()) {
    case 'chest':
      return const Color(0xFFF87171); // red
    case 'back':
      return const Color(0xFF60A5FA); // blue
    case 'shoulders':
      return const Color(0xFFA78BFA); // purple
    case 'arms':
    case 'biceps':
    case 'triceps':
      return const Color(0xFFFBBF24); // yellow
    case 'legs':
    case 'quads':
    case 'hamstrings':
      return const Color(0xFF34D399); // green
    case 'calves':
      return const Color(0xFF6EE7B7); // light green
    case 'core':
      return const Color(0xFFFCA5A5); // pink
    default:
      return AppColors.primaryBlue;
  }
}

// ── Public helper: show the preview sheet from anywhere ───────────────────────

Future<void> showTemplatePreview({
  required BuildContext context,
  required ProgramTemplate template,
  required VoidCallback onAdd,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF1E293B),
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => _TemplatePreviewSheet(
      template: template,
      onAdd: onAdd,
    ),
  );
}

// ── Cloning helper (shared by screen + wizard) ────────────────────────────────

ProgramModel buildProgramFromTemplate(ProgramTemplate template) {
  const uuid = Uuid();
  final days = template.workoutDays.asMap().entries.map((entry) {
    final i = entry.key;
    final day = entry.value;
    final exercises = day.exercises.map((et) {
      final repParts = et.reps.split('-');
      final repsFrom = repParts.first;
      final repsTo = repParts.length > 1 ? repParts.last : repParts.first;
      return ExerciseModel(
        id: uuid.v4(),
        name: et.name,
        gifUrl: '',
        sets: et.sets,
        repsFrom: repsFrom,
        repsTo: repsTo,
        restTime: et.restTime,
        targetMuscles: [et.muscle],
      );
    }).toList();
    return WorkoutDayModel(
      id: uuid.v4(),
      name: day.name,
      dayNumber: i + 1,
      exercises: exercises,
    );
  }).toList();

  return ProgramModel(
    id: uuid.v4(),
    name: template.name,
    splitType: template.daysPerWeek <= 3
        ? 'full_body'
        : template.daysPerWeek == 4
            ? 'upper_lower'
            : 'ppl',
    goal: template.goal,
    experienceLevel: template.difficulty,
    days: days,
  );
}

// ── Main templates browser screen ─────────────────────────────────────────────

class TemplatesScreen extends ConsumerStatefulWidget {
  const TemplatesScreen({super.key});

  @override
  ConsumerState<TemplatesScreen> createState() => _TemplatesScreenState();
}

class _TemplatesScreenState extends ConsumerState<TemplatesScreen> {
  String _search = '';
  String? _filterDifficulty;
  String? _filterGoal;

  List<ProgramTemplate> get _filtered {
    return kProgramTemplates.where((t) {
      if (_search.isNotEmpty &&
          !t.name.toLowerCase().contains(_search.toLowerCase()) &&
          !t.description.toLowerCase().contains(_search.toLowerCase())) {
        return false;
      }
      if (_filterDifficulty != null && t.difficulty != _filterDifficulty) {
        return false;
      }
      if (_filterGoal != null && t.goal != _filterGoal) return false;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Scaffold(
      appBar: AppBar(title: const Text('Program Templates')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search programs…',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () => setState(() => _search = ''),
                      )
                    : null,
                filled: true,
                fillColor: Theme.of(context).cardTheme.color,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _FilterChip(
                  label: 'Beginner',
                  selected: _filterDifficulty == 'Beginner',
                  onTap: () => setState(() => _filterDifficulty =
                      _filterDifficulty == 'Beginner' ? null : 'Beginner'),
                  color: const Color(0xFF34D399),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Intermediate',
                  selected: _filterDifficulty == 'Intermediate',
                  onTap: () => setState(() => _filterDifficulty =
                      _filterDifficulty == 'Intermediate'
                          ? null
                          : 'Intermediate'),
                  color: const Color(0xFFFBBF24),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Advanced',
                  selected: _filterDifficulty == 'Advanced',
                  onTap: () => setState(() => _filterDifficulty =
                      _filterDifficulty == 'Advanced' ? null : 'Advanced'),
                  color: const Color(0xFFF87171),
                ),
                const SizedBox(width: 12),
                const SizedBox(
                    height: 20, child: VerticalDivider(width: 1)),
                const SizedBox(width: 12),
                _FilterChip(
                  label: 'Strength',
                  selected: _filterGoal == 'Strength',
                  onTap: () => setState(() => _filterGoal =
                      _filterGoal == 'Strength' ? null : 'Strength'),
                  color: AppColors.primaryBlue,
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Hypertrophy',
                  selected: _filterGoal == 'Hypertrophy',
                  onTap: () => setState(() => _filterGoal =
                      _filterGoal == 'Hypertrophy' ? null : 'Hypertrophy'),
                  color: AppColors.primaryBlue,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: filtered.isEmpty
                ? const _EmptySearch()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _TemplateCard(
                        template: filtered[i],
                        delay: i * 60,
                        onTap: () => _showPreview(context, filtered[i]),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _showPreview(BuildContext context, ProgramTemplate template) {
    showTemplatePreview(
      context: context,
      template: template,
      onAdd: () async {
        Navigator.of(context).pop();
        await _addProgram(context, template);
      },
    );
  }

  Future<void> _addProgram(
      BuildContext context, ProgramTemplate template) async {
    final program = buildProgramFromTemplate(template);
    await ref.read(programsProvider.notifier).addProgram(program);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.success, size: 20),
              const SizedBox(width: 10),
              Text('"${template.name}" added to your programs!'),
            ],
          ),
          backgroundColor: const Color(0xFF1E293B),
          action: SnackBarAction(
            label: 'View',
            textColor: AppColors.primaryBlue,
            onPressed: () => context.push('/programs/${program.id}'),
          ),
        ),
      );
    }
  }
}

// ── Filter chip ───────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color color;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color.withAlpha(40) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : Colors.white.withAlpha(40),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? color : Colors.white.withAlpha(150),
          ),
        ),
      ),
    );
  }
}

// ── Template list card ─────────────────────────────────────────────────────────

class _TemplateCard extends StatelessWidget {
  final ProgramTemplate template;
  final int delay;
  final VoidCallback onTap;

  const _TemplateCard(
      {required this.template, required this.delay, required this.onTap});

  Color get _difficultyColor {
    switch (template.difficulty) {
      case 'Beginner':
        return const Color(0xFF34D399);
      case 'Intermediate':
        return const Color(0xFFFBBF24);
      default:
        return const Color(0xFFF87171);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: Theme.of(context).dividerColor.withAlpha(60)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    template.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _difficultyColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    template.difficulty,
                    style: TextStyle(
                        color: _difficultyColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              template.description,
              style:
                  TextStyle(fontSize: 13, color: Colors.white.withAlpha(160)),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _StatPill(
                    icon: Icons.calendar_today_rounded,
                    label: '${template.daysPerWeek} days/week'),
                const SizedBox(width: 8),
                _StatPill(
                    icon: Icons.timer_rounded,
                    label: '~${template.avgMinutesPerSession} min'),
                const SizedBox(width: 8),
                _StatPill(
                    icon: Icons.flag_rounded, label: template.goal),
              ],
            ),
          ],
        ),
      )
          .animate()
          .fadeIn(
              delay: Duration(milliseconds: delay), duration: 350.ms)
          .slideX(
              begin: -0.05,
              end: 0,
              delay: Duration(milliseconds: delay),
              duration: 350.ms,
              curve: Curves.easeOut),
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.primaryBlue),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11, color: Colors.white.withAlpha(180))),
        ],
      ),
    );
  }
}

// ── Template preview bottom sheet ─────────────────────────────────────────────

class _TemplatePreviewSheet extends ConsumerStatefulWidget {
  final ProgramTemplate template;
  final VoidCallback onAdd;

  const _TemplatePreviewSheet({required this.template, required this.onAdd});

  @override
  ConsumerState<_TemplatePreviewSheet> createState() =>
      _TemplatePreviewSheetState();
}

class _TemplatePreviewSheetState extends ConsumerState<_TemplatePreviewSheet> {
  int _currentPage = 0;

  /// name → gifUrl (empty string = not found yet or load failed)
  final Map<String, String> _gifCache = {};

  @override
  void initState() {
    super.initState();
    _loadGifs();
  }

  Future<void> _loadGifs() async {
    final repo = ref.read(exerciseRepositoryProvider);
    final allNames = widget.template.workoutDays
        .expand((d) => d.exercises)
        .map((e) => e.name)
        .toSet();

    await Future.wait(allNames.map((name) async {
      try {
        final results = await repo.searchByName(name, limit: 1);
        if (results.isNotEmpty && mounted) {
          setState(() => _gifCache[name] = results.first.gifUrl);
        }
      } catch (_) {}
    }));
  }

  @override
  void dispose() {
    super.dispose();
  }

  Color get _difficultyColor {
    switch (widget.template.difficulty) {
      case 'Beginner':
        return const Color(0xFF34D399);
      case 'Intermediate':
        return const Color(0xFFFBBF24);
      default:
        return const Color(0xFFF87171);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.template;
    final days = t.workoutDays;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, controller) {
        return CustomScrollView(
          controller: controller,
          slivers: [
            // ── Handle bar ────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: Colors.white.withAlpha(40),
                          borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),

            // ── Title + difficulty badge ──────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(t.name,
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w800)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _difficultyColor.withAlpha(30),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(t.difficulty,
                          style: TextStyle(
                              color: _difficultyColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ),

            // ── Description ───────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Text(t.description,
                    style: TextStyle(
                        fontSize: 14, color: Colors.white.withAlpha(170))),
              ),
            ),

            // ── Stats row ─────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
                child: Row(
                  children: [
                    _InfoTile(
                        icon: Icons.calendar_today_rounded,
                        label: 'Days/Week',
                        value: '${t.daysPerWeek}'),
                    _InfoTile(
                        icon: Icons.timer_rounded,
                        label: 'Per Session',
                        value: '~${t.avgMinutesPerSession}m'),
                    _InfoTile(
                        icon: Icons.flag_rounded,
                        label: 'Goal',
                        value: t.goal),
                    _InfoTile(
                        icon: Icons.event_repeat_rounded,
                        label: 'Duration',
                        value: '${t.estimatedWeeks}w'),
                  ],
                ),
              ),
            ),

            // ── Equipment chips ───────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Equipment',
                        style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: t.equipment
                          .map((e) => Chip(
                                label: Text(e,
                                    style: const TextStyle(fontSize: 12)),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4),
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),

            // ── Day swiper section ────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  children: [
                    Text('Workout Days',
                        style: Theme.of(context).textTheme.labelLarge),
                    const Spacer(),
                    Text(
                      '${_currentPage + 1} / ${days.length}',
                      style: TextStyle(
                          fontSize: 12, color: Colors.white.withAlpha(120)),
                    ),
                  ],
                ),
              ),
            ),

            // ── Day selector chips ────────────────────────────────────────────
            if (days.length > 1)
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    itemCount: days.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final sel = i == _currentPage;
                      return GestureDetector(
                        onTap: () => setState(() => _currentPage = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 4),
                          decoration: BoxDecoration(
                            color: sel
                                ? AppColors.primaryBlue
                                : Colors.white.withAlpha(12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: sel
                                  ? AppColors.primaryBlue
                                  : Colors.white.withAlpha(30),
                            ),
                          ),
                          child: Text(
                            days[i].name,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: sel
                                  ? Colors.white
                                  : Colors.white.withAlpha(150),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

            // ── Day exercise count ────────────────────────────────────────────
            if (days.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                  child: Row(
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Text(
                          days[_currentPage].name,
                          key: ValueKey(_currentPage),
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${days[_currentPage].exercises.length} exercises',
                        style: TextStyle(
                            fontSize: 12, color: Colors.white.withAlpha(120)),
                      ),
                    ],
                  ),
                ),
              ),

            // ── Exercise grid — scrolls as part of the sheet ──────────────────
            if (days.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                sliver: SliverGrid.builder(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.82,
                  ),
                  itemCount: days[_currentPage].exercises.length,
                  itemBuilder: (_, i) {
                    final ex = days[_currentPage].exercises[i];
                    return _ExerciseGridCard(
                      exercise: ex,
                      index: i,
                      gifUrl: _gifCache[ex.name] ?? '',
                    ).animate().fadeIn(
                        delay: (i * 25).ms, duration: 250.ms);
                  },
                ),
              ),

            // ── Add button ───────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: widget.onAdd,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add to My Programs'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Exercise grid card ────────────────────────────────────────────────────────

class _ExerciseGridCard extends StatelessWidget {
  final ExerciseTemplate exercise;
  final int index;
  final String gifUrl;

  const _ExerciseGridCard({
    required this.exercise,
    required this.index,
    this.gifUrl = '',
  });

  @override
  Widget build(BuildContext context) {
    final color = _muscleColor(exercise.muscle);
    final icon = _muscleIcon(exercise.muscle);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Image / GIF area (top ~62%) ─────────────────────────────────────
          Expanded(
            flex: 5,
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(13)),
              child: _buildImage(color, icon),
            ),
          ),
          // ── Info area (bottom ~38%) ─────────────────────────────────────────
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withAlpha(25),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          exercise.muscle,
                          style: TextStyle(
                              fontSize: 9,
                              color: color,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${exercise.sets}×${exercise.reps}',
                        style: TextStyle(
                            fontSize: 9,
                            color: Colors.white.withAlpha(120),
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(Color color, IconData icon) {
    // Placeholder: coloured background with centred icon
    final placeholder = Container(
      color: color.withAlpha(15),
      child: Stack(
        children: [
          Positioned(
            right: -8,
            bottom: -8,
            child: Icon(icon, size: 80, color: color.withAlpha(25)),
          ),
          Center(
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withAlpha(35),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 28, color: color),
            ),
          ),
        ],
      ),
    );

    if (gifUrl.isEmpty) return placeholder;
    if (gifUrl.startsWith('assets/')) {
      return Image.asset(gifUrl,
          fit: BoxFit.cover, errorBuilder: (_, __, ___) => placeholder);
    }
    return Image.network(gifUrl,
        fit: BoxFit.cover, errorBuilder: (_, __, ___) => placeholder);
  }

}

// ── Info tile (stats row) ─────────────────────────────────────────────────────

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(10),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: AppColors.primaryBlue),
            const SizedBox(height: 4),
            Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 13)),
            Text(label,
                style: TextStyle(
                    fontSize: 10, color: Colors.white.withAlpha(120))),
          ],
        ),
      ),
    );
  }
}

// ── Empty search state ────────────────────────────────────────────────────────

class _EmptySearch extends StatelessWidget {
  const _EmptySearch();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded,
              size: 48, color: Colors.white.withAlpha(80)),
          const SizedBox(height: 12),
          Text('No programs match your filters',
              style: TextStyle(color: Colors.white.withAlpha(120))),
        ],
      ),
    );
  }
}
