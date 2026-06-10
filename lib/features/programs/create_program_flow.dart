import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/exercise_model.dart';
import '../../data/models/program_model.dart';
import '../../data/models/workout_day_model.dart';
import 'programs_provider.dart';

class CreateProgramFlow extends ConsumerStatefulWidget {
  const CreateProgramFlow({super.key});

  @override
  ConsumerState<CreateProgramFlow> createState() => _CreateProgramFlowState();
}

class _CreateProgramFlowState extends ConsumerState<CreateProgramFlow> {
  int _step = 0;
  String? _selectedSplit;
  String _goal = 'Muscle Building';
  String _level = 'Intermediate';
  int _daysPerWeek = 4;
  final List<String> _techniques = [];
  bool _isGenerating = false;

  // Custom split state
  final List<_CustomDay> _customDays = [];

  final _nameController = TextEditingController();

  static const _goals = ['Muscle Building', 'Strength', 'Body Recomposition', 'Fat Loss'];
  static const _levels = ['Beginner', 'Intermediate', 'Advanced'];
  static const _allTechniques = [
    'Drop Sets', 'Supersets', 'Rest-Pause Sets', 'Pyramid Sets', 'Tempo Training'
  ];
  static const _techniqueKeys = [
    'drop_sets', 'supersets', 'rest_pause', 'pyramid_sets', 'tempo_training'
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Create Program'),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _buildStep(),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _StepChooseSplit(
            onSelect: _onSplitSelected, onImport: _importFromFile);
      case 1:
        if (_selectedSplit == 'custom') {
          return _CustomSplitBuilder(
            nameController: _nameController,
            daysPerWeek: _daysPerWeek,
            customDays: _customDays,
            onDaysChanged: (d) => setState(() => _daysPerWeek = d),
            onGenerate: _generateCustomProgram,
            isGenerating: _isGenerating,
          );
        }
        return _CoachBuilder(
          split: _selectedSplit!,
          nameController: _nameController,
          goal: _goal,
          level: _level,
          daysPerWeek: _daysPerWeek,
          techniques: _techniques,
          goals: _goals,
          levels: _levels,
          allTechniques: _allTechniques,
          onGoalChanged: (v) => setState(() => _goal = v),
          onLevelChanged: (v) => setState(() => _level = v),
          onDaysChanged: (v) => setState(() => _daysPerWeek = v),
          onTechniqueToggled: _toggleTechnique,
          onGenerate: _generateTemplateProgram,
          isGenerating: _isGenerating,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Future<void> _importFromFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final bytes = result.files.first.bytes;
      if (bytes == null) return;

      final json = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      final program = ProgramModel.fromJson(json);

      // Give it a fresh ID to avoid collision
      final imported = ProgramModel(
        id: const Uuid().v4(),
        name: program.name,
        splitType: program.splitType,
        goal: program.goal,
        days: program.days,
      );

      await ref.read(programsProvider.notifier).addProgram(imported);
      if (mounted) {
        context.pop();
        context.push('/programs/${imported.id}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not import file: $e')),
        );
      }
    }
  }

  void _onSplitSelected(String split) {
    setState(() {
      _selectedSplit = split;
      _step = 1;
      if (split != 'custom') {
        switch (split) {
          case 'upper_lower':
            _nameController.text = 'Upper/Lower Program';
            _daysPerWeek = 4;
          case 'push_pull_legs':
            _nameController.text = 'Push Pull Legs';
            _daysPerWeek = 3;
          case 'full_body':
            _nameController.text = 'Full Body Program';
            _daysPerWeek = 3;
        }
      }
    });
  }

  void _toggleTechnique(String technique) {
    setState(() {
      final key = _techniqueKeys[_allTechniques.indexOf(technique)];
      if (_techniques.contains(key)) {
        _techniques.remove(key);
      } else {
        _techniques.add(key);
      }
    });
  }

  Future<void> _generateCustomProgram(List<_CustomDay> days) async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a program name')),
      );
      return;
    }
    setState(() => _isGenerating = true);
    HapticFeedback.mediumImpact();

    try {
      final builtDays = <WorkoutDayModel>[];
      const uuid = Uuid();

      for (int i = 0; i < days.length; i++) {
        final d = days[i];
        final exercises = <ExerciseModel>[];
        for (final mg in d.muscleGroups) {
          final fetched = await ref
              .read(exerciseRepositoryProvider)
              .getSimilarExercises(mg.bodyPart, limit: mg.count + 5);
          final filtered = fetched.where((e) {
            final n = e.name.toLowerCase();
            return !n.contains('dip') && !n.contains('deadlift') && !n.contains('barbell row');
          }).take(mg.count).toList();
          exercises.addAll(filtered.map((e) => e.copyWith(sets: 3, repsFrom: '8', repsTo: '12')));
        }
        builtDays.add(WorkoutDayModel(
          id: uuid.v4(),
          name: d.name.isNotEmpty ? d.name : 'Day ${i + 1}',
          dayNumber: i + 1,
          exercises: exercises,
        ));
      }

      final program = ProgramModel(
        id: uuid.v4(),
        name: _nameController.text.trim(),
        splitType: 'custom',
        goal: 'Muscle Building',
        days: builtDays,
      );
      await ref.read(programsProvider.notifier).addProgram(program);
      if (mounted) {
        context.pop();
        context.push('/programs/${program.id}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating program: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _generateTemplateProgram() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a program name')),
      );
      return;
    }
    setState(() => _isGenerating = true);
    HapticFeedback.mediumImpact();

    try {
      final generator = ref.read(programGeneratorProvider);
      final program = await generator.generateFromTemplate(
        name: _nameController.text.trim(),
        splitType: _selectedSplit!,
        goal: _goal,
        experienceLevel: _level,
        daysPerWeek: _daysPerWeek,
        techniques: _techniques,
      );
      await ref.read(programsProvider.notifier).addProgram(program);
      if (mounted) {
        context.pop();
        context.push('/programs/${program.id}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }
}

class _StepChooseSplit extends StatelessWidget {
  final void Function(String) onSelect;
  final VoidCallback onImport;
  const _StepChooseSplit({required this.onSelect, required this.onImport});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Choose Your Split', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text('Select a training structure for your program', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 24),
        _SplitCard(
          icon: Icons.swap_vert_rounded,
          iconColor: steelBlue,
          title: 'Upper/Lower',
          subtitle: '4 days/week · Balanced',
          onTap: () => onSelect('upper_lower'),
        ),
        const SizedBox(height: 12),
        _SplitCard(
          icon: Icons.sync_rounded,
          iconColor: tealSuccess,
          title: 'Push Pull Legs',
          subtitle: '3 days/week · Focused',
          onTap: () => onSelect('push_pull_legs'),
        ),
        const SizedBox(height: 12),
        _SplitCard(
          icon: Icons.fitness_center_rounded,
          iconColor: primaryRed,
          title: 'Full Body',
          subtitle: '3 days/week · Compound',
          onTap: () => onSelect('full_body'),
        ),
        const SizedBox(height: 12),
        _SplitCard(
          icon: Icons.tune_rounded,
          iconColor: const Color(0xFF8899AA),
          title: 'Custom Split',
          subtitle: 'Build your own · Full control',
          onTap: () => onSelect('custom'),
        ),
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 12),
        Text('Or import an existing program',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: const Color(0xFF8899AA))),
        const SizedBox(height: 10),
        _SplitCard(
          icon: Icons.upload_file_rounded,
          iconColor: tealSuccess,
          title: 'Import from JSON',
          subtitle: 'Load a previously exported program file',
          onTap: onImport,
        ),
      ],
    );
  }
}

