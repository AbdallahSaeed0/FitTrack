import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/exercise_model.dart';
import '../../data/models/program_model.dart';
import 'programs_provider.dart';

class EditExerciseSheet extends ConsumerStatefulWidget {
  final ExerciseModel exercise;
  final ProgramModel program;
  final int dayIndex;
  final int exerciseIndex;

  const EditExerciseSheet({
    super.key,
    required this.exercise,
    required this.program,
    required this.dayIndex,
    required this.exerciseIndex,
  });

  @override
  ConsumerState<EditExerciseSheet> createState() => _EditExerciseSheetState();
}

class _EditExerciseSheetState extends ConsumerState<EditExerciseSheet> {
  late TextEditingController _setsController;
  late TextEditingController _repsFromController;
  late TextEditingController _repsToController;
  late TextEditingController _restController;
  late String _technique;
  late bool _linkWithPrevious;

  static const _techniques = [
    ('Standard', 'standard'),
    ('Drop Sets', 'drop_sets'),
    ('Supersets', 'supersets'),
    ('Giant Sets', 'giant_sets'),
    ('Rest-Pause', 'rest_pause'),
    ('Pyramid Sets', 'pyramid_sets'),
    ('Cluster Sets', 'cluster_sets'),
    ('Tempo Training', 'tempo_training'),
  ];

  static const _techniqueDescriptions = {
    'drop_sets': 'Reduce weight after failure, continue reps',
    'supersets': 'Two exercises back-to-back, no rest',
    'giant_sets': '3+ exercises combined in one block',
    'rest_pause': 'Hit failure, rest 15 sec, continue',
    'pyramid_sets': 'Increase weight, decrease reps each set',
    'cluster_sets': 'Short rest within sets for more volume',
    'tempo_training': 'Control the speed of each rep phase',
  };

  @override
  void initState() {
    super.initState();
    final e = widget.exercise;
    _setsController = TextEditingController(text: e.sets.toString());
    _repsFromController = TextEditingController(text: e.repsFrom);
    _repsToController = TextEditingController(text: e.repsTo);
    _restController = TextEditingController(text: e.restTime);
    _technique = e.technique;
    // Pre-tick if this exercise is already linked to the previous one.
    final exercises = widget.program.days[widget.dayIndex].exercises;
    if (widget.exerciseIndex > 0 && e.supersetGroupId != null) {
      final prev = exercises[widget.exerciseIndex - 1];
      _linkWithPrevious = prev.supersetGroupId == e.supersetGroupId;
    } else {
      _linkWithPrevious = false;
    }
  }

