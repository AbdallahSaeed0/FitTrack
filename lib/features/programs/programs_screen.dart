import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/program_model.dart';
import 'programs_provider.dart';

class ProgramsScreen extends ConsumerStatefulWidget {
  const ProgramsScreen({super.key});

  @override
  ConsumerState<ProgramsScreen> createState() => _ProgramsScreenState();
}

class _ProgramsScreenState extends ConsumerState<ProgramsScreen> {
  bool _importing = false;

  Future<void> _importProgram() async {
    setState(() => _importing = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      final bytes = result.files.first.bytes;
      final path = result.files.first.path;
      final raw = bytes != null
          ? utf8.decode(bytes)
          : await File(path!).readAsString();

      final json = jsonDecode(raw) as Map<String, dynamic>;
      final program = ProgramModel.fromJson(json).copyWith(
        id: const Uuid().v4(),
        isActive: false,
      );
      await ref.read(programsProvider.notifier).addProgram(program);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Imported "${program.name}"'),
            backgroundColor: AppColors.growthGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed — make sure it is a valid FitTrack JSON file'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final programs = ref.watch(programsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Programs'),
        actions: [
          IconButton(
            icon: _importing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.activeDark),
                  )
                : const Icon(Icons.file_download_outlined, color: AppColors.activeDark),
            tooltip: 'Import Program',
            onPressed: _importing ? null : _importProgram,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              onPressed: () => context.push('/programs/create'),
              icon: const Icon(Icons.add_rounded, color: AppColors.activeDark, size: 18),
              label: const Text(
                'New',
                style: TextStyle(color: AppColors.activeDark, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
      body: programs.isEmpty
          ? _EmptyState(onTap: () => context.push('/programs/create'))
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: programs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _ProgramCard(program: programs[index]);
              },
            ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onTap;
  const _EmptyState({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.activeDark.withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.fitness_center_rounded, color: AppColors.activeDark, size: 36),
          ),
          const SizedBox(height: 16),
          Text(
            'No programs yet',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first workout program',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(minimumSize: const Size(200, 48)),
            child: const Text('Create Program'),
          ),
        ],
      ),
    );
  }
}

class _ProgramCard extends ConsumerWidget {
  final ProgramModel program;

  const _ProgramCard({required this.program});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isActive = program.isActive;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? AppColors.activeDark : AppColors.borderDark,
          width: isActive ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/programs/${program.id}'),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.mediumGray.withAlpha(40),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.fitness_center_rounded,
                    color: isActive ? AppColors.activeDark : AppColors.inactiveDark,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        program.name,
                        style: Theme.of(context).textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${program.trainingDaysCount} training days · ${program.splitType.replaceAll('_', ' ').toUpperCase()}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (isActive)
                  _ActiveBadgeWithMenu(program: program)
                else
                  _ProgramPopupMenu(program: program),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActiveBadgeWithMenu extends ConsumerWidget {
  final ProgramModel program;
  const _ActiveBadgeWithMenu({required this.program});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.activeDark,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'Active',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
          ),
        ),
        const SizedBox(width: 4),
        _buildPopup(context, ref, showActivate: false),
      ],
    );
  }

  Widget _buildPopup(BuildContext context, WidgetRef ref, {required bool showActivate}) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert_rounded, color: AppColors.white.withAlpha(160), size: 20),
      color: const Color(0xFF1A2236),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (v) => _onSelected(context, ref, v),
      itemBuilder: (_) => [
        _menuItem('edit', Icons.edit_rounded, 'Edit', AppColors.accentTeal),
        _menuItem('delete', Icons.delete_rounded, 'Delete', AppColors.error),
      ],
    );
  }

  void _onSelected(BuildContext context, WidgetRef ref, String value) async {
    if (value == 'edit') {
      context.push('/programs/${program.id}');
    } else if (value == 'delete') {
      final ok = await _confirmDelete(context);
      if (ok == true) ref.read(programsProvider.notifier).deleteProgram(program.id);
    }
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Delete Program?'),
        content: Text('Delete "${program.name}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(d, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _ProgramPopupMenu extends ConsumerWidget {
  final ProgramModel program;
  const _ProgramPopupMenu({required this.program});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert_rounded, color: AppColors.white.withAlpha(160)),
      color: const Color(0xFF1A2236),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (v) => _onSelected(context, ref, v),
      itemBuilder: (_) => [
        _menuItem('activate', Icons.check_circle_rounded, 'Set as Active', AppColors.growthGreen),
        _menuItem('edit', Icons.edit_rounded, 'Edit', AppColors.accentTeal),
        _menuItem('delete', Icons.delete_rounded, 'Delete', AppColors.error),
      ],
    );
  }

  void _onSelected(BuildContext context, WidgetRef ref, String value) async {
    switch (value) {
      case 'activate':
        ref.read(programsProvider.notifier).setActive(program.id);
      case 'edit':
        context.push('/programs/${program.id}');
      case 'delete':
        final ok = await showDialog<bool>(
          context: context,
          builder: (d) => AlertDialog(
            title: const Text('Delete Program?'),
            content: Text('Delete "${program.name}"? This cannot be undone.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancel')),
              TextButton(
                onPressed: () => Navigator.pop(d, true),
                child: const Text('Delete', style: TextStyle(color: AppColors.error)),
              ),
            ],
          ),
        );
        if (ok == true) ref.read(programsProvider.notifier).deleteProgram(program.id);
    }
  }
}

PopupMenuItem<String> _menuItem(String value, IconData icon, String label, Color color) {
  return PopupMenuItem<String>(
    value: value,
    child: Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(color: color)),
      ],
    ),
  );
}
