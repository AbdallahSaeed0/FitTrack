import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart' show AppColors;
import '../../core/theme/app_theme.dart';
import '../../data/repositories/session_repository.dart';
import 'workout_provider.dart';

class LogSetSheet extends ConsumerStatefulWidget {
  const LogSetSheet({super.key});

  @override
  ConsumerState<LogSetSheet> createState() => _LogSetSheetState();
}

class _LogSetSheetState extends ConsumerState<LogSetSheet> {
  final _weightController = TextEditingController();       // left / single
  final _weightRightController = TextEditingController();  // right (unilateral only)
  final _repsController = TextEditingController(text: '10');
  final _notesController = TextEditingController();
  final _durationController = TextEditingController();     // cardio: minutes
  final _distanceController = TextEditingController();     // cardio: km (optional)

  int _reps = 10;
  bool _toFailure = false;
  bool _isBodyweight = false;
  bool _isUnilateral = false;
  bool _isDropset = false;
  // Extra weights AFTER the initial weight (in _weightController). One per drop.
  final List<TextEditingController> _dropControllers = [];

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
        SessionRepository.instance.getExerciseHistory(exercise.name, limit: 5);
    setState(() => _history = history);

    if (exercise.isCardio) {
      _loadCardioHistory(state, history);
      return;
    }

    // Auto-detect bodyweight
    final isBodyweightExercise = exercise.equipments.any(
      (e) => e.toLowerCase().contains('body'),
    );
    // Default dropset ON when the exercise is configured as drop_sets.
    final isDropsetExercise = exercise.technique == 'drop_sets';
    setState(() {
      _isBodyweight = isBodyweightExercise;
      _isDropset = isDropsetExercise;
      if (isDropsetExercise && _dropControllers.isEmpty) {
        _dropControllers.add(TextEditingController());
      }
    });

    // Pre-fill: current session's last set takes highest priority,
    // then last session's matching set, then exercise target reps.
    final currentSessionSets =
        state.session?.exercises[state.currentExerciseIndex].sets ?? [];

