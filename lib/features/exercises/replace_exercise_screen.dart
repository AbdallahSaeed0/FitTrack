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

class _ReplaceExerciseScreenState extends ConsumerState<ReplaceExerciseScreen> {
  final _searchController = TextEditingController();
  ExerciseModel? _selected;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bodyPart = widget.currentExercise.bodyParts.isNotEmpty
          ? widget.currentExercise.bodyParts.first
          : 'chest';
      ref.read(exerciseSearchProvider.notifier).loadSimilar(bodyPart);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(exerciseSearchProvider);

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
          Padding(
            padding: const EdgeInsets.all(16),
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
                          final bodyPart = widget.currentExercise.bodyParts.isNotEmpty
                              ? widget.currentExercise.bodyParts.first
                              : 'chest';
                          ref.read(exerciseSearchProvider.notifier).loadSimilar(bodyPart);
                        },
                      )
                    : null,
              ),
              onChanged: (q) {
                if (q.length > 2) {
                  ref.read(exerciseSearchProvider.notifier).search(q);
                } else if (q.isEmpty) {
                  final bodyPart = widget.currentExercise.bodyParts.isNotEmpty
                      ? widget.currentExercise.bodyParts.first
                      : 'chest';
                  ref.read(exerciseSearchProvider.notifier).loadSimilar(bodyPart);
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  _searchController.text.isEmpty
                      ? 'Similar Exercises (Same Muscle Group)'
                      : 'Search Results',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
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
