import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/services/update_service.dart';
import '../../core/utils/photo_utils.dart';
import '../../data/services/hive_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/user_profile_model.dart';
import '../../shared/providers/api_key_provider.dart';
import '../../shared/providers/theme_provider.dart';
import '../../shared/providers/user_profile_provider.dart';
import '../../shared/widgets/update_dialog.dart';
import '../nutrition/nutrition_provider.dart';
import '../../core/services/water_reminder_service.dart';
import 'progress_photos_screen.dart';
import 'weight_history_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  bool _useKg = true;
  bool _editing = false;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final profile = ref.read(userProfileProvider);
    _nameController = TextEditingController(text: profile.name);
    _ageController = TextEditingController(text: profile.age.toString());
    _heightController = TextEditingController(text: profile.height.toString());
    _weightController = TextEditingController(text: profile.weight.toString());
    _useKg = profile.useKg;
  }

  Future<void> _pickPhoto() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (picked != null) {
      // Copy to permanent app storage so the path survives cache clears
      final permanentPath = await copyToAppDocuments(picked.path);
      final profile = ref.read(userProfileProvider);
      await ref.read(userProfileProvider.notifier).update(
            profile.copyWith(photoPath: permanentPath),
          );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          TextButton(
            onPressed: _editing ? _saveProfile : () => setState(() => _editing = true),
            child: Text(
              _editing ? 'Save' : 'Edit',
              style: const TextStyle(color: primaryRed, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Column(
              children: [
                GestureDetector(
                  onTap: _pickPhoto,
                  child: Stack(
                    children: [
                      _buildAvatar(profile),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                            color: primaryRed,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (!_editing)
                  Text(profile.name, style: Theme.of(context).textTheme.headlineMedium),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _SectionHeader(title: 'Personal Info'),
          const SizedBox(height: 12),
          if (_editing) ...[
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ageController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(labelText: 'Age'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _heightController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Height (cm)'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _weightController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: 'Weight (${_useKg ? 'kg' : 'lbs'})'),
                  ),
                ),
              ],
            ),
          ] else ...[
            _InfoTile(label: 'Age', value: '${profile.age} years'),
            _InfoTile(label: 'Height', value: '${profile.height.toStringAsFixed(0)} cm'),
            _InfoTile(label: 'Weight', value: '${profile.weight.toStringAsFixed(1)} ${profile.useKg ? 'kg' : 'lbs'}'),
          ],
          const SizedBox(height: 24),
          _SectionHeader(title: 'Preferences'),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  const Expanded(child: Text('Weight Unit', style: TextStyle(fontWeight: FontWeight.w600))),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: true, label: Text('kg')),
                      ButtonSegment(value: false, label: Text('lbs')),
                    ],
                    selected: {_useKg},
                    onSelectionChanged: (v) => setState(() => _useKg = v.first),
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) return primaryRed;
                        return null;
                      }),
                      foregroundColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) return Colors.white;
                        return null;
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _SectionHeader(title: 'Appearance'),
          const SizedBox(height: 12),
          _ThemeToggle(),
          const SizedBox(height: 24),
          _SectionHeader(title: 'Tracking'),
          const SizedBox(height: 12),
          _WaterReminderToggle(),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: primaryRed.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.photo_library_rounded, color: primaryRed, size: 20),
              ),
              title: const Text('Progress Photos',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Track your transformation journey'),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF8899AA)),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ProgressPhotosScreen(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.activeDark.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.history_rounded, color: AppColors.activeDark, size: 20),
              ),
              title: const Text('Weight History',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('All your logged sets & weights'),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF8899AA)),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const WeightHistoryScreen(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _SectionHeader(title: 'API Settings'),
          const SizedBox(height: 12),
          const _ApiKeyCard(),
          const SizedBox(height: 24),
          _SectionHeader(title: 'App Updates'),
          const SizedBox(height: 12),
          const _UpdateCard(),
          const SizedBox(height: 24),
          _SectionHeader(title: 'About'),
          const SizedBox(height: 12),
          const _InfoTile(label: 'App', value: 'FitTrack'),
          const _InfoTile(label: 'Developer', value: 'Abdallah Saeed'),
        ],
      ),
    );
  }

  Widget _buildAvatar(UserProfileModel profile) {
    final hasPhoto = profile.photoPath != null && profile.photoPath!.isNotEmpty;
    final file = hasPhoto ? File(profile.photoPath!) : null;
    final fileExists = file != null && file.existsSync();

    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: fileExists ? null : primaryRed,
        image: fileExists
            ? DecorationImage(image: FileImage(file), fit: BoxFit.cover)
            : null,
      ),
      child: fileExists
          ? null
          : Center(
              child: Text(
                profile.name.isNotEmpty ? profile.name[0].toUpperCase() : 'A',
                style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800),
              ),
            ),
    );
  }

  Future<void> _saveProfile() async {
    HapticFeedback.selectionClick();
    final current = ref.read(userProfileProvider);
    final updated = UserProfileModel(
      name: _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : 'User',
      age: int.tryParse(_ageController.text) ?? 25,
      height: double.tryParse(_heightController.text) ?? 175,
      weight: double.tryParse(_weightController.text) ?? 75,
      useKg: _useKg,
      isFirstLaunch: false,
      photoPath: current.photoPath,
    );
    await ref.read(userProfileProvider.notifier).update(updated);
    setState(() => _editing = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved'), backgroundColor: tealSuccess),
      );
    }
  }
}

