import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/program_seeder.dart';
import '../../data/models/exercise_model.dart';
import '../../data/models/program_model.dart';
import '../../shared/widgets/exercise_gif_widget.dart';
import '../../shared/widgets/technique_badge.dart';
import '../../data/repositories/exercise_repository.dart';
import 'edit_exercise_sheet.dart';
import 'programs_provider.dart';
import '../exercises/exercises_provider.dart';
import '../exercises/create_custom_exercise_sheet.dart';

// Returns labels like "A1", "A2", "B1"… for exercises in a superset group.
// Single-member groups and standalone exercises get null.
List<String?> _computeSupersetLabels(List<ExerciseModel> exercises) {
  final out = List<String?>.filled(exercises.length, null);
  int letterIdx = 0;
  int i = 0;
  while (i < exercises.length) {
    final groupId = exercises[i].supersetGroupId;
    if (groupId == null) {
      i++;
      continue;
    }
    int j = i;
    while (j < exercises.length && exercises[j].supersetGroupId == groupId) {
      j++;
    }
    final runLen = j - i;
    if (runLen >= 2) {
      final letter = String.fromCharCode('A'.codeUnitAt(0) + letterIdx);
      for (int k = 0; k < runLen; k++) {
        out[i + k] = '$letter${k + 1}';
      }
      letterIdx++;
    }
    i = j;
  }
  return out;
}

class ProgramDetailScreen extends ConsumerStatefulWidget {
  final String programId;

  const ProgramDetailScreen({super.key, required this.programId});

  @override
  ConsumerState<ProgramDetailScreen> createState() =>
      _ProgramDetailScreenState();
}