    if (currentSessionSets.isNotEmpty) {
      // Use the most recently logged set in this session for this exercise.
      final lastSet = currentSessionSets.last;
      if (!isBodyweightExercise && !lastSet.isBodyweight) {
        _weightController.text = lastSet.weight.toStringAsFixed(
            lastSet.weight == lastSet.weight.floorToDouble() ? 0 : 1);
      }
      setState(() {
        _reps = lastSet.reps;
        _repsController.text = '${lastSet.reps}';
      });
    } else if (history.isNotEmpty) {
      final lastSets = history.first.sets;
      final currentSetIndex = currentSessionSets.length;
      if (lastSets.isNotEmpty) {
        final refSet = currentSetIndex < lastSets.length
            ? lastSets[currentSetIndex]
            : lastSets.last;
        if (!isBodyweightExercise) {
          _weightController.text = refSet.weight.toStringAsFixed(
              refSet.weight == refSet.weight.floorToDouble() ? 0 : 1);
        }
        setState(() {
          _reps = refSet.reps;
          _repsController.text = '${refSet.reps}';
        });
      }
    } else {
      // Pre-fill from exercise target reps
      final targetReps = int.tryParse(exercise.repsFrom) ?? 10;
      setState(() {
        _reps = targetReps;
        _repsController.text = '$targetReps';
      });
    }
  }

  void _loadCardioHistory(
      WorkoutState state, List<({DateTime date, List<dynamic> sets})> history) {
    final currentSessionSets =
        state.session?.exercises[state.currentExerciseIndex].sets ?? [];

    dynamic refSet;
    if (currentSessionSets.isNotEmpty) {
      refSet = currentSessionSets.last;
    } else if (history.isNotEmpty && history.first.sets.isNotEmpty) {
      refSet = history.first.sets.first;
    }

    if (refSet != null && refSet.durationSeconds != null) {
      final mins = (refSet.durationSeconds as int) / 60;
      _durationController.text = mins == mins.floorToDouble()
          ? mins.toInt().toString()
          : mins.toStringAsFixed(1);
      if (refSet.distanceKm != null) {
        final dist = refSet.distanceKm as double;
        _distanceController.text =
            dist == dist.floorToDouble() ? dist.toInt().toString() : dist.toString();
      }
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _weightRightController.dispose();
    _repsController.dispose();
    _notesController.dispose();
    _durationController.dispose();
    _distanceController.dispose();
    for (final c in _dropControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addDrop() {
    setState(() => _dropControllers.add(TextEditingController()));
  }

  void _removeDrop(int i) {
    setState(() {
      _dropControllers[i].dispose();
      _dropControllers.removeAt(i);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(workoutProvider);
    final exercise = state.currentDay?.exercises[state.currentExerciseIndex];
    final currentSetNumber =
        (state.session?.exercises[state.currentExerciseIndex].sets.length ??
                0) +
            1;
    final isCardio = exercise?.isCardio ?? false;

    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).viewPadding.bottom + 20),
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
              if (_history.isNotEmpty)
                TextButton.icon(
                  onPressed: () =>
                      setState(() => _showHistory = !_showHistory),
                  icon: Icon(Icons.history_rounded, size: 16,
                      color: AppColors.activeDark),
                  label: Text(
                    _showHistory ? 'Hide' : 'History',
                    style: TextStyle(color: AppColors.activeDark, fontSize: 13),
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
                    final dateLabel = DateFormat('d MMM').format(entry.date);
                    final setsLabel = entry.sets
                        .map((s) => s.formatSummary())
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
                                    ?.copyWith(color: AppColors.textSecondary)),
                          ),
                          Expanded(
                            child: Text(setsLabel,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(fontSize: 13)),
                          ),
                          GestureDetector(
                            onTap: () {
                              final sets = entry.sets;
                              if (sets.isNotEmpty) {
                                final refSet = currentSetNumber - 1 < sets.length
                                    ? sets[currentSetNumber - 1]
                                    : sets.last;
                                if (isCardio) {
                                  if (refSet.durationSeconds != null) {
                                    final mins = refSet.durationSeconds! / 60;
                                    _durationController.text =
                                        mins == mins.floorToDouble()
                                            ? mins.toInt().toString()
                                            : mins.toStringAsFixed(1);
                                  }
                                  if (refSet.distanceKm != null) {
                                    final dist = refSet.distanceKm!;
                                    _distanceController.text =
                                        dist == dist.floorToDouble()
                                            ? dist.toInt().toString()
                                            : dist.toString();
                                  }
                                  setState(() => _showHistory = false);
                                  return;
                                }
                                if (!_isBodyweight) {
                                  _weightController.text =
                                      refSet.weight.toStringAsFixed(
                                          refSet.weight ==
                                                  refSet.weight.floorToDouble()
                                              ? 0
                                              : 1);
                                }
                                setState(() {
                                  _reps = refSet.reps;
                                  _showHistory = false;
                                });
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

          if (isCardio) ...[
            _buildCardioInputs(context),
          ] else ...[
          // Reps + Weight inputs
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Reps', style: Theme.of(context).textTheme.labelMedium),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _repsController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      onChanged: (v) =>
                          setState(() => _reps = int.tryParse(v) ?? _reps),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Weight input(s) — single when not unilateral, L/R when unilateral
              if (!_isBodyweight) ...[
                if (!_isUnilateral)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Weight',
                            style: Theme.of(context).textTheme.labelMedium),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _weightController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                          ],
                          decoration: const InputDecoration(
                              suffixText: 'kg',
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12)),
                        ),
                      ],
                    ),
                  )
                else ...[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Left',
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(color: steelBlue)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _weightController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                          ],
                          decoration: InputDecoration(
                              suffixText: 'kg',
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                    color: steelBlue.withAlpha(120)),
                              )),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Right',
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(color: AppColors.activeDark)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _weightRightController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                          ],
                          decoration: InputDecoration(
                              suffixText: 'kg',
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                    color: AppColors.activeDark.withAlpha(120)),
                              )),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ],
          ),

          const SizedBox(height: 12),

          // Bodyweight toggle + To Failure row
          Row(
            children: [
              // Bodyweight toggle
              GestureDetector(
                onTap: () => setState(() => _isBodyweight = !_isBodyweight),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _isBodyweight
                        ? steelBlue.withAlpha(25)
                        : Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: _isBodyweight
                            ? steelBlue
                            : Theme.of(context).dividerColor.withAlpha(80)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.accessibility_new_rounded,
                          size: 14,
                          color: _isBodyweight ? steelBlue : Colors.grey),
                      const SizedBox(width: 4),
                      Text('Bodyweight',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _isBodyweight ? steelBlue : Colors.grey)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // To Failure
              GestureDetector(
                onTap: () => setState(() => _toFailure = !_toFailure),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _toFailure
                        ? primaryRed.withAlpha(20)
                        : Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: _toFailure
                            ? primaryRed
                            : Theme.of(context).dividerColor.withAlpha(80)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.local_fire_department_rounded,
                          size: 14,
                          color: _toFailure ? primaryRed : Colors.grey),
                      const SizedBox(width: 4),
                      Text('To Failure',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _toFailure ? primaryRed : Colors.grey)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Unilateral (each arm/leg)
              GestureDetector(
                onTap: () => setState(() => _isUnilateral = !_isUnilateral),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _isUnilateral
                        ? AppColors.activeDark.withAlpha(25)
                        : Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: _isUnilateral
                            ? AppColors.activeDark
                            : Theme.of(context).dividerColor.withAlpha(80)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.swap_horiz_rounded,
                          size: 14,
                          color: _isUnilateral
                              ? AppColors.activeDark
                              : Colors.grey),
                      const SizedBox(width: 4),
                      Text('Each Side',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _isUnilateral
                                  ? AppColors.activeDark
                                  : Colors.grey)),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Dropset chip
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              setState(() {
                _isDropset = !_isDropset;
                if (_isDropset && _dropControllers.isEmpty) {
                  _dropControllers.add(TextEditingController());
                }
              });
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _isDropset
                    ? primaryRed.withAlpha(20)
                    : Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: _isDropset
                        ? primaryRed
                        : Theme.of(context).dividerColor.withAlpha(80)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.south_rounded,
                      size: 14,
                      color: _isDropset ? primaryRed : Colors.grey),
                  const SizedBox(width: 4),
                  Text('Dropset',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _isDropset ? primaryRed : Colors.grey)),
                ],
              ),
            ),
          ),

          // Drop rows
          if (_isDropset && !_isBodyweight) ...[
            const SizedBox(height: 10),
            ..._dropControllers.asMap().entries.map((e) {
              final i = e.key;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 64,
                      child: Text('Drop ${i + 1}',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: primaryRed.withAlpha(220))),
                    ),
                    Expanded(
                      child: TextFormField(
                        controller: e.value,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9.]'))
                        ],
                        decoration: const InputDecoration(
                          suffixText: 'kg',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 10, vertical: 10),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _removeDrop(i),
                      icon: const Icon(Icons.close_rounded,
                          size: 18, color: Colors.grey),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                          minWidth: 28, minHeight: 28),
                    ),
                  ],
                ),
              );
            }),
            TextButton.icon(
              onPressed: _addDrop,
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Add drop'),
              style: TextButton.styleFrom(
                foregroundColor: primaryRed,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
          ],

          if (_isUnilateral && !_isBodyweight) ...[
            const SizedBox(height: 6),
            Text(
              'Enter different weights if each side differs.',
              style: TextStyle(fontSize: 11, color: AppColors.activeDark.withAlpha(180)),
            ),
          ],
          ],

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

  Widget _buildCardioInputs(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Duration',
                  style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 6),
              TextFormField(
                controller: _durationController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                ],
                decoration: const InputDecoration(
                    suffixText: 'min',
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Distance (optional)',
                  style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 6),
              TextFormField(
                controller: _distanceController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                ],
                decoration: const InputDecoration(
                    suffixText: 'km',
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 12)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _confirmCardio() {
    final minutes = double.tryParse(_durationController.text) ?? 0;
    if (minutes <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid duration')),
      );
      return;
    }
    final distance = double.tryParse(_distanceController.text);
    ref.read(workoutProvider.notifier).logSet(
          weight: 0,
          reps: 0,
          notes: _notesController.text.isNotEmpty ? _notesController.text : null,
          durationSeconds: (minutes * 60).round(),
          distanceKm: (distance != null && distance > 0) ? distance : null,
        );
    Navigator.of(context).pop();
  }

  void _confirm() {
    final exercise = ref
        .read(workoutProvider)
        .currentDay
        ?.exercises[ref.read(workoutProvider).currentExerciseIndex];
    if (exercise?.isCardio ?? false) {
      _confirmCardio();
      return;
    }
    _reps = int.tryParse(_repsController.text) ?? _reps;
    final weight = _isBodyweight ? 0.0 : (double.tryParse(_weightController.text) ?? 0);
    if (!_isBodyweight && weight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid weight')),
      );
      return;
    }
    if (_reps <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid reps')),
      );
      return;
    }
    List<double>? drops;
    if (_isDropset && !_isBodyweight) {
      drops = _dropControllers
          .map((c) => double.tryParse(c.text) ?? 0)
          .where((w) => w > 0)
          .toList();
      if (drops.isEmpty) drops = null;
    }
    double? rightWeight;
    if (_isUnilateral && !_isBodyweight) {
      final rv = double.tryParse(_weightRightController.text);
      if (rv != null && rv > 0 && rv != weight) rightWeight = rv;
    }
    ref.read(workoutProvider.notifier).logSet(
          weight: weight,
          reps: _reps,
          notes: _notesController.text.isNotEmpty ? _notesController.text : null,
          toFailure: _toFailure,
          isBodyweight: _isBodyweight,
          isUnilateral: _isUnilateral,
          weightRight: rightWeight,
          dropWeights: drops,
        );
    Navigator.of(context).pop();
  }
}