class _SplitCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SplitCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color ?? Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderLight),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Color(0xFF8899AA)),
          ],
        ),
      ),
    );
  }
}

class _MuscleGroup {
  String bodyPart;
  int count;
  _MuscleGroup({required this.bodyPart, this.count = 3});
}

class _CustomDay {
  String name;
  List<_MuscleGroup> muscleGroups;
  _CustomDay({this.name = '', List<_MuscleGroup>? muscleGroups})
      : muscleGroups = muscleGroups ?? [];
}

class _CustomSplitBuilder extends ConsumerStatefulWidget {
  final TextEditingController nameController;
  final int daysPerWeek;
  final List<_CustomDay> customDays;
  final void Function(int) onDaysChanged;
  final void Function(List<_CustomDay>) onGenerate;
  final bool isGenerating;

  const _CustomSplitBuilder({
    required this.nameController,
    required this.daysPerWeek,
    required this.customDays,
    required this.onDaysChanged,
    required this.onGenerate,
    required this.isGenerating,
  });

  @override
  ConsumerState<_CustomSplitBuilder> createState() => _CustomSplitBuilderState();
}

class _CustomSplitBuilderState extends ConsumerState<_CustomSplitBuilder> {
  late List<_CustomDay> _days;
  late int _daysCount;

  static const _muscles = [
    ('Chest', 'chest'), ('Back', 'back'), ('Shoulders', 'shoulders'),
    ('Biceps', 'upper arms'), ('Triceps', 'upper arms'), ('Quads', 'upper legs'),
    ('Hamstrings', 'upper legs'), ('Glutes', 'upper legs'), ('Calves', 'lower legs'),
    ('Abs', 'waist'), ('Core', 'waist'), ('Cardio', 'cardio'),
  ];

