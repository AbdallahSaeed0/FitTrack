import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/image_bytes_saver.dart';
import '../../data/models/progress_photo_model.dart';
import '../../shared/screens/crop_image_screen.dart';

class ProgressPhotosScreen extends StatefulWidget {
  const ProgressPhotosScreen({super.key});

  @override
  State<ProgressPhotosScreen> createState() => _ProgressPhotosScreenState();
}

class _ProgressPhotosScreenState extends State<ProgressPhotosScreen> {
  final _picker = ImagePicker();
  List<ProgressPhotoModel> _photos = [];

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  void _loadPhotos() {
    // photos are kept in _photos list directly; nothing to reload from persistent store
  }

  Future<void> _addPhoto(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 90,
      );
      if (picked == null || !mounted) return;

      // Read bytes immediately — fixes camera black screen where file isn't ready yet
      final rawBytes = await picked.readAsBytes();
      if (!mounted) return;

      final croppedBytes = await Navigator.push<Uint8List>(
        context,
        MaterialPageRoute(
          builder: (_) => CropImageScreen(
            file: picked,
            preloadedBytes: rawBytes,
          ),
        ),
      );

      // Guard: user cancelled crop
      if (!mounted || croppedBytes == null) return;

      final savedPath = await saveCroppedBytes(
        croppedBytes,
        subfolder: 'progress_photos',
      );

      if (!mounted) return;
      await _showDetailsDialog(savedPath);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load photo: $e')),
      );
    }
  }

  Future<void> _showDetailsDialog(String photoPath) async {
    final weightCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom +
              MediaQuery.of(ctx).padding.bottom +
              24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Save Photo', style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: weightCtrl,
              decoration: const InputDecoration(
                labelText: 'Bodyweight (kg)  — optional',
                prefixIcon: Icon(Icons.monitor_weight_outlined),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesCtrl,
              decoration: const InputDecoration(
                labelText: 'Notes  — optional',
                prefixIcon: Icon(Icons.notes_rounded),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final photo = ProgressPhotoModel(
                    id: const Uuid().v4(),
                    photoPath: photoPath,
                    dateTaken: DateTime.now(),
                    weightKg: double.tryParse(weightCtrl.text),
                    notes: notesCtrl.text.trim().isEmpty
                        ? null
                        : notesCtrl.text.trim(),
                  );
                  if (ctx.mounted) {
                    setState(() => _photos = [photo, ..._photos]
                      ..sort((a, b) => b.dateTaken.compareTo(a.dateTaken)));
                    Navigator.pop(ctx);
                  }
                },
                child: const Text('Save Photo'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddOptions() {
    HapticFeedback.selectionClick();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).cardTheme.color,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: primaryRed),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(ctx);
                _addPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.photo_library_rounded, color: steelBlue),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _addPhoto(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showFullPhoto(ProgressPhotoModel photo) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => _PhotoDetailScreen(
        photo: photo,
        onDeleted: () {
          setState(() => _photos.removeWhere((p) => p.id == photo.id));
        },
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress Photos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_a_photo_rounded),
            onPressed: _showAddOptions,
            tooltip: 'Add Photo',
          ),
        ],
      ),
      body: _photos.isEmpty ? _emptyState() : _grid(),
      floatingActionButton: _photos.isNotEmpty
          ? FloatingActionButton(
              onPressed: _showAddOptions,
              backgroundColor: primaryRed,
              child:
                  const Icon(Icons.add_a_photo_rounded, color: Colors.white),
            )
          : null,
    );
  }

  Widget _emptyState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: steelBlue.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.photo_camera_rounded,
                  size: 52, color: steelBlue),
            ),
            const SizedBox(height: 20),
            Text('No progress photos yet',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('Track your transformation journey',
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: _showAddOptions,
              icon: const Icon(Icons.add_a_photo_rounded),
              label: const Text('Add First Photo'),
            ),
          ],
        ),
      );

  /// Groups photos by calendar day (newest group first).
  Map<String, List<ProgressPhotoModel>> _groupByDate() {
    final map = <String, List<ProgressPhotoModel>>{};
    for (final p in _photos) {
      final key = DateFormat('yyyy-MM-dd').format(p.dateTaken);
      map.putIfAbsent(key, () => []).add(p);
    }
    final sorted = map.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));
    return Map.fromEntries(sorted);
  }

  Widget _grid() {
    final groups = _groupByDate();
    final keys = groups.keys.toList();
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(12, 12, 12, 12 + bottomPad + 72),
      itemCount: keys.length,
      itemBuilder: (_, gi) {
        final dateKey = keys[gi];
        final date = DateTime.parse(dateKey);
        final headerLabel = DateFormat('MMM d, yyyy').format(date).toUpperCase();
        final photos = groups[dateKey]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              child: Row(
                children: [
                  Text(
                    headerLabel,
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Divider(color: Color(0xFF334155), height: 1),
                  ),
                ],
              ),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.72,
              ),
              itemCount: photos.length,
              itemBuilder: (_, i) => _PhotoTile(
                photo: photos[i],
                onTap: () => _showFullPhoto(photos[i]),
              ),
            ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}

