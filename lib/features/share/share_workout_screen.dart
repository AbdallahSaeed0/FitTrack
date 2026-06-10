import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/session_model.dart';
import '../../data/repositories/program_repository.dart';
import 'share_service.dart';
import 'workout_card_widget.dart';

class ShareWorkoutScreen extends StatefulWidget {
  final WorkoutSessionModel session;
  const ShareWorkoutScreen({super.key, required this.session});

  @override
  State<ShareWorkoutScreen> createState() => _ShareWorkoutScreenState();
}

class _ShareWorkoutScreenState extends State<ShareWorkoutScreen> {
  final _cardKey = GlobalKey();
  final _picker = ImagePicker();

  late WorkoutShareData _shareData;
  CardTemplate _template = CardTemplate.minimal;
  bool _showExercises = true;
  bool _showQuote = true;
  bool _generating = false;
  Uint8List? _attachedPhotoBytes;

  @override
  void initState() {
    super.initState();
    final program =
        ProgramRepository.instance.getById(widget.session.programId);
    _shareData = WorkoutShareData.fromSession(
      widget.session,
      programName: program?.name ?? '',
    );
  }

  Future<void> _pickAttachPhoto(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 90,
      );
      if (picked == null || !mounted) return;
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      setState(() {
        _attachedPhotoBytes = bytes;
        _shareData = _shareData.copyWith(backgroundPhotoBytes: bytes);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load photo: $e')),
        );
      }
    }
  }

  Future<Uint8List?> _capture() async {
    final boundary =
        _cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final bytes = await ShareService.captureCard(boundary);
    return bytes != null ? Uint8List.fromList(bytes) : null;
  }

  Future<void> _onShare() async {
    setState(() => _generating = true);
    try {
      final bytes = await _capture();
      if (bytes == null) throw Exception('Capture failed');
      if (mounted) {
        await ShareService.shareCard(
          bytes,
          text: ShareService.buildTextSummary(_shareData),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Share failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<void> _onCopyText() async {
    await Clipboard.setData(
        ClipboardData(text: ShareService.buildTextSummary(_shareData)));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Copied to clipboard!'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Preview card width: leave 48px horizontal padding total
    final previewWidth = screenWidth - 48.0;
    final previewHeight = previewWidth * 16 / 9;

    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1628),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Share Workout',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ── Card preview ────────────────────────────────────────────────────
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    RepaintBoundary(
                      key: _cardKey,
                      child: SizedBox(
                        width: previewWidth,
                        height: previewHeight,
                        child: WorkoutCardWidget(
                          data: _shareData,
                          template: _template,
                          showExercises: _showExercises,
                          showQuote: _showQuote,
                        ),
                      ),
                    ).animate().fadeIn(duration: 400.ms).scale(
                        begin: const Offset(0.96, 0.96),
                        end: const Offset(1, 1)),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),

          // ── Controls panel ──────────────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF0F1C2E),
              border: Border(
                  top: BorderSide(color: Color(0xFF1E3050), width: 1)),
            ),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Photo attachment
                const Text(
                  'ADD A PROGRESS PHOTO?',
                  style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (_attachedPhotoBytes != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          width: 56,
                          height: 56,
                          child: Image.memory(
                            _attachedPhotoBytes!,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Photo attached — used as card background',
                          style: TextStyle(
                              color: Color(0xFF94A3B8), fontSize: 12),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded,
                            color: Color(0xFF94A3B8), size: 18),
                        onPressed: () => setState(() {
                          _attachedPhotoBytes = null;
                          _shareData = WorkoutShareData(
                            session: _shareData.session,
                            programName: _shareData.programName,
                            totalVolume: _shareData.totalVolume,
                            totalSets: _shareData.totalSets,
                            prExercises: _shareData.prExercises,
                          );
                        }),
                      ),
                    ] else ...[
                      _PhotoButton(
                        icon: Icons.camera_alt_rounded,
                        label: 'Camera',
                        onTap: () => _pickAttachPhoto(ImageSource.camera),
                      ),
                      const SizedBox(width: 10),
                      _PhotoButton(
                        icon: Icons.photo_library_rounded,
                        label: 'Gallery',
                        onTap: () => _pickAttachPhoto(ImageSource.gallery),
                      ),
                      const Spacer(),
                      const Text(
                        'Used as card background',
                        style: TextStyle(
                            color: Color(0xFF4A5568), fontSize: 11),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 14),

                // Template selector
                const Text(
                  'TEMPLATE',
                  style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5),
                ),
                const SizedBox(height: 10),
                Row(
                  children: CardTemplate.values.map((t) {
                    final active = _template == t;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                            right:
                                t == CardTemplate.values.last ? 0 : 8),
                        child: _TemplateChip(
                          template: t,
                          selected: active,
                          onTap: () => setState(() => _template = t),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),

                // Toggles
                Row(
                  children: [
                    _Toggle(
                      label: 'Exercises',
                      value: _showExercises,
                      onChanged: (v) => setState(() => _showExercises = v),
                    ),
                    const SizedBox(width: 8),
                    _Toggle(
                      label: 'Quote',
                      value: _showQuote,
                      onChanged: (v) => setState(() => _showQuote = v),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _generating ? null : _onCopyText,
                        icon: const Icon(Icons.content_copy_rounded, size: 16),
                        label: const Text('Copy Text'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF94A3B8),
                          side: const BorderSide(color: Color(0xFF334155)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: _generating ? null : _onShare,
                        icon: _generating
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white),
                              )
                            : const Icon(Icons.share_rounded, size: 18),
                        label: Text(_generating ? 'Generating…' : 'Share'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          textStyle: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: MediaQuery.of(context).padding.bottom + 14),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Photo button ──────────────────────────────────────────────────────────────

class _PhotoButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _PhotoButton(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1A2840),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2A3850)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.primary, size: 16),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ── Template chip ──────────────────────────────────────────────────────────────

class _TemplateChip extends StatelessWidget {
  final CardTemplate template;
  final bool selected;
  final VoidCallback onTap;
  const _TemplateChip(
      {required this.template, required this.selected, required this.onTap});

  IconData get _icon {
    switch (template) {
      case CardTemplate.minimal:
        return Icons.dashboard_rounded;
      case CardTemplate.detailed:
        return Icons.format_list_bulleted_rounded;
      case CardTemplate.achievement:
        return Icons.emoji_events_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withAlpha(25)
              : const Color(0xFF1A2840),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : const Color(0xFF2A3850),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(_icon,
                color: selected ? AppColors.primary : const Color(0xFF64748B),
                size: 18),
            const SizedBox(height: 4),
            Text(
              template.label,
              style: TextStyle(
                color:
                    selected ? AppColors.primary : const Color(0xFF64748B),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Toggle chip ────────────────────────────────────────────────────────────────

class _Toggle extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _Toggle(
      {required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: value
              ? AppColors.success.withAlpha(20)
              : const Color(0xFF1A2840),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: value ? AppColors.success : const Color(0xFF2A3850),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              value ? Icons.check_circle_rounded : Icons.circle_outlined,
              size: 14,
              color: value ? AppColors.success : const Color(0xFF64748B),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color:
                    value ? AppColors.success : const Color(0xFF64748B),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
