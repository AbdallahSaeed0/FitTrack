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
import 'edit_exercise_sheet.dart';
import 'programs_provider.dart';

class ProgramDetailScreen extends ConsumerStatefulWidget {
  final String programId;

  const ProgramDetailScreen({super.key, required this.programId});

  @override
  ConsumerState<ProgramDetailScreen> createState() => _ProgramDetailScreenState();
}

class _ProgramDetailScreenState extends ConsumerState<ProgramDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _initTabController();
  }

  void _initTabController() {
    final program = ref.read(programsProvider.notifier).getById(widget.programId);
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

    return Scaffold(
      appBar: AppBar(
        title: Text(program.name),
        actions: [
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
          // Refresh button — re-fetches exercise data from API
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
                  const SnackBar(content: Text('Program set as active'), backgroundColor: tealSuccess),
                );
              },
              child: const Text('Set Active', style: TextStyle(color: primaryRed)),
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
          : TabBarView(
              controller: _tabController,
              children: List.generate(program.days.length, (dayIdx) {
                final day = program.days[dayIdx];
                if (day.exercises.isEmpty) {
                  return const Center(child: Text('No exercises for this day'));
                }
                return ReorderableListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: day.exercises.length,
                  onReorder: (oldIndex, newIndex) {
                    if (newIndex > oldIndex) newIndex--;
                    _reorderExercise(program, dayIdx, oldIndex, newIndex);
                  },
                  itemBuilder: (context, exIdx) {
                    final exercise = day.exercises[exIdx];
                    return ReorderableDragStartListener(
                      key: ValueKey(exercise.id + exIdx.toString()),
                      index: exIdx,
                      child: _ExerciseRow(
                        exercise: exercise,
                        program: program,
                        dayIndex: dayIdx,
                        exerciseIndex: exIdx,
                      ),
                    );
                  },
                );
              }),
            ),
    );
  }

  Future<void> _exportToPdf(BuildContext context, ProgramModel program) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (ctx) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              program.name,
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Text(
            'Generated ${DateFormat('MMMM d, yyyy').format(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600),
          ),
          if (program.goal.isNotEmpty || program.experienceLevel.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 4),
              child: pw.Text(
                '${program.goal}  ·  ${program.experienceLevel}',
                style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
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
                    .map((ex) => [ex.name, '${ex.sets}', '${ex.repsFrom}–${ex.repsTo}', ex.restTime])
                    .toList(),
                border: pw.TableBorder.all(color: PdfColors.grey300),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              ),
              pw.SizedBox(height: 16),
            ],
          )),
        ],
      ),
    );
    await Printing.layoutPdf(
      onLayout: (_) async => pdf.save(),
      name: '${program.name.replaceAll(' ', '_')}.pdf',
    );
  }

  Future<void> _shareAsJson(BuildContext context, ProgramModel program) async {
    try {
      final json = const JsonEncoder.withIndent('  ').convert(program.toJson());
      final dir = await getTemporaryDirectory();
      final fileName = '${program.name.replaceAll(RegExp(r'[^\w\s]'), '').replaceAll(' ', '_')}.fittrack.json';
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
          SnackBar(content: Text('Export failed: $e'), backgroundColor: primaryRed),
        );
      }
    }
  }

  Future<void> _refreshExerciseData(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('Refreshing exercise data from API...'), duration: Duration(seconds: 60)),
    );
    await ProgramSeeder.seedIfEmpty();
    ref.read(programsProvider.notifier).refresh();
    if (context.mounted) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(content: Text('Exercise data updated!'), backgroundColor: tealSuccess),
      );
    }
  }

  void _reorderExercise(ProgramModel program, int dayIndex, int oldIndex, int newIndex) {
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

class _ExerciseRow extends ConsumerWidget {
  final ExerciseModel exercise;
  final ProgramModel program;
  final int dayIndex;
  final int exerciseIndex;

  const _ExerciseRow({
    required this.exercise,
    required this.program,
    required this.dayIndex,
    required this.exerciseIndex,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => context.push('/exercises/${exercise.id}', extra: exercise),
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Icon(Icons.drag_handle_rounded, color: Color(0xFFAAAAAA), size: 20),
              const SizedBox(width: 8),
              ExerciseGifWidget(gifUrl: exercise.gifUrl, exerciseName: exercise.name, width: 52, height: 52),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            exercise.name,
                            style: Theme.of(context).textTheme.titleMedium,
                            maxLines: 2,
                          ),
                        ),
                        if (exercise.isNew) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: tealSuccess,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('NEW', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
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
              IconButton(
                icon: const Icon(Icons.edit_rounded, size: 18, color: Color(0xFF8899AA)),
                onPressed: () => _showEditSheet(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
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