  @override
  void initState() {
    super.initState();
    _daysCount = widget.daysPerWeek;
    _days = List.generate(_daysCount, (i) => _CustomDay(name: 'Day ${i + 1}'));
    if (widget.customDays.isNotEmpty) {
      _days = widget.customDays;
    }
  }

  void _updateDaysCount(int count) {
    setState(() {
      _daysCount = count;
      while (_days.length < count) { _days.add(_CustomDay(name: 'Day ${_days.length + 1}')); }
      while (_days.length > count) { _days.removeLast(); }
    });
    widget.onDaysChanged(count);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
          children: [
            Text('Custom Split', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 20),
            TextField(
              controller: widget.nameController,
              decoration: const InputDecoration(labelText: 'Program Name'),
            ),
            const SizedBox(height: 20),
            Text('Days per week: $_daysCount', style: Theme.of(context).textTheme.titleMedium),
            Slider(
              value: _daysCount.toDouble(),
              min: 2,
              max: 7,
              divisions: 5,
              activeColor: primaryRed,
              label: '$_daysCount days',
              onChanged: (v) => _updateDaysCount(v.round()),
            ),
            const SizedBox(height: 16),
            ...List.generate(_daysCount, (i) => _DayCard(
              day: _days[i],
              index: i,
              muscles: _muscles,
              onChanged: () => setState(() {}),
            )),
          ],
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(20),
            color: Theme.of(context).scaffoldBackgroundColor,
            child: ElevatedButton(
              onPressed: widget.isGenerating ? null : () => widget.onGenerate(_days),
              child: widget.isGenerating
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Generate Program'),
            ),
          ),
        ),
      ],
    );
  }
}

class _DayCard extends StatelessWidget {
  final _CustomDay day;
  final int index;
  final List<(String, String)> muscles;
  final VoidCallback onChanged;