// ── Photo tile ────────────────────────────────────────────────────────────────

class _PhotoTile extends StatelessWidget {
  final ProgressPhotoModel photo;
  final VoidCallback onTap;

  const _PhotoTile({required this.photo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('d MMM yyyy').format(photo.dateTaken);

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _nativePhoto(photo.photoPath, BoxFit.cover),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(10, 28, 10, 10),
                decoration: const BoxDecoration(
                  color: Color(0xB4000000),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(dateLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        )),
                    if (photo.weightKg != null)
                      Text('${photo.weightKg!.toStringAsFixed(1)} kg',
                          style: TextStyle(
                            color: Colors.white.withAlpha(200),
                            fontSize: 11,
                          )),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Platform-aware image builder ─────────────────────────────────────────────
// Handles: http(s)://, blob:, data: (web data URL), file:// and bare native paths.
Widget _nativePhoto(String path, BoxFit fit) {
  if (path.startsWith('http') ||
      path.startsWith('blob:') ||
      path.startsWith('data:') ||
      path.startsWith('file://')) {
    return Image.network(path, fit: fit,
        errorBuilder: (_, __, ___) => Container(
              color: steelBlue.withAlpha(20),
              child: const Icon(Icons.broken_image_rounded,
                  size: 48, color: steelBlue),
            ));
  }
  // Native path — use File image (more reliable than file:// URI on Android)
  try {
    return Image.file(
      File(path),
      fit: fit,
      errorBuilder: (_, __, ___) => Container(
            color: steelBlue.withAlpha(20),
            child: const Icon(Icons.broken_image_rounded,
                size: 48, color: steelBlue),
          ),
    );
  } catch (_) {
    return Container(
      color: steelBlue.withAlpha(20),
      child: const Icon(Icons.broken_image_rounded, size: 48, color: steelBlue),
    );
  }
}

// ── Full-screen detail ────────────────────────────────────────────────────────

class _PhotoDetailScreen extends StatelessWidget {
  final ProgressPhotoModel photo;
  final VoidCallback onDeleted;

  const _PhotoDetailScreen({required this.photo, required this.onDeleted});

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('EEEE, d MMMM yyyy').format(photo.dateTaken);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(dateLabel,
            style: const TextStyle(color: Colors.white, fontSize: 14)),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: primaryRed),
            tooltip: 'Delete',
            onPressed: () {
              Navigator.pop(context);
              onDeleted();
            },
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: _nativePhoto(photo.photoPath, BoxFit.contain),
            ),
            if (photo.weightKg != null || photo.notes != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                color: const Color(0xFF1A1A2E),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (photo.weightKg != null) ...[
                      Row(children: [
                        const Icon(Icons.monitor_weight_outlined,
                            size: 16, color: steelBlue),
                        const SizedBox(width: 8),
                        Text(
                          '${photo.weightKg!.toStringAsFixed(1)} kg',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600),
                        ),
                      ]),
                      if (photo.notes != null) const SizedBox(height: 8),
                    ],
                    if (photo.notes != null)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.notes_rounded,
                              size: 16, color: steelBlue),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(photo.notes!,
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 13)),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
