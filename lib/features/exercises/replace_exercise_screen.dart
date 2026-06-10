import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/exercise_model.dart';
import '../../data/models/program_model.dart';
import '../../shared/widgets/exercise_gif_widget.dart';
import '../programs/programs_provider.dart';
import 'exercises_provider.dart';

class ReplaceExerciseScreen extends ConsumerStatefulWidget {
  final ProgramModel program;
  final int dayIndex;
  final int exerciseIndex;
  final ExerciseModel currentExercise;

  const ReplaceExerciseScreen({
    super.key,
    required this.program,
    required this.dayIndex,
    required this.exerciseIndex,
    required this.currentExercise,
  });

  @override
  ConsumerState<ReplaceExerciseScreen> createState() => _ReplaceExerciseScreenState();
}

const _kBodyParts = [
  'back', 'chest', 'shoulders', 'upper arms',
  'upper legs', 'lower legs', 'waist', 'lower arms',
];

class _ReplaceExerciseScreenState extends ConsumerState<ReplaceExerciseScreen> {
  final _searchController = TextEditingController();
  ExerciseModel? _selected;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bodyPart = widget.currentExercise.bodyParts.isNotEmpty
          ? widget.currentExercise.bodyParts.first
          : 'back';
      ref.read(exerciseSearchProvider.notifier).loadSimilar(bodyPart);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _label(String bp) {
    const labels = {
      'upper arms': 'Arms',
      'upper legs': 'Legs',
      'lower legs': 'Calves',
      'lower arms': 'Forearms',
    };
    return labels[bp] ?? bp[0].toUpperCase() + bp.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(exerciseSearchProvider);
    final selectedBp = searchState.selectedBodyPart;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Replace Exercise'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // ── Search field ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search exercises...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          ref
                              .read(exerciseSearchProvider.notifier)
                              .search('', bodyPart: selectedBp);
                        },
                      )
                    : null,
              ),
              onChanged: (q) {
                ref.read(exerciseSearchProvider.notifier).search(q);
              },
            ),
          ),
          // ── Body-part filter chips ───────────────────────────────────────
          SizedBox(
            height: 38,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _kBodyParts.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final bp = _kBodyParts[i];
                final active = selectedBp == bp;
                return FilterChip(
                  label: Text(_label(bp)),
                  selected: active,
                  onSelected: (_) {
                    final next = active ? null : bp;
                    ref.read(exerciseSearchProvider.notifier).setBodyPart(
                          next,
                          currentQuery: _searchController.text,
                        );
                  },
                  selectedColor: tealSuccess.withAlpha(40),
                  checkmarkColor: tealSuccess,
                  labelStyle: TextStyle(
                    color: active ? tealSuccess : null,
                    fontWeight:
                        active ? FontWeight.w700 : FontWeight.normal,
                    fontSize: 12,
                  ),
                  side: BorderSide(
                    color: active
                        ? tealSuccess
                        : Theme.of(context).dividerColor.withAlpha(80),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                  visualDensity: VisualDensity.compact,
                  showCheckmark: false,
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          // ── Result label ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _searchController.text.isEmpty && selectedBp == null
                    ? 'Similar Exercises'
                    : 'Results (${searchState.results.length})',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: searchState.isLoading
                ? const Center(child: CircularProgressIndicator(color: tealSuccess))
                : searchState.error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline_rounded, size: 48, color: primaryRed),
                            const SizedBox(height: 12),
                            Text(searchState.error!, textAlign: TextAlign.center),
                            TextButton(
                              onPressed: () {
                                final bodyPart = widget.currentExercise.bodyParts.isNotEmpty
                                    ? widget.currentExercise.bodyParts.first
                                    : 'chest';
                                ref.read(exerciseSearchProvider.notifier).loadSimilar(bodyPart);
                              },
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : searchState.results.isEmpty
                        ? const Center(child: Text('No exercises found'))
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: searchState.results.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final ex = searchState.results[index];
                              final isSelected = _selected?.id == ex.id;
                              return GestureDetector(
                                onTap: () => setState(() => _selected = ex),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isSelected ? tealSuccess.withAlpha(15) : Theme.of(context).cardTheme.color,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected ? tealSuccess : Theme.of(context).dividerColor.withAlpha(60),
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      ExerciseGifWidget(gifUrl: ex.gifUrl, exerciseName: ex.name, width: 44, height: 44, enableFullScreen: true),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(ex.name, style: Theme.of(context).textTheme.titleMedium),
                                            Text(
                                              [
                                                if (ex.bodyParts.isNotEmpty) ex.bodyParts.first,
                                                if (ex.equipments.isNotEmpty) ex.equipments.first,
                                              ].join(' · '),
                                              style: Theme.of(context).textTheme.bodySmall,
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (isSelected)
                                        const Icon(Icons.check_circle_rounded, color: tealSuccess),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
          ),
          if (_selected != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: _confirmReplacement,
                child: const Text('Confirm Replacement'),
              ),
            ),
        ],
      ),
    );
  }

  void _confirmReplacement() {
    if (_selected == null) return;
    HapticFeedback.mediumImpact();

    final replacement = _selected!.copyWith(
      sets: widget.currentExercise.sets,
      repsFrom: widget.currentExercise.repsFrom,
      repsTo: widget.currentExercise.repsTo,
      restTime: widget.currentExercise.restTime,
      technique: widget.currentExercise.technique,
      isNew: true,
    );

    final days = List.of(widget.program.days);
    final exercises = List.of(days[widget.dayIndex].exercises);
    exercises[widget.exerciseIndex] = replacement;
    final updatedDay = days[widget.dayIndex].copyWith(exercises: exercises);
    days[widget.dayIndex] = updatedDay;
    final updatedProgram = widget.program.copyWith(days: days);
    ref.read(programsProvider.notifier).updateProgram(updatedProgram);

    context.pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Replaced with ${_selected!.name}'),
        backgroundColor: tealSuccess,
      ),
    );
  }
}