class _ProgramDetailScreenState extends ConsumerState<ProgramDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _reorderMode = false;

  @override
  void initState() {
    super.initState();
    _initTabController();
    // Silently patch any missing/broken images in the background.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ExerciseRepository.clearCache();
      ref.read(programsProvider.notifier).refreshExerciseImages();
    });
  }

  void _initTabController() {
    final program =
        ref.read(programsProvider.notifier).getById(widget.programId);
    final count = program?.days.length ?? 1;
    _tabController = TabController(length: count, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final programs = ref.watch(programsProvider);
    final program = programs.firstWhere(
      (p) => p.id == widget.programId,
      orElse: () => ProgramModel(id: '', name: 'Not Found', days: []),
    );

    if (program.id.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Program')),
        body: const Center(child: Text('Program not found')),
      );
    }

    final dayIdx = _tabController.index.clamp(0, program.days.length - 1);

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () => _editName(context, program),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  program.name,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.edit_rounded, size: 14, color: Color(0xFF8899AA)),
            ],
          ),
        ),
        actions: [
          // Reorder mode toggle
          if (!_reorderMode)
            IconButton(
              icon: const Icon(Icons.reorder_rounded),
              tooltip: 'Reorder exercises',
              onPressed: () => setState(() => _reorderMode = true),
            )
          else
            TextButton(
              onPressed: () => setState(() => _reorderMode = false),
              child: const Text('Done',
                  style: TextStyle(color: tealSuccess, fontWeight: FontWeight.w700)),
            ),
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Share Program',
            onPressed: () => _shareAsJson(context, program),
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded),
            tooltip: 'Export to PDF',
            onPressed: () => _exportToPdf(context, program),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh exercise data',
            onPressed: () => _refreshExerciseData(context),
          ),
          if (!program.isActive)
            TextButton(
              onPressed: () {
                ref.read(programsProvider.notifier).setActive(program.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Program set as active'),
                      backgroundColor: tealSuccess),
                );
              },
              child: const Text('Set Active',
                  style: TextStyle(color: primaryRed)),
            ),
        ],
        bottom: program.days.isNotEmpty
            ? TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: primaryRed,
                labelColor: primaryRed,
                unselectedLabelColor: const Color(0xFF8899AA),
                tabs: program.days.map((d) => Tab(text: d.name)).toList(),
              )
            : null,
      ),
      body: program.days.isEmpty
          ? const Center(child: Text('No workout days'))
          : Stack(
              children: [
                TabBarView(
                  controller: _tabController,
                  children: List.generate(program.days.length, (tabIdx) {
                    final day = program.days[tabIdx];
                    if (day.exercises.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.fitness_center_rounded,
                                size: 48, color: Color(0xFF8899AA)),
                            const SizedBox(height: 12),
                            const Text('No exercises yet'),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () =>
                                  _addExercise(context, program, tabIdx),
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('Add Exercise'),
                            ),
                          ],
                        ),
                      );
                    }

                    if (_reorderMode) {
                      final ssLabels =
                          _computeSupersetLabels(day.exercises);
                      return ReorderableListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        itemCount: day.exercises.length,
                        onReorder: (oldIndex, newIndex) {
                          if (newIndex > oldIndex) newIndex--;
                          _reorderExercise(
                              program, tabIdx, oldIndex, newIndex);
                        },
                        itemBuilder: (context, exIdx) {
                          final exercise = day.exercises[exIdx];
                          final label = ssLabels[exIdx];
                          final prevSame = exIdx > 0 &&
                              exercise.supersetGroupId != null &&
                              day.exercises[exIdx - 1].supersetGroupId ==
                                  exercise.supersetGroupId;
                          final nextSame = exIdx < day.exercises.length - 1 &&
                              exercise.supersetGroupId != null &&
                              day.exercises[exIdx + 1].supersetGroupId ==
                                  exercise.supersetGroupId;
                          return ReorderableDragStartListener(
                            key: ValueKey(exercise.id + exIdx.toString()),
                            index: exIdx,
                            child: _ExerciseRow(
                              exercise: exercise,
                              program: program,
                              dayIndex: tabIdx,
                              exerciseIndex: exIdx,
                              reorderMode: true,
                              supersetLabel: label,
                              supersetContinuesAbove: prevSame,
                              supersetContinuesBelow: nextSame,
                              onDelete: () => _confirmDelete(
                                  context, program, tabIdx, exIdx),
                            ),
                          );
                        },
                      );
                    }

                    final ssLabels = _computeSupersetLabels(day.exercises);
                    return GridView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
                      physics: const AlwaysScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 0.72,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: day.exercises.length,
                      itemBuilder: (context, exIdx) {
                        final exercise = day.exercises[exIdx];
                        return _ExerciseGridCard(
                          key: ValueKey(exercise.id + exIdx.toString()),
                          exercise: exercise,
                          program: program,
                          dayIndex: tabIdx,
                          exerciseIndex: exIdx,
                          supersetLabel: ssLabels[exIdx],
                          onDelete: () => _confirmDelete(
                              context, program, tabIdx, exIdx),
                        );
                      },
                    );
                  }),
                ),

                // "Add Exercise" floating button at the bottom
                Positioned(
                  bottom: 24,
                  left: 16,
                  right: 16,
                  child: ElevatedButton.icon(
                    onPressed: () => _addExercise(context, program, dayIdx),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add Exercise'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  void _deleteExercise(ProgramModel program, int dayIndex, int exerciseIndex) {
    final days = List.of(program.days);
    final exercises = List.of(days[dayIndex].exercises);
    exercises.removeAt(exerciseIndex);
    days[dayIndex] = days[dayIndex].copyWith(exercises: exercises);
    ref.read(programsProvider.notifier).updateProgram(program.copyWith(days: days));
  }

  Future<void> _confirmDelete(BuildContext context, ProgramModel program,
      int dayIndex, int exerciseIndex) async {
    final name = program.days[dayIndex].exercises[exerciseIndex].name;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Exercise?'),
        content: Text('Remove "$name" from this day?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove',
                style: TextStyle(color: primaryRed, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirm == true) _deleteExercise(program, dayIndex, exerciseIndex);
  }

  Future<void> _editName(BuildContext context, ProgramModel program) async {
    final ctrl = TextEditingController(text: program.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Program'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            hintText: 'Program name',
          ),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Save', style: TextStyle(color: tealSuccess, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (newName != null && newName.isNotEmpty && newName != program.name) {
      ref.read(programsProvider.notifier)
          .updateProgram(program.copyWith(name: newName));
    }
  }

  void _addExercise(
      BuildContext context, ProgramModel program, int dayIndex) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddExerciseSheet(
        program: program,
        dayIndex: dayIndex,
      ),
    );
  }

  Future<void> _exportToPdf(
      BuildContext context, ProgramModel program) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (ctx) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              program.name,
              style: pw.TextStyle(
                  fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Text(
            'Generated ${DateFormat('MMMM d, yyyy').format(DateTime.now())}',
            style:
                const pw.TextStyle(fontSize: 11, color: PdfColors.grey600),
          ),
          if (program.goal.isNotEmpty || program.experienceLevel.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 4),
              child: pw.Text(
                '${program.goal}  ·  ${program.experienceLevel}',
                style: const pw.TextStyle(
                    fontSize: 11, color: PdfColors.grey700),
              ),
            ),
          pw.SizedBox(height: 20),
          ...program.days.map((day) => pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Header(level: 1, child: pw.Text(day.name)),
                  pw.TableHelper.fromTextArray(
                    headers: ['Exercise', 'Sets', 'Reps', 'Rest'],
                    data: day.exercises
                        .map((ex) => [
                              ex.name,
                              '${ex.sets}',
                              '${ex.repsFrom}–${ex.repsTo}',
                              ex.restTime
                            ])
                        .toList(),
                    border:
                        pw.TableBorder.all(color: PdfColors.grey300),
                    headerStyle:
                        pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    cellPadding: const pw.EdgeInsets.symmetric(
                        horizontal: 8, vertical: 6),
                  ),
                  pw.SizedBox(height: 16),
                ],
              )),
        ],
      ),
    );
    await Printing.layoutPdf(
      onLayout: (_) async => pdf.save(),
      name:
          '${program.name.replaceAll(' ', '_')}.pdf',
    );
  }

  Future<void> _shareAsJson(
      BuildContext context, ProgramModel program) async {
    try {
      final json =
          const JsonEncoder.withIndent('  ').convert(program.toJson());
      final dir = await getTemporaryDirectory();
      final fileName =
          '${program.name.replaceAll(RegExp(r'[^\w\s]'), '').replaceAll(' ', '_')}.fittrack.json';
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(json);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/json')],
        subject: 'FitTrack Program: ${program.name}',
        text: 'My workout program "${program.name}" from FitTrack',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Export failed: $e'),
              backgroundColor: primaryRed),
        );
      }
    }
  }

  Future<void> _refreshExerciseData(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(
          content: Text('Refreshing exercise images…'),
          duration: Duration(seconds: 60)),
    );
    // Clear the exercise cache so extra_exercises.json is reloaded fresh.
    ExerciseRepository.clearCache();
    await ProgramSeeder.seedIfEmpty();
    final patched =
        await ref.read(programsProvider.notifier).refreshExerciseImages();
    if (context.mounted) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
            content: Text(patched > 0
                ? 'Done! Updated images for $patched exercise${patched == 1 ? '' : 's'}.'
                : 'All images are already up to date.'),
            backgroundColor: tealSuccess),
      );
    }
  }

  void _reorderExercise(
      ProgramModel program, int dayIndex, int oldIndex, int newIndex) {
    HapticFeedback.selectionClick();
    final days = List.of(program.days);
    final exercises = List.of(days[dayIndex].exercises);
    final item = exercises.removeAt(oldIndex);
    exercises.insert(newIndex, item);
    final updatedDay = days[dayIndex].copyWith(exercises: exercises);
    days[dayIndex] = updatedDay;
    final updatedProgram = program.copyWith(days: days);
    ref.read(programsProvider.notifier).updateProgram(updatedProgram);
  }
}

