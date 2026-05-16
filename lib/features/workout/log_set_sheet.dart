import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/session_repository.dart';
import 'workout_provider.dart';

class LogSetSheet extends ConsumerStatefulWidget {
  const LogSetSheet({super.key});

  @override
  ConsumerState<LogSetSheet> createState() => _LogSetSheetState();
}

class _LogSetSheetState extends ConsumerState<LogSetSheet> {
  final _weightController = TextEditingController();
  final _repsController = TextEditingController();
  final _notesController = TextEditingController();

  List<({DateTime date, List<dynamic> sets})> _history = [];
  bool _showHistory = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadHistory());
  }

  void _loadHistory() {
    final state = ref.read(workoutProvider);
    final exercise = state.currentDay?.exercises[state.currentExerciseIndex];
    if (exercise == null) return;

    final history =
        SessionRepository().getExerciseHistory(exercise.name, limit: 5);
    setState(() => _history = history);

    // Pre-fill weight from last session, same set number
    if (history.isNotEmpty) {
      final lastSets = history.first.sets;
      final currentSetIndex =
          state.session?.exercises[state.currentExerciseIndex].sets.length ?? 0;
      if (lastSets.isNotEmpty) {
        final refSet = currentSetIndex < lastSets.length
            ? lastSets[currentSetIndex]
            : lastSets.last;
        _weightController.text = refSet.weight.toStringAsFixed(
            refSet.weight == refSet.weight.floorToDouble() ? 0 : 1);
        _repsController.text = refSet.reps.toString();
      }
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(workoutProvider);
    final exercise = state.currentDay?.exercises[state.currentExerciseIndex];
    final currentSetNumber =
        (state.session?.exercises[state.currentExerciseIndex].sets.length ??
                0) +
            1;

    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: borderLight, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),

          // Title row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Log Set $currentSetNumber',
                        style: Theme.of(context).textTheme.headlineMedium),
                    if (exercise != null)
                      Text(exercise.name,
                          style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              // History toggle
              if (_history.isNotEmpty)
                TextButton.icon(
                  onPressed: () =>
                      setState(() => _showHistory = !_showHistory),
                  icon: Icon(
                    Icons.history_rounded,
                    size: 16,
                    color: AppColors.activeDark,
                  ),
                  label: Text(
                    _showHistory ? 'Hide' : 'History',
                    style: TextStyle(
                        color: AppColors.activeDark, fontSize: 13),
                  ),
                ),
            ],
          ),

          // History panel
          if (_showHistory && _history.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.activeDark.withAlpha(10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.activeDark.withAlpha(40)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Previous Sessions',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.activeDark,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  ..._history.map((entry) {
                    final dateLabel =
                        DateFormat('d MMM').format(entry.date);
                    final setsLabel = entry.sets
                        .map((s) =>
                            '${s.weight.toStringAsFixed(s.weight == s.weight.floorToDouble() ? 0 : 1)}kg×${s.reps}')
                        .join('  ');
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 52,
                            child: Text(dateLabel,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                        color: AppColors.textSecondary)),
                          ),
                          Expanded(
                            child: Text(setsLabel,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(fontSize: 13)),
                          ),
                          // Tap to use this weight
                          GestureDetector(
                            onTap: () {
                              final sets = entry.sets;
                              if (sets.isNotEmpty) {
                                final refSet =
                                    currentSetNumber - 1 < sets.length
                                        ? sets[currentSetNumber - 1]
                                        : sets.last;
                                _weightController.text =
                                    refSet.weight.toStringAsFixed(
                                        refSet.weight ==
                                                refSet.weight.floorToDouble()
                                            ? 0
                                            : 1);
                                _repsController.text =
                                    refSet.reps.toString();
                                setState(() => _showHistory = false);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.activeDark.withAlpha(20),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text('Use',
                                  style: TextStyle(
                                      color: AppColors.activeDark,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Weight + Reps inputs
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _weightController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                  ],
                  decoration: const InputDecoration(
                      labelText: 'Weight (kg)', suffixText: 'kg'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _repsController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(labelText: 'Reps'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Notes (optional)',
              hintText: 'e.g. Felt strong today',
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _confirm,
            child: const Text('Confirm & Start Rest Timer'),
          ),
        ],
      ),
    );
  }

  void _confirm() {
    final weight = double.tryParse(_weightController.text) ?? 0;
    final reps = int.tryParse(_repsController.text) ?? 0;
    if (weight <= 0 || reps <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid weight and reps')),
      );
      return;
    }
    ref.read(workoutProvider.notifier).logSet(
          weight: weight,
          reps: reps,
          notes: _notesController.text.isNotEmpty
              ? _notesController.text
              : null,
        );
    Navigator.of(context).pop();
  }
}
