import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/exercise_model.dart';
import '../../data/services/workoutx_service.dart';
import '../../shared/providers/api_key_provider.dart';
import '../../shared/widgets/animated_exercise_image.dart';
import '../../shared/widgets/technique_badge.dart';

class ExerciseDetailScreen extends ConsumerStatefulWidget {
  final String exerciseId;
  final ExerciseModel? exercise;

  const ExerciseDetailScreen({
    super.key,
    required this.exerciseId,
    this.exercise,
  });

  @override
  ConsumerState<ExerciseDetailScreen> createState() =>
      _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends ConsumerState<ExerciseDetailScreen> {
  String? _workoutXGif;
  bool _loadingGif = false;

  @override
  void initState() {
    super.initState();
    _tryLoadWorkoutXGif();
  }

  Future<void> _tryLoadWorkoutXGif() async {
    final key = ref.read(apiKeyProvider);
    if (key.isEmpty || widget.exercise == null) return;
    setState(() => _loadingGif = true);
    final gif =
        await WorkoutXService(apiKey: key).getExerciseGif(widget.exercise!.name);
    if (mounted) {
      setState(() {
        _workoutXGif = gif;
        _loadingGif = false;
      });
    }
  }

  List<String> _imageUrls(ExerciseModel ex) {
    // Build the static frames from free-exercise-db
    final url = ex.gifUrl;
    final staticFrames = <String>[];
    if (url.isNotEmpty) {
      if (url.contains('/0.jpg')) {
        staticFrames
          ..add(url)
          ..add(url.replaceFirst('/0.jpg', '/1.jpg'));
      } else {
        staticFrames.add(url);
      }
    }

    // Prepend the WorkoutX animated GIF when available — keep static frames too
    if (_workoutXGif != null && _workoutXGif!.isNotEmpty) {
      return [_workoutXGif!, ...staticFrames];
    }
    return staticFrames;
  }

  @override
  Widget build(BuildContext context) {
    final ex = widget.exercise;
    if (ex == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Exercise')),
        body: const Center(child: Text('Exercise not found')),
      );
    }

    final imageUrls = _imageUrls(ex);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Hero image / animated frames ─────────────────────────────────────
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Padding(
                padding: const EdgeInsets.only(top: 56, left: 8, right: 8),
                child: Stack(
                  children: [
                    AnimatedExerciseImage(
                      imageUrls: imageUrls,
                      height: 240,
                      fit: BoxFit.contain,
                      enableFullScreen: true,
                      fullScreenTitle: widget.exercise?.name ?? '',
                    ),
                    // Loading badge while fetching from WorkoutX
                    if (_loadingGif)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: steelBlue.withAlpha(200),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 10,
                                height: 10,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white),
                              ),
                              SizedBox(width: 6),
                              Text('Loading GIF…',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 11)),
                            ],
                          ),
                        ),
                      ),
                    // Badge once WorkoutX GIF loaded
                    if (_workoutXGif != null)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: tealSuccess.withAlpha(200),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('WorkoutX GIF',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // ── Details ───────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(ex.name,
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 10),

                  // Tags
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (ex.bodyParts.isNotEmpty)
                        _Chip(label: ex.bodyParts.first, color: primaryRed),
                      if (ex.technique != 'standard')
                        _Chip(
                            label: TechniqueBadge.label(ex.technique),
                            color: steelBlue),
                      if (ex.equipments.isNotEmpty)
                        _Chip(
                            label: ex.equipments.first,
                            color: const Color(0xFF8899AA)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Muscles
                  if (ex.targetMuscles.isNotEmpty) ...[
                    _InfoRow(
                        label: 'Primary Muscles',
                        value: ex.targetMuscles.join(', ')),
                    const SizedBox(height: 8),
                  ],
                  if (ex.secondaryMuscles.isNotEmpty) ...[
                    _InfoRow(
                        label: 'Secondary Muscles',
                        value: ex.secondaryMuscles.join(', ')),
                    const SizedBox(height: 8),
                  ],
                  const SizedBox(height: 16),

                  // Instructions
                  if (ex.instructions.isNotEmpty) ...[
                    Text('Instructions',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    ...ex.instructions.asMap().entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: const BoxDecoration(
                                color: primaryRed,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${entry.key + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                entry.value,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Supporting widgets ────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  final String label;
  final Color color;

  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Text(
        label,
        style:
            TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