  const _DayCard({
    required this.day,
    required this.index,
    required this.muscles,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(color: primaryRed, shape: BoxShape.circle),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    onChanged: (v) {
                      day.name = v;
                      onChanged();
                    },
                    decoration: InputDecoration(
                      labelText: 'Day Name',
                      hintText: 'e.g. Chest & Triceps',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    controller: TextEditingController(text: day.name)
                      ..selection = TextSelection.collapsed(offset: day.name.length),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (day.muscleGroups.isEmpty)
              const Text('No muscle groups selected', style: TextStyle(color: Color(0xFF8899AA))),
            ...day.muscleGroups.map((mg) => _MuscleGroupRow(
              mg: mg,
              onRemove: () {
                day.muscleGroups.remove(mg);
                onChanged();
              },
              onCountChanged: (c) {
                mg.count = c;
                onChanged();
              },
            )),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _addMuscleGroup(context),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Add Muscle Group'),
              style: OutlinedButton.styleFrom(
                foregroundColor: steelBlue,
                side: const BorderSide(color: steelBlue),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addMuscleGroup(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _MusclePickerSheet(
        muscles: muscles,
        selected: day.muscleGroups.map((m) => m.bodyPart).toSet(),
        onSelect: (name, bodyPart) {
          day.muscleGroups.add(_MuscleGroup(bodyPart: bodyPart, count: 3));
          onChanged();
          Navigator.pop(ctx);
        },
      ),
    );
  }
}

class _MusclePickerSheet extends StatelessWidget {
  final List<(String, String)> muscles;
  final Set<String> selected;
  final void Function(String name, String bodyPart) onSelect;

  const _MusclePickerSheet({
    required this.muscles,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select Muscle Group', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: muscles.map(((String, String) m) {
                final isSelected = selected.contains(m.$2);
                return GestureDetector(
                  onTap: isSelected ? null : () => onSelect(m.$1, m.$2),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? borderLight : steelBlue.withAlpha(20),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isSelected ? borderLight : steelBlue),
                    ),
                    child: Text(
                      m.$1,
                      style: TextStyle(
                        color: isSelected ? Colors.grey : steelBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _MuscleGroupRow extends StatelessWidget {
  final _MuscleGroup mg;
  final VoidCallback onRemove;
  final void Function(int) onCountChanged;

  const _MuscleGroupRow({required this.mg, required this.onRemove, required this.onCountChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(mg.bodyPart.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: steelBlue)),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: mg.count > 1 ? () => onCountChanged(mg.count - 1) : null,
                icon: const Icon(Icons.remove_circle_outline_rounded, size: 20),
                color: primaryRed,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              ),
              Text('${mg.count}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              IconButton(
                onPressed: mg.count < 6 ? () => onCountChanged(mg.count + 1) : null,
                icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                color: primaryRed,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              ),
            ],
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.close_rounded, size: 18, color: Colors.grey),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
        ],
      ),
    );
  }
}

class _CoachBuilder extends StatelessWidget {
  final String split;
  final TextEditingController nameController;
  final String goal;
  final String level;
  final int daysPerWeek;
  final List<String> techniques;
  final List<String> goals;
  final List<String> levels;
  final List<String> allTechniques;
  final void Function(String) onGoalChanged;
  final void Function(String) onLevelChanged;
  final void Function(int) onDaysChanged;
  final void Function(String) onTechniqueToggled;
  final VoidCallback onGenerate;
  final bool isGenerating;

  const _CoachBuilder({
    required this.split,
    required this.nameController,
    required this.goal,
    required this.level,
    required this.daysPerWeek,
    required this.techniques,
    required this.goals,
    required this.levels,
    required this.allTechniques,
    required this.onGoalChanged,
    required this.onLevelChanged,
    required this.onDaysChanged,
    required this.onTechniqueToggled,
    required this.onGenerate,
    required this.isGenerating,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
          children: [
            Text('Program Setup', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 20),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Program Name'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: goal,
              decoration: const InputDecoration(labelText: 'Goal'),
              items: goals.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
              onChanged: (v) => v != null ? onGoalChanged(v) : null,
            ),
            const SizedBox(height: 16),
            Text('Experience Level', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: levels.map((l) {
                final selected = level == l;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onLevelChanged(l),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: selected ? steelBlue : Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: selected ? steelBlue : Theme.of(context).dividerColor.withAlpha(60)),
                      ),
                      child: Center(
                        child: Text(
                          l,
                          style: TextStyle(
                            color: selected ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Text('Days per week', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [3, 4, 5, 6].map((d) {
                final selected = daysPerWeek == d;
                return GestureDetector(
                  onTap: () => onDaysChanged(d),
                  child: Container(
                    width: 52,
                    height: 44,
                    decoration: BoxDecoration(
                      color: selected ? primaryRed : Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: selected ? primaryRed : Theme.of(context).dividerColor.withAlpha(60)),
                    ),
                    child: Center(
                      child: Text(
                        '$d',
                        style: TextStyle(
                          color: selected ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Text('Advanced Techniques', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...allTechniques.map((t) {
              final key = t.toLowerCase().replaceAll(' ', '_').replaceAll('-', '_');
              final selected = techniques.any((tk) => tk.contains(key.split('_').first));
              return CheckboxListTile(
                title: Text(t),
                value: selected,
                activeColor: steelBlue,
                contentPadding: EdgeInsets.zero,
                onChanged: (_) => onTechniqueToggled(t),
              );
            }),
          ],
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(20),
            color: Theme.of(context).scaffoldBackgroundColor,
            child: ElevatedButton(
              onPressed: isGenerating ? null : onGenerate,
              child: isGenerating
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Generate Program'),
            ),
          ),
        ),
      ],
    );
  }
}