  @override
  void dispose() {
    _setsController.dispose();
    _repsFromController.dispose();
    _repsToController.dispose();
    _restController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).viewPadding.bottom + 20),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: borderLight, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text(widget.exercise.name, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text('Edit exercise settings', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _setsController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(labelText: 'Sets'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _repsFromController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(labelText: 'Reps From'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _repsToController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(labelText: 'Reps To'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _restController,
              decoration: const InputDecoration(
                labelText: 'Rest Time',
                hintText: 'e.g. 2-3 min',
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _technique,
              decoration: const InputDecoration(labelText: 'Technique'),
              items: _techniques.map((t) => DropdownMenuItem(value: t.$2, child: Text(t.$1))).toList(),
              onChanged: (v) => setState(() => _technique = v ?? 'standard'),
            ),
            if (_technique != 'standard' && _techniqueDescriptions.containsKey(_technique)) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: steelBlue.withAlpha(15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: steelBlue.withAlpha(50)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: steelBlue, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _techniqueDescriptions[_technique] ?? '',
                        style: const TextStyle(fontSize: 13, color: steelBlue),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 8),
            // Superset linking
            _buildSupersetSection(),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      context.push('/exercises/replace', extra: {
                        'program': widget.program,
                        'dayIndex': widget.dayIndex,
                        'exerciseIndex': widget.exerciseIndex,
                        'exercise': widget.exercise,
                      });
                    },
                    icon: const Icon(Icons.sync_rounded, size: 18),
                    label: const Text('Replace'),
                    style: OutlinedButton.styleFrom(foregroundColor: steelBlue, side: const BorderSide(color: steelBlue)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmRemove(context),
                    icon: const Icon(Icons.delete_rounded, size: 18),
                    label: const Text('Remove'),
                    style: OutlinedButton.styleFrom(foregroundColor: primaryRed, side: const BorderSide(color: primaryRed)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _saveChanges, child: const Text('Save Changes')),
          ],
        ),
      ),
    );
  }

  Widget _buildSupersetSection() {
    final exercises = widget.program.days[widget.dayIndex].exercises;
    final canLink = widget.exerciseIndex > 0;
    final prev = canLink ? exercises[widget.exerciseIndex - 1] : null;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: steelBlue.withAlpha(12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: steelBlue.withAlpha(40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.link_rounded, size: 16, color: steelBlue),
              const SizedBox(width: 6),
              Text('Superset',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: steelBlue, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 6),
          if (!canLink)
            const Text(
              'First exercise of the day. Move another exercise above it to link.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            )
          else ...[
            CheckboxListTile(
              value: _linkWithPrevious,
              onChanged: (v) =>
                  setState(() => _linkWithPrevious = v ?? false),
              activeColor: steelBlue,
              dense: true,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(
                'Link with previous: ${prev!.name}',
                style: const TextStyle(fontSize: 13),
              ),
              subtitle: const Text(
                'Perform back-to-back with no rest between.',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _saveChanges() {
    final updated = widget.exercise.copyWith(
      sets: int.tryParse(_setsController.text) ?? widget.exercise.sets,
      repsFrom: _repsFromController.text,
      repsTo: _repsToController.text,
      restTime: _restController.text,
      technique: _technique,
    );
    _applyChanges(updated);
    Navigator.pop(context);
    HapticFeedback.selectionClick();
  }

  // Applies field changes + superset link state.
  void _applyChanges(ExerciseModel updated) {
    final days = List.of(widget.program.days);
    final exercises = List.of(days[widget.dayIndex].exercises);
    final idx = widget.exerciseIndex;

    if (idx > 0 && _linkWithPrevious) {
      // Link with previous.
      final prev = exercises[idx - 1];
      String groupId = prev.supersetGroupId ?? const Uuid().v4();
      // Ensure prev is part of the group.
      if (prev.supersetGroupId == null) {
        exercises[idx - 1] = prev.copyWith(
          supersetGroupId: groupId,
          supersetOrder: 0,
        );
      }
      // Find max order among current members of groupId, assign next.
      int maxOrder = 0;
      for (final ex in exercises) {
        if (ex.supersetGroupId == groupId && ex.supersetOrder > maxOrder) {
          maxOrder = ex.supersetOrder;
        }
      }
      exercises[idx] = updated.copyWith(
        supersetGroupId: groupId,
        supersetOrder: maxOrder + 1,
      );
    } else {
      // Unlink: this exercise becomes standalone.
      exercises[idx] = updated.copyWith(
        supersetGroupId: null,
        supersetOrder: 0,
      );
    }

    days[widget.dayIndex] =
        days[widget.dayIndex].copyWith(exercises: exercises);
    final updatedProgram = widget.program.copyWith(days: days);
    ref.read(programsProvider.notifier).updateProgram(updatedProgram);
  }

  Future<void> _confirmRemove(BuildContext context) async {
    final navigator = Navigator.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Remove Exercise?'),
        content: Text('Remove "${widget.exercise.name}" from this day?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(d, true),
            child: const Text('Remove', style: TextStyle(color: primaryRed)),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      _removeExercise();
      navigator.pop();
    }
  }

  void _removeExercise() {
    final days = List.of(widget.program.days);
    final exercises = List.of(days[widget.dayIndex].exercises);
    exercises.removeAt(widget.exerciseIndex);
    final updatedDay = days[widget.dayIndex].copyWith(exercises: exercises);
    days[widget.dayIndex] = updatedDay;
    final updatedProgram = widget.program.copyWith(days: days);
    ref.read(programsProvider.notifier).updateProgram(updatedProgram);
  }
}