// ── Add Exercise Sheet ─────────────────────────────────────────────────────────

class _AddExerciseSheet extends ConsumerStatefulWidget {
  final ProgramModel program;
  final int dayIndex;

  const _AddExerciseSheet({required this.program, required this.dayIndex});

  @override
  ConsumerState<_AddExerciseSheet> createState() => _AddExerciseSheetState();
}

class _AddExerciseSheetState extends ConsumerState<_AddExerciseSheet> {
  final _searchController = TextEditingController();
  ExerciseModel? _selected;
  String _bodyPart = 'chest';

  static const _filters = [
    ('Chest', 'chest'),
    ('Back', 'back'),
    ('Shoulders', 'shoulders'),
    ('Arms', 'upper arms'),
    ('Legs', 'upper legs'),
    ('Calves', 'lower legs'),
    ('Core', 'waist'),
    ('Cardio', 'cardio'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(exerciseSearchProvider.notifier).loadSimilar('chest');
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilter(String bodyPart) {
    setState(() {
      _bodyPart = bodyPart;
      _selected = null;
      _searchController.clear();
    });
    ref.read(exerciseSearchProvider.notifier).loadSimilar(bodyPart);
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(exerciseSearchProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.97,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 4),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor.withAlpha(80),
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            // Header
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  Text('Add Exercise',
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => _showCreateCustom(context),
                    icon: const Icon(Icons.add_circle_rounded,
                        size: 16, color: steelBlue),
                    label: const Text('Custom',
                        style: TextStyle(
                            color: steelBlue,
                            fontWeight: FontWeight.w700,
                            fontSize: 13)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search exercises…',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            _applyFilter(_bodyPart);
                            setState(() {});
                          },
                        )
                      : null,
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onChanged: (q) {
                  setState(() {});
                  if (q.length > 2) {
                    ref.read(exerciseSearchProvider.notifier).search(q);
                  } else if (q.isEmpty) {
                    _applyFilter(_bodyPart);
                  }
                },
              ),
            ),
            const SizedBox(height: 8),
            // Body part filter chips
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Colors.white, Colors.white, Colors.transparent],
                stops: [0.0, 0.80, 1.0],
              ).createShader(bounds),
              blendMode: BlendMode.dstIn,
              child: SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(12, 0, 32, 0),
                  itemCount: _filters.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final (label, value) = _filters[i];
                    final sel = _bodyPart == value &&
                        _searchController.text.isEmpty;
                    return GestureDetector(
                      onTap: () => _applyFilter(value),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: sel
                              ? primaryRed
                              : Theme.of(context).cardTheme.color,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: sel
                                  ? primaryRed
                                  : Theme.of(context)
                                      .dividerColor
                                      .withAlpha(60)),
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            color: sel
                                ? Colors.white
                                : const Color(0xFF64748B),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Exercise grid
            Expanded(
              child: searchState.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: tealSuccess))
                  : searchState.results.isEmpty
                      ? const Center(child: Text('No exercises found'))
                      : GridView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 0.72,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemCount: searchState.results.length,
                          itemBuilder: (context, index) {
                            final ex = searchState.results[index];
                            final isSelected = _selected?.id == ex.id;
                            return _AddExerciseGridCard(
                              exercise: ex,
                              selected: isSelected,
                              onTap: () => setState(
                                  () => _selected = isSelected ? null : ex),
                            );
                          },
                        ),
            ),
            if (_selected != null)
              Padding(
                padding: EdgeInsets.fromLTRB(
                    16,
                    8,
                    16,
                    MediaQuery.of(context).viewPadding.bottom + 16),
                child: FilledButton.icon(
                  onPressed: _confirmAdd,
                  icon: const Icon(Icons.add_rounded),
                  label: Text('Add ${_selected!.name}',
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  style: FilledButton.styleFrom(
                    backgroundColor: primaryRed,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showCreateCustom(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreateCustomExerciseSheet(
        onCreated: (exercise) {
          // Immediately add the newly created exercise to the program.
          _addExerciseToProgramAndPop(exercise);
        },
      ),
    );
  }

  void _addExerciseToProgramAndPop(ExerciseModel exercise) {
    HapticFeedback.mediumImpact();
    final newExercise = exercise.copyWith(sets: 3, repsFrom: '8', repsTo: '12');
    final days = List.of(widget.program.days);
    final exercises = List.of(days[widget.dayIndex].exercises);
    exercises.add(newExercise);
    final updatedDay = days[widget.dayIndex].copyWith(exercises: exercises);
    days[widget.dayIndex] = updatedDay;
    final updatedProgram = widget.program.copyWith(days: days);
    ref.read(programsProvider.notifier).updateProgram(updatedProgram);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added ${exercise.name}'),
          backgroundColor: tealSuccess,
        ),
      );
    }
  }

  void _confirmAdd() {
    if (_selected == null) return;
    _addExerciseToProgramAndPop(_selected!);
  }
}

