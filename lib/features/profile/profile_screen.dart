import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/services/update_service.dart';
import '../../core/utils/image_bytes_saver.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/screens/crop_image_screen.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/user_profile_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show FileOptions;
import '../../core/services/supabase_service.dart';
import '../../shared/providers/theme_provider.dart';
import '../../shared/providers/user_profile_provider.dart';
import '../../shared/widgets/update_dialog.dart';
import '../nutrition/nutrition_provider.dart';
import '../../core/services/water_reminder_service.dart';
import 'progress_photos_screen.dart';
import 'weight_history_screen.dart';
import '../achievements/achievements_provider.dart';
import '../achievements/achievements_screen.dart';

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
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 90,
    );
    if (picked == null || !mounted) return;

    // Read bytes immediately so crop screen has them ready.
    final rawBytes = await picked.readAsBytes();
    if (!mounted) return;

    // Open full-screen crop UI — 1:1 square with circle overlay for the avatar.
    final croppedBytes = await Navigator.push<Uint8List>(
      context,
      MaterialPageRoute(
        builder: (_) => CropImageScreen(
          file: picked,
          preloadedBytes: rawBytes,
          aspectRatio: 1.0,
          withCircleUi: true,
        ),
      ),
    );
    if (croppedBytes == null || !mounted) return;

    // Show uploading indicator
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(children: [
            SizedBox(width: 16, height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
            SizedBox(width: 12),
            Text('Uploading photo…'),
          ]),
          duration: Duration(seconds: 10),
        ),
      );
    }

    String photoPath;
    String? uploadError;
    try {
      // Upload to Supabase Storage — gives us a persistent public URL.
      photoPath = await _uploadAvatarToStorage(croppedBytes);
    } catch (e) {
      uploadError = e.toString();
      debugPrint('[ProfileScreen] Storage upload failed: $e');
      // Fall back: save locally and use a file path.
      photoPath = await saveCroppedBytes(croppedBytes);
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    if (uploadError != null) {
      // Show the actual error so we can diagnose it.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload failed: $uploadError'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 8),
        ),
      );
      return;
    }

    String? dbError;
    try {
      final profile = ref.read(userProfileProvider);
      await ref.read(userProfileProvider.notifier).update(
            profile.copyWith(photoPath: photoPath),
          );
    } catch (e) {
      dbError = e.toString();
      debugPrint('[ProfileScreen] DB save failed: $e');
    }

    // Evict image cache so the updated avatar shows everywhere immediately.
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();

    if (!mounted) return;
    if (dbError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('DB save failed: $dbError'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 8),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile photo updated!')),
      );
    }
  }

  /// Uploads [bytes] to Supabase Storage under `avatars/<userId>.jpg`,
  /// then writes the public URL directly into `profiles.avatar_url`.
  /// Returns the public URL (with cache-buster).
  Future<String> _uploadAvatarToStorage(Uint8List bytes) async {
    final userId = SupabaseService.userId;
    const bucket = 'avatars';
    final storagePath = '$userId.jpg';

    // 1. Upload file (upsert = replace if exists).
    await SupabaseService.client.storage.from(bucket).uploadBinary(
      storagePath,
      bytes,
      fileOptions: FileOptions(
        contentType: 'image/jpeg',
        upsert: true,
      ),
    );

    // 2. Build public URL with cache-buster.
    final publicUrl =
        SupabaseService.client.storage.from(bucket).getPublicUrl(storagePath);
    final cacheBust = DateTime.now().millisecondsSinceEpoch;
    final urlWithBust = '$publicUrl?v=$cacheBust';

    // 3. Persist the URL directly into the profiles table — explicit, no
    //    silent swallowing.  This throws on failure so the caller sees the error.
    await SupabaseService.client
        .from('profiles')
        .update({'avatar_url': urlWithBust})
        .eq('id', userId);

    return urlWithBust;
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
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Log out',
            onPressed: () => _confirmLogout(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(userProfileProvider),
        color: AppColors.primary,
        child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
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
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Name',
                helperText: 'This is also your login username',
                helperStyle: TextStyle(fontSize: 11),
                prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
              ),
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
          _SectionHeader(title: 'Achievements'),
          const SizedBox(height: 12),
          _AchievementsCard(),
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
      ),
    );
  }

  Widget _buildAvatar(UserProfileModel profile) {
    final hasPhoto = profile.photoPath != null && profile.photoPath!.isNotEmpty;

    ImageProvider? imageProvider;
    if (hasPhoto) {
      final p = profile.photoPath!;
      if (p.startsWith('http') || p.startsWith('blob:') || p.startsWith('data:')) {
        // Remote URL (Supabase Storage) or web data URL
        imageProvider = NetworkImage(p);
      } else if (p.startsWith('file://')) {
        imageProvider = NetworkImage(p);
      } else {
        // Native absolute path fallback (pre-upload era)
        imageProvider = FileImage(File(p));
      }
    }

    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: imageProvider == null ? primaryRed : null,
        image: imageProvider != null
            ? DecorationImage(image: imageProvider, fit: BoxFit.cover)
            : null,
      ),
      child: imageProvider == null
          ? Center(
              child: Text(
                profile.name.isNotEmpty ? profile.name[0].toUpperCase() : 'A',
                style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800),
              ),
            )
          : null,
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Out?'),
        content: const Text('You will be returned to the login screen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log Out',
                style: TextStyle(color: primaryRed)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await SupabaseService.client.auth.signOut();
    }
  }

  Future<void> _saveProfile() async {
    HapticFeedback.selectionClick();
    final current = ref.read(userProfileProvider);
    final newName = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()
        : 'User';

    final updated = UserProfileModel(
      name: newName,
      age: int.tryParse(_ageController.text) ?? 25,
      height: double.tryParse(_heightController.text) ?? 175,
      weight: double.tryParse(_weightController.text) ?? 75,
      useKg: _useKg,
      isFirstLaunch: false,
      photoPath: current.photoPath,
    );
    await ref.read(userProfileProvider.notifier).update(updated);

    // Keep login_email in sync so the user can always log in with their
    // current display name.  Requires the SQL migration:
    //   ALTER TABLE profiles ADD COLUMN IF NOT EXISTS login_email TEXT;
    final authEmail = SupabaseService.currentUser?.email;
    if (authEmail != null) {
      try {
        await SupabaseService.client
            .from('profiles')
            .update({'login_email': authEmail, 'name': newName})
            .eq('id', SupabaseService.userId);
      } catch (_) {}
    }

    setState(() => _editing = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Profile saved'), backgroundColor: tealSuccess),
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
    try {
      final release =
          await UpdateService().checkForUpdates(throwOnError: true);
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
            content: Text('You\'re on the latest version!'),
            backgroundColor: AppColors.growthGreen,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _checking = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Update check failed: $e'),
          backgroundColor: AppColors.error,
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

class _AchievementsCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(achievementsProvider);
    final unlocked = all.where((a) => a.isUnlocked).length;
    return Card(
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.success.withAlpha(25),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.emoji_events_rounded,
              color: AppColors.success, size: 20),
        ),
        title: const Text('Achievements',
            style: TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('$unlocked / ${all.length} unlocked'),
        trailing: const Icon(Icons.arrow_forward_ios_rounded,
            size: 14, color: Color(0xFF8899AA)),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const AchievementsScreen(),
          ),
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
          WaterReminderService().toggleReminders(v);
        },
        activeTrackColor: AppColors.activeDark,
        activeThumbColor: Colors.white,
      ),
    );
  }
}