class _ThemeToggle extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            const Expanded(child: Text('Theme', style: TextStyle(fontWeight: FontWeight.w600))),
            SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(value: ThemeMode.light, label: Text('Light'), icon: Icon(Icons.light_mode_rounded, size: 14)),
                ButtonSegment(value: ThemeMode.system, label: Text('Auto'), icon: Icon(Icons.brightness_auto_rounded, size: 14)),
                ButtonSegment(value: ThemeMode.dark, label: Text('Dark'), icon: Icon(Icons.dark_mode_rounded, size: 14)),
              ],
              selected: {mode},
              onSelectionChanged: (v) => ref.read(themeModeProvider.notifier).setMode(v.first),
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) return primaryRed;
                  return null;
                }),
                foregroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) return Colors.white;
                  return null;
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Color(0xFF8899AA),
        letterSpacing: 1.2,
      ),
    );
  }
}

class _ApiKeyCard extends ConsumerStatefulWidget {
  const _ApiKeyCard();

  @override
  ConsumerState<_ApiKeyCard> createState() => _ApiKeyCardState();
}

class _ApiKeyCardState extends ConsumerState<_ApiKeyCard> {
  late TextEditingController _controller;
  bool _editing = false;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: ref.read(apiKeyProvider));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    await ref.read(apiKeyProvider.notifier).save(_controller.text);
    setState(() => _editing = false);
    messenger.showSnackBar(
      const SnackBar(content: Text('API key saved'), backgroundColor: tealSuccess),
    );
  }

  void _cancel() {
    _controller.text = ref.read(apiKeyProvider);
    setState(() => _editing = false);
  }

  @override
  Widget build(BuildContext context) {
    final hasKey = ref.watch(apiKeyProvider).isNotEmpty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.api_rounded, size: 18, color: steelBlue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'WorkoutX API Key',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                if (hasKey && !_editing)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: tealSuccess.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: tealSuccess.withAlpha(60)),
                    ),
                    child: const Text('Active',
                        style: TextStyle(
                            color: tealSuccess,
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  ),
                const SizedBox(width: 8),
                if (!_editing)
                  TextButton(
                    onPressed: () => setState(() => _editing = true),
                    child: const Text('Edit',
                        style: TextStyle(color: primaryRed, fontWeight: FontWeight.w700)),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Optional — enables animated GIFs for exercises. Get a free key at dashboard.workoutxapp.com',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _controller,
              readOnly: !_editing,
              obscureText: !_visible,
              decoration: InputDecoration(
                hintText: 'wx_your_api_key_here',
                filled: !_editing,
                fillColor: _editing ? null : Theme.of(context).dividerColor.withAlpha(15),
                suffixIcon: IconButton(
                  icon: Icon(
                    _visible
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _visible = !_visible),
                ),
              ),
            ),
            if (_editing) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(backgroundColor: steelBlue),
                      child: const Text('Save'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton(
                    onPressed: _cancel,
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Update card ───────────────────────────────────────────────────────────────

class _UpdateCard extends StatefulWidget {
  const _UpdateCard();

  @override
  State<_UpdateCard> createState() => _UpdateCardState();
}

class _UpdateCardState extends State<_UpdateCard> {
  String _versionLabel = 'Loading...';
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    UpdateService.currentVersionLabel().then((v) {
      if (mounted) setState(() => _versionLabel = v);
    });
  }

  Future<void> _checkNow() async {
    setState(() => _checking = true);
    final release = await UpdateService().checkForUpdates();
    if (!mounted) return;
    setState(() => _checking = false);

    if (release != null) {
      showDialog<void>(
        context: context,
        builder: (_) => UpdateDialog(release: release),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You have the latest version!'),
          backgroundColor: AppColors.growthGreen,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.activeDark.withAlpha(20),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.system_update_rounded,
              color: AppColors.activeDark, size: 20),
        ),
        title: const Text('Check for Updates',
            style: TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(_versionLabel),
        trailing: _checking
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.activeDark),
              )
            : const Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: Color(0xFF8899AA)),
        onTap: _checking ? null : _checkNow,
      ),
    );
  }
}

// ── Info tile ─────────────────────────────────────────────────────────────────

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  const _InfoTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
            Text(value, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}

class _WaterReminderToggle extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(waterReminderEnabledProvider);
    return Card(
      child: SwitchListTile(
        secondary: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.activeDark.withAlpha(25),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.water_drop_rounded, color: AppColors.activeDark, size: 20),
        ),
        title: const Text('Water Reminders', style: TextStyle(fontWeight: FontWeight.w600)),
        subtitle: const Text('Get reminded every 10 minutes'),
        value: enabled,
        onChanged: (v) {
          ref.read(waterReminderEnabledProvider.notifier).state = v;
          HiveService.settings.put('waterReminderEnabled', v);
          WaterReminderService().toggleReminders(v);
        },
        activeTrackColor: AppColors.activeDark,
        activeThumbColor: Colors.white,
      ),
    );
  }
}
