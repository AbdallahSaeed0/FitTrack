import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/exercise_model.dart';
import '../../data/repositories/custom_exercise_repository.dart';
import '../../data/repositories/exercise_repository.dart';
import '../../shared/widgets/exercise_gif_widget.dart';

class CreateCustomExerciseSheet extends StatefulWidget {
  final void Function(ExerciseModel exercise) onCreated;

  const CreateCustomExerciseSheet({super.key, required this.onCreated});

  @override
  State<CreateCustomExerciseSheet> createState() =>
      _CreateCustomExerciseSheetState();
}

class _CreateCustomExerciseSheetState
    extends State<CreateCustomExerciseSheet> {
  final _nameCtrl = TextEditingController();
  String _bodyPart = 'chest';
  String _equipment = 'dumbbell';
  bool _saving = false;

  // The gifUrl borrowed from an existing exercise in the library.
  String _selectedGifUrl = '';
  String _selectedGifLabel = '';

  static const _bodyParts = [
    ('Chest', 'chest'),
    ('Back', 'back'),
    ('Shoulders', 'shoulders'),
    ('Upper Arms (Biceps / Triceps)', 'upper arms'),
    ('Upper Legs (Quads / Hamstrings / Glutes)', 'upper legs'),
    ('Lower Legs (Calves)', 'lower legs'),
    ('Core / Waist', 'waist'),
    ('Cardio', 'cardio'),
  ];

  static const _equipments = [
    ('Dumbbell', 'dumbbell'),
    ('Barbell', 'barbell'),
    ('Cable', 'cable'),
    ('Machine', 'machine'),
    ('Bodyweight', 'body weight'),
    ('EZ-Bar', 'ez barbell'),
    ('Kettlebell', 'kettlebell'),
    ('Band / Other', 'band'),
  ];

  static const _muscleByBodyPart = {
    'chest': 'pectorals',
    'back': 'lats',
    'shoulders': 'delts',
    'upper arms': 'biceps brachii',
    'upper legs': 'quadriceps',
    'lower legs': 'calves',
    'waist': 'abs',
    'cardio': 'cardiovascular system',
  };

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  // Opens the image-picker sheet and waits for the user to choose.
  Future<void> _pickFromLibrary() async {
    final result = await showModalBottomSheet<ExerciseModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LibraryImagePickerSheet(bodyPart: _bodyPart),
    );
    if (result != null && mounted) {
      setState(() {
        _selectedGifUrl = result.gifUrl;
        _selectedGifLabel = result.name;
      });
    }
  }

  Future<void> _create() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an exercise name')),
      );
      return;
    }
    setState(() => _saving = true);
    HapticFeedback.mediumImpact();

    final exercise = ExerciseModel(
      id: 'custom_${const Uuid().v4()}',
      name: name,
      gifUrl: _selectedGifUrl,
      sets: 3,
      repsFrom: '8',
      repsTo: '12',
      restTime: '2-3 min',
      technique: 'standard',
      targetMuscles: [_muscleByBodyPart[_bodyPart] ?? _bodyPart],
      bodyParts: [_bodyPart],
      equipments: [_equipment],
    );

    await CustomExerciseRepository.instance.save(exercise);
    ExerciseRepository.clearCache();

    if (mounted) {
      Navigator.pop(context);
      widget.onCreated(exercise);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = _selectedGifUrl.isNotEmpty;

    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).viewPadding.bottom + 24),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
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
                    color: borderLight,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: steelBlue.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.add_circle_rounded,
                      color: steelBlue, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Create Custom Exercise',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800)),
                      Text('Appears in all exercise searches',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: const Color(0xFF8899AA))),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Image from library ────────────────────────────────────────────
            GestureDetector(
              onTap: _pickFromLibrary,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 130,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: hasImage
                        ? steelBlue
                        : Theme.of(context).dividerColor.withAlpha(80),
                    width: hasImage ? 2 : 1,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: hasImage
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          ExerciseGifWidget(
                            gifUrl: _selectedGifUrl,
                            exerciseName: _selectedGifLabel,
                            width: double.infinity,
                            height: 130,
                            borderRadius: 0,
                          ),
                          // Dark overlay at bottom
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    Colors.black.withAlpha(180),
                                    Colors.transparent
                                  ],
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _selectedGifLabel,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 7, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: steelBlue,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text('Change',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: steelBlue.withAlpha(20),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                                Icons.image_search_rounded,
                                size: 28,
                                color: steelBlue),
                          ),
                          const SizedBox(height: 8),
                          const Text('Pick image from exercise library',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: steelBlue,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text('Optional — search by movement',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.color)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // Name
            TextField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Exercise Name *',
                hintText: 'e.g. Cable Lateral Raise',
                prefixIcon: Container(
                  margin: const EdgeInsets.all(10),
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: steelBlue.withAlpha(15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.fitness_center_rounded,
                      size: 16, color: steelBlue),
                ),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),

            // Muscle group
            DropdownButtonFormField<String>(
              initialValue: _bodyPart,
              decoration: InputDecoration(
                labelText: 'Muscle Group',
                prefixIcon: Container(
                  margin: const EdgeInsets.all(10),
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: primaryRed.withAlpha(15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.accessibility_new_rounded,
                      size: 16, color: primaryRed),
                ),
              ),
              items: _bodyParts
                  .map((e) =>
                      DropdownMenuItem(value: e.$2, child: Text(e.$1)))
                  .toList(),
              onChanged: (v) {
                setState(() => _bodyPart = v ?? _bodyPart);
                // Clear selected image so user picks one matching the new muscle group.
                if (_selectedGifUrl.isNotEmpty) {
                  setState(() {
                    _selectedGifUrl = '';
                    _selectedGifLabel = '';
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // Equipment
            DropdownButtonFormField<String>(
              initialValue: _equipment,
              decoration: InputDecoration(
                labelText: 'Equipment',
                prefixIcon: Container(
                  margin: const EdgeInsets.all(10),
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: tealSuccess.withAlpha(15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.build_rounded,
                      size: 16, color: tealSuccess),
                ),
              ),
              items: _equipments
                  .map((e) =>
                      DropdownMenuItem(value: e.$2, child: Text(e.$1)))
                  .toList(),
              onChanged: (v) =>
                  setState(() => _equipment = v ?? _equipment),
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _saving ? null : _create,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: steelBlue,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_rounded, size: 18),
                        SizedBox(width: 8),
                        Text('Create & Add Exercise',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Library image picker sheet — search existing exercises, pick their GIF
// ─────────────────────────────────────────────────────────────────────────────

class _LibraryImagePickerSheet extends StatefulWidget {
  final String bodyPart;
  const _LibraryImagePickerSheet({required this.bodyPart});

  @override
  State<_LibraryImagePickerSheet> createState() =>
      _LibraryImagePickerSheetState();
}

class _LibraryImagePickerSheetState
    extends State<_LibraryImagePickerSheet> {
  final _searchCtrl = TextEditingController();
  List<ExerciseModel> _results = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final repo = ExerciseRepository();
      final q = _searchCtrl.text.trim();
      List<ExerciseModel> results;
      if (q.isNotEmpty) {
        results = await repo.searchByName(q, limit: 40);
      } else {
        results = await repo.getSimilarExercises(widget.bodyPart, limit: 150);
      }
      // Only show exercises that actually have a GIF.
      results = results.where((e) => e.gifUrl.isNotEmpty).toList();
      setState(() => _results = results);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.97,
      expand: false,
      builder: (_, scrollCtrl) => Container(
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
                margin: const EdgeInsets.only(top: 10, bottom: 4),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: borderLight,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            // Header
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  const Icon(Icons.image_search_rounded,
                      color: steelBlue, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Pick an Image',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800)),
                        const Text(
                            'Search for a similar movement to borrow its image',
                            style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF8899AA))),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Search
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: TextField(
                controller: _searchCtrl,
                autofocus: false,
                onChanged: (_) => _load(),
                decoration: InputDecoration(
                  hintText: 'Search by name or muscle…',
                  prefixIcon:
                      const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon:
                              const Icon(Icons.clear_rounded, size: 16),
                          onPressed: () {
                            _searchCtrl.clear();
                            _load();
                          },
                        )
                      : null,
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: borderLight)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: borderLight)),
                ),
              ),
            ),
            // Grid
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _results.isEmpty
                      ? const Center(
                          child: Text('No results',
                              style:
                                  TextStyle(color: Color(0xFF8899AA))))
                      : GridView.builder(
                          controller: scrollCtrl,
                          padding:
                              const EdgeInsets.fromLTRB(12, 4, 12, 24),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 0.78,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemCount: _results.length,
                          itemBuilder: (_, i) {
                            final ex = _results[i];
                            return GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                Navigator.pop(context, ex);
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .cardTheme
                                      .color,
                                  borderRadius:
                                      BorderRadius.circular(12),
                                  border: Border.all(
                                      color: Theme.of(context)
                                          .dividerColor
                                          .withAlpha(60)),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Column(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: ExerciseGifWidget(
                                        gifUrl: ex.gifUrl,
                                        exerciseName: ex.name,
                                        width: double.infinity,
                                        height: double.infinity,
                                        borderRadius: 0,
                                      ),
                                    ),
                                    SizedBox(
                                      height: 44,
                                      child: Padding(
                                        padding:
                                            const EdgeInsets.fromLTRB(
                                                6, 4, 6, 6),
                                        child: Text(
                                          ex.name,
                                          maxLines: 2,
                                          overflow:
                                              TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              fontSize: 9.5,
                                              fontWeight:
                                                  FontWeight.w600),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