// ── Add Exercise Grid Card (used inside _AddExerciseSheet) ───────────────────

class _AddExerciseGridCard extends StatelessWidget {
  final ExerciseModel exercise;
  final bool selected;
  final VoidCallback onTap;

  const _AddExerciseGridCard({
    required this.exercise,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final muscle = exercise.targetMuscles.isNotEmpty
        ? exercise.targetMuscles.first
        : exercise.bodyParts.isNotEmpty
            ? exercise.bodyParts.first
            : '';

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? tealSuccess : Theme.of(context).dividerColor.withAlpha(60),
            width: selected ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(13)),
                    child: SizedBox(
                      width: double.infinity,
                      child: ExerciseGifWidget(
                        gifUrl: exercise.gifUrl,
                        exerciseName: exercise.name,
                        width: 200,
                        height: 200,
                        borderRadius: 0,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 52,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(6, 4, 6, 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          exercise.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 9.5, fontWeight: FontWeight.w700),
                        ),
                        if (muscle.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(muscle,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: steelBlue,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (selected)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: tealSuccess.withAlpha(20),
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
              ),
            Positioned(
              top: 4,
              right: 4,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: selected ? tealSuccess : Colors.black45,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  selected ? Icons.check_rounded : Icons.add_rounded,
                  size: 11,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Exercise Grid Card (normal view) ──────────────────────────────────────────

class _ExerciseGridCard extends ConsumerWidget {
  final ExerciseModel exercise;
  final ProgramModel program;
  final int dayIndex;
  final int exerciseIndex;
  final String? supersetLabel;
  final VoidCallback? onDelete;

  const _ExerciseGridCard({
    super.key,
    required this.exercise,
    required this.program,
    required this.dayIndex,
    required this.exerciseIndex,
    this.supersetLabel,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inSuperset = supersetLabel != null;

    return GestureDetector(
      onTap: () =>
          context.push('/exercises/${exercise.id}', extra: exercise),
      onLongPress: () {
        HapticFeedback.mediumImpact();
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (_) => Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                        color: borderLight,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 12),
                Text(exercise.name,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.edit_rounded, color: steelBlue),
                  title: const Text('Edit'),
                  contentPadding: EdgeInsets.zero,
                  onTap: () {
                    Navigator.pop(context);
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => EditExerciseSheet(
                        exercise: exercise,
                        program: program,
                        dayIndex: dayIndex,
                        exerciseIndex: exerciseIndex,
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_rounded, color: primaryRed),
                  title: const Text('Remove',
                      style: TextStyle(color: primaryRed)),
                  contentPadding: EdgeInsets.zero,
                  onTap: () {
                    Navigator.pop(context);
                    onDelete?.call();
                  },
                ),
              ],
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: inSuperset
                ? steelBlue.withAlpha(180)
                : Theme.of(context).dividerColor.withAlpha(60),
            width: inSuperset ? 2 : 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // GIF
                  Expanded(
                    flex: 3,
                    child: SizedBox(
                      width: double.infinity,
                      child: ExerciseGifWidget(
                        gifUrl: exercise.gifUrl,
                        exerciseName: exercise.name,
                        width: 200,
                        height: 200,
                        borderRadius: 0,
                      ),
                    ),
                  ),
                  // Info
                  SizedBox(
                    height: 52,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(6, 4, 6, 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            exercise.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 9.5, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${exercise.sets}×${exercise.repsFrom}–${exercise.repsTo}',
                            style: const TextStyle(
                                fontSize: 9,
                                color: primaryRed,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              // Superset label badge (top-left)
              if (inSuperset)
                Positioned(
                  top: 4,
                  left: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: steelBlue,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(supersetLabel!,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w800)),
                  ),
                )
              // NEW badge (only when not in superset, to avoid overlap)
              else if (exercise.isNew)
                Positioned(
                  top: 4,
                  left: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: tealSuccess,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: const Text('NEW',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
              // Edit button
              Positioned(
                top: 3,
                right: 3,
                child: GestureDetector(
                  onTap: () => _showEditSheet(context),
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: const Icon(Icons.edit_rounded,
                        size: 11, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditSheet(BuildContext context) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditExerciseSheet(
        exercise: exercise,
        program: program,
        dayIndex: dayIndex,
        exerciseIndex: exerciseIndex,
      ),
    );
  }
}

// ── Exercise Row (reorder mode only) ─────────────────────────────────────────

class _ExerciseRow extends ConsumerWidget {
  final ExerciseModel exercise;
  final ProgramModel program;
  final int dayIndex;
  final int exerciseIndex;
  final bool reorderMode;
  final String? supersetLabel;
  final bool supersetContinuesAbove;
  final bool supersetContinuesBelow;
  final VoidCallback? onDelete;

  const _ExerciseRow({
    required this.exercise,
    required this.program,
    required this.dayIndex,
    required this.exerciseIndex,
    required this.reorderMode,
    this.supersetLabel,
    this.supersetContinuesAbove = false,
    this.supersetContinuesBelow = false,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inSuperset = supersetLabel != null;

    final rowCard = GestureDetector(
      onTap: reorderMode
          ? null
          : () => context.push('/exercises/${exercise.id}', extra: exercise),
      child: Card(
        margin: EdgeInsets.only(
          bottom: supersetContinuesBelow ? 2 : 8,
          left: inSuperset ? 4 : 0,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: inSuperset
              ? BorderSide(color: steelBlue.withAlpha(160), width: 1.5)
              : BorderSide.none,
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Icon(Icons.drag_handle_rounded,
                  color: Color(0xFFAAAAAA), size: 20),
              const SizedBox(width: 8),
              ExerciseGifWidget(
                  gifUrl: exercise.gifUrl,
                  exerciseName: exercise.name,
                  width: 52,
                  height: 52),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (inSuperset) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: steelBlue,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(supersetLabel!,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800)),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Expanded(
                          child: Text(
                            exercise.name,
                            style: Theme.of(context).textTheme.titleMedium,
                            maxLines: 2,
                          ),
                        ),
                        if (exercise.isNew && !inSuperset) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: tealSuccess,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('NEW',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ],
                        if (exercise.technique != 'standard') ...[
                          const SizedBox(width: 6),
                          TechniqueBadge(technique: exercise.technique),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${exercise.sets} × ${exercise.repsFrom}–${exercise.repsTo} · ${exercise.restTime}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (reorderMode)
                IconButton(
                  icon: const Icon(Icons.delete_rounded,
                      size: 18, color: primaryRed),
                  onPressed: onDelete,
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                )
              else
                IconButton(
                  icon: const Icon(Icons.edit_rounded,
                      size: 18, color: Color(0xFF8899AA)),
                  onPressed: () => _showEditSheet(context),
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
            ],
          ),
        ),
      ),
    );

    if (!inSuperset) return rowCard;

    // Wrap with SUPERSET header + left bar (same visual as live workout).
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!supersetContinuesAbove)
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 2),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: steelBlue.withAlpha(30),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: steelBlue.withAlpha(80)),
              ),
              child: const Text('SUPERSET',
                  style: TextStyle(
                      fontSize: 10,
                      color: steelBlue,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5)),
            ),
          ),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 4,
                margin: EdgeInsets.only(
                    top: supersetContinuesAbove ? 0 : 0,
                    bottom: supersetContinuesBelow ? 2 : 8),
                decoration: BoxDecoration(
                  color: steelBlue,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(child: rowCard),
            ],
          ),
        ),
      ],
    );
  }

  void _showEditSheet(BuildContext context) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditExerciseSheet(
        exercise: exercise,
        program: program,
        dayIndex: dayIndex,
        exerciseIndex: exerciseIndex,
      ),
    );
  }
}
