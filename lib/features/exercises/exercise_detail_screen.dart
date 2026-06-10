import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/exercise_model.dart';
import '../../data/repositories/exercise_repository.dart';
import '../../shared/widgets/animated_exercise_image.dart';
import '../../shared/widgets/technique_badge.dart';

class ExerciseDetailScreen extends StatefulWidget {
  final String exerciseId;
  final ExerciseModel? exercise;

  const ExerciseDetailScreen({
    super.key,
    required this.exerciseId,
    this.exercise,
  });

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
  String? _enrichedGifUrl;
  bool _gifLoading = false;

  @override
  void initState() {
    super.initState();
    _tryEnrichGifUrl();
  }

  Future<void> _tryEnrichGifUrl({bool force = false}) async {
    final ex = widget.exercise;
    if (ex == null) return;
    // Skip if already has a gif and not forced refresh
    if (!force && ex.gifUrl.isNotEmpty && _enrichedGifUrl == null) {
      return;
    }
    if (force) setState(() => _gifLoading = true);
    try {
      final found = await ExerciseRepository().getByExactName(ex.name);
      if (mounted && found != null && found.gifUrl.isNotEmpty) {
        setState(() => _enrichedGifUrl = found.gifUrl);
      }
    } finally {
      if (mounted) setState(() => _gifLoading = false);
    }
  }

  List<String> _imageUrls(ExerciseModel ex) {
    final url = _enrichedGifUrl ?? ex.gifUrl;
    if (url.isEmpty) return [];
    if (url.contains('/0.jpg')) {
      return [url, url.replaceFirst('/0.jpg', '/1.jpg')];
    }
    return [url];
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
            expandedHeight: 320,
            pinned: true,
            actions: [
              if (_gifLoading)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white70)),
                )
              else
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: 'Refresh GIF',
                  onPressed: () => _tryEnrichGifUrl(force: true),
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: ClipRect(
                child: Padding(
                  padding: const EdgeInsets.only(top: 56, left: 8, right: 8),
                  child: GestureDetector(
                    onDoubleTap: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => Scaffold(
                          backgroundColor: Colors.black,
                          appBar: AppBar(
                            backgroundColor: Colors.black,
                            iconTheme:
                                const IconThemeData(color: Colors.white),
                            title: Text(widget.exercise?.name ?? '',
                                style:
                                    const TextStyle(color: Colors.white)),
                          ),
                          body: Center(
                            child: AnimatedExerciseImage(
                              imageUrls: imageUrls,
                              height: double.infinity,
                              fit: BoxFit.contain,
                              enableFullScreen: false,
                              fullScreenTitle: '',
                            ),
                          ),
                        ),
                      ));
                    },
                    child: AnimatedExerciseImage(
                      imageUrls: imageUrls,
                      height: 240,
                      fit: BoxFit.contain,
                      enableFullScreen: true,
                      fullScreenTitle: widget.exercise?.name ?? '',
                    ),
                  ),
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
