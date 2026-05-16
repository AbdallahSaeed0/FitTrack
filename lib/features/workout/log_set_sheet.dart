import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
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

    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Log Set',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          if (exercise != null) ...[
            const SizedBox(height: 4),
            Text(
              exercise.name,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _weightController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                  decoration: const InputDecoration(
                    labelText: 'Weight (kg)',
                    suffixText: 'kg',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _repsController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Reps',
                  ),
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
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
    );
    Navigator.of(context).pop();
  }
}
