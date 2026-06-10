import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/photo_utils.dart';
import '../../shared/providers/user_profile_provider.dart';

// ─── Page indices ─────────────────────────────────────────────────────────────

const _kWelcome3 = 2;
const _kPersonalInfo = 3;
const _kPhoto = 4;
const _kTotal = 6;

// ─── Main flow controller ─────────────────────────────────────────────────────

class OnboardingFlow extends ConsumerStatefulWidget {
  const OnboardingFlow({super.key});

  @override
  ConsumerState<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends ConsumerState<OnboardingFlow> {
  final _pageController = PageController();
  int _currentPage = 0;

  // Collected data
  final _nameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  bool _useKg = true;
  String? _photoPath;
  String? _selectedGoal;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(userProfileProvider);
    _nameCtrl.text = profile.name == 'Abdallah' ? '' : profile.name;
    _ageCtrl.text = profile.age == 25 ? '' : profile.age.toString();
    _heightCtrl.text = profile.height == 175 ? '' : profile.height.toString();
    _weightCtrl.text = profile.weight == 75 ? '' : profile.weight.toString();
    _useKg = profile.useKg;
    _photoPath = profile.photoPath;
    _selectedGoal = profile.fitnessGoal;
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  void _goTo(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  void _next() {
    if (_currentPage < _kTotal - 1) _goTo(_currentPage + 1);
  }

  void _back() {
    if (_currentPage > 0) _goTo(_currentPage - 1);
  }

  Future<void> _finish() async {
    if (_selectedGoal == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your fitness goal to continue.')),
      );
      return;
    }

    setState(() => _saving = true);

    final name = _nameCtrl.text.trim().isNotEmpty ? _nameCtrl.text.trim() : 'User';
    final age = int.tryParse(_ageCtrl.text) ?? 20;
    final height = double.tryParse(_heightCtrl.text) ?? 175;
    final weight = double.tryParse(_weightCtrl.text) ?? 70;

    final current = ref.read(userProfileProvider);
    final updated = current.copyWith(
      name: name,
      age: age,
      height: height,
      weight: weight,
      useKg: _useKg,
      photoPath: _photoPath,
      fitnessGoal: _selectedGoal,
      isFirstLaunch: false,
    );
    await ref.read(userProfileProvider.notifier).update(updated);

    if (mounted) setState(() => _saving = false);
    // State change causes FitTrackApp to rebuild → routes to main app automatically
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // ── Progress indicator (only on non-welcome pages) ──
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 300),
              crossFadeState: _currentPage >= _kPersonalInfo
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: const SizedBox(height: 12),
              secondChild: _StepIndicator(
                current: _currentPage - _kPersonalInfo,
                total: _kTotal - _kPersonalInfo,
              ),
            ),

            // ── Pages ──
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  _WelcomePage(
                    icon: Icons.fitness_center_rounded,
                    color: primaryRed,
                    title: 'Track Your Workouts',
                    subtitle:
                        'Log every set, rep and weight. FitTrack keeps your entire workout history in one place.',
                  ),
                  _WelcomePage(
                    icon: Icons.bar_chart_rounded,
                    color: steelBlue,
                    title: 'Monitor Your Progress',
                    subtitle:
                        'See your strength gains over time with charts, streaks and personal bests.',
                  ),
                  _WelcomePage(
                    icon: Icons.calendar_month_rounded,
                    color: tealSuccess,
                    title: 'Stay Consistent',
                    subtitle:
                        'Follow structured programs and build the habit that transforms your physique.',
                  ),
                  _PersonalInfoPage(
                    nameCtrl: _nameCtrl,
                    ageCtrl: _ageCtrl,
                    heightCtrl: _heightCtrl,
                    weightCtrl: _weightCtrl,
                    useKg: _useKg,
                    onUseKgChanged: (v) => setState(() => _useKg = v),
                  ),
                  _PhotoPage(
                    photoPath: _photoPath,
                    onPhotoChanged: (p) => setState(() => _photoPath = p),
                  ),
                  _GoalsPage(
                    selected: _selectedGoal,
                    onSelected: (g) => setState(() => _selectedGoal = g),
                  ),
                ],
              ),
            ),

            // ── Welcome page indicator dots ──
            if (_currentPage < _kPersonalInfo) ...[
              const SizedBox(height: 12),
              SmoothPageIndicator(
                controller: _pageController,
                count: 3,
                effect: ExpandingDotsEffect(
                  activeDotColor: primaryRed,
                  dotColor:
                      Theme.of(context).dividerColor.withAlpha(80),
                  dotHeight: 8,
                  dotWidth: 8,
                  expansionFactor: 3,
                ),
              ),
            ],
            const SizedBox(height: 16),

            // ── Navigation buttons ──
            _NavBar(
              currentPage: _currentPage,
              saving: _saving,
              onBack: _back,
              onNext: _next,
              onSkip: _next,
              onFinish: _finish,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ─── Step indicator (personal info → goals) ───────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final int current;
  final int total;
  const _StepIndicator({required this.current, required this.total});

  static const _labels = [
    'Your Info',
    'Photo',
    'API Key',
    'Goals',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: List.generate(total, (i) {
          final done = i < current;
          final active = i == current;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 3,
                        decoration: BoxDecoration(
                          color: done || active
                              ? primaryRed
                              : Theme.of(context).dividerColor.withAlpha(80),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        i < _labels.length ? _labels[i] : '',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: active
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: active
                              ? primaryRed
                              : Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.color,
                        ),
                      ),
                    ],
                  ),
                ),
                if (i < total - 1) const SizedBox(width: 4),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ─── Nav bar ──────────────────────────────────────────────────────────────────

class _NavBar extends StatelessWidget {
  final int currentPage;
  final bool saving;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final VoidCallback onFinish;

  const _NavBar({
    required this.currentPage,
    required this.saving,
    required this.onBack,
    required this.onNext,
    required this.onSkip,
    required this.onFinish,
  });

  bool get _isWelcome => currentPage < _kPersonalInfo;
  bool get _isLast => currentPage == _kTotal - 1;
  bool get _canSkip =>
      currentPage == _kPhoto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // Back button (hidden on first page)
          if (currentPage > 0)
            OutlinedButton(
              onPressed: onBack,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(80, 48),
                side: BorderSide(
                    color: Theme.of(context).dividerColor.withAlpha(120)),
              ),
              child: const Text('Back'),
            )
          else
            const SizedBox(width: 80),

          const Spacer(),

          // Skip (optional steps)
          if (_canSkip && !_isLast) ...[
            TextButton(
              onPressed: onSkip,
              child: const Text('Skip',
                  style: TextStyle(color: Color(0xFF8899AA))),
            ),
            const SizedBox(width: 8),
          ],

          // Main action button
          if (_isLast)
            ElevatedButton(
              onPressed: saving ? null : onFinish,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(150, 48),
                backgroundColor: primaryRed,
              ),
              child: saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Complete Setup',
                      style: TextStyle(fontWeight: FontWeight.w700)),
            )
          else
            ElevatedButton(
              onPressed: onNext,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(120, 48),
              ),
              child: Text(
                _isWelcome && currentPage == _kWelcome3
                    ? 'Get Started'
                    : 'Continue',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── PAGE 0–2: Welcome slides ─────────────────────────────────────────────────

class _WelcomePage extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _WelcomePage({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 56, color: color),
          ),
          const SizedBox(height: 40),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
          ),
          const SizedBox(height: 16),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }
}

// ─── PAGE 3: Personal info ────────────────────────────────────────────────────

class _PersonalInfoPage extends StatelessWidget {
  final TextEditingController nameCtrl;
  final TextEditingController ageCtrl;
  final TextEditingController heightCtrl;
  final TextEditingController weightCtrl;
  final bool useKg;
  final ValueChanged<bool> onUseKgChanged;

  const _PersonalInfoPage({
    required this.nameCtrl,
    required this.ageCtrl,
    required this.heightCtrl,
    required this.weightCtrl,
    required this.useKg,
    required this.onUseKgChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tell us about yourself',
              style: Theme.of(context)
                  .textTheme
                  .headlineLarge
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(
            'This helps personalise your experience.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color),
          ),
          const SizedBox(height: 28),

          TextField(
            controller: nameCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Your name',
              prefixIcon: Icon(Icons.person_rounded),
            ),
          ),
          const SizedBox(height: 14),

          TextField(
            controller: ageCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Age',
              prefixIcon: Icon(Icons.cake_rounded),
              suffixText: 'years',
            ),
          ),
          const SizedBox(height: 14),

          TextField(
            controller: heightCtrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
            ],
            decoration: const InputDecoration(
              labelText: 'Height',
              prefixIcon: Icon(Icons.height_rounded),
              suffixText: 'cm',
            ),
          ),
          const SizedBox(height: 14),

          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: weightCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                  ],
                  decoration: InputDecoration(
                    labelText: 'Weight',
                    prefixIcon: const Icon(Icons.monitor_weight_rounded),
                    suffixText: useKg ? 'kg' : 'lbs',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, label: Text('kg')),
                  ButtonSegment(value: false, label: Text('lbs')),
                ],
                selected: {useKg},
                onSelectionChanged: (v) => onUseKgChanged(v.first),
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith((s) {
                    if (s.contains(WidgetState.selected)) return primaryRed;
                    return null;
                  }),
                  foregroundColor: WidgetStateProperty.resolveWith((s) {
                    if (s.contains(WidgetState.selected)) return Colors.white;
                    return null;
                  }),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── PAGE 4: Photo upload ─────────────────────────────────────────────────────

class _PhotoPage extends StatefulWidget {
  final String? photoPath;
  final ValueChanged<String?> onPhotoChanged;

  const _PhotoPage({required this.photoPath, required this.onPhotoChanged});

  @override
  State<_PhotoPage> createState() => _PhotoPageState();
}

class _PhotoPageState extends State<_PhotoPage> {
  final _picker = ImagePicker();
  String? _localPath;

  @override
  void initState() {
    super.initState();
    _localPath = widget.photoPath;
  }

  Future<void> _pick(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (picked != null) {
      // Copy to permanent app storage immediately
      final permanentPath = await copyToAppDocuments(picked.path);
      setState(() => _localPath = permanentPath);
      widget.onPhotoChanged(permanentPath);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto =
        _localPath != null && File(_localPath!).existsSync();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Add a profile photo',
              style: Theme.of(context)
                  .textTheme
                  .headlineLarge
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(
            'Optional — you can always add one later.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color),
          ),
          const SizedBox(height: 36),

          GestureDetector(
            onTap: () => _pick(ImageSource.gallery),
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: hasPhoto
                    ? null
                    : Theme.of(context).cardTheme.color,
                border: Border.all(
                  color: primaryRed.withAlpha(60),
                  width: 2.5,
                ),
                image: hasPhoto
                    ? DecorationImage(
                        image: FileImage(File(_localPath!)),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: hasPhoto
                  ? null
                  : const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo_rounded,
                            size: 36, color: primaryRed),
                        SizedBox(height: 6),
                        Text('Tap to add',
                            style: TextStyle(
                                color: primaryRed,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
            ),
          ),

          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: () => _pick(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_rounded, size: 18),
                label: const Text('Gallery'),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () => _pick(ImageSource.camera),
                icon: const Icon(Icons.camera_alt_rounded, size: 18),
                label: const Text('Camera'),
              ),
            ],
          ),

          if (hasPhoto) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                setState(() => _localPath = null);
                widget.onPhotoChanged(null);
              },
              child: const Text('Remove photo',
                  style: TextStyle(color: Color(0xFF8899AA))),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── PAGE 5: Fitness goals ────────────────────────────────────────────────────

class _GoalsPage extends StatelessWidget {
  final String? selected;
  final ValueChanged<String> onSelected;

  const _GoalsPage({required this.selected, required this.onSelected});

  static const _goals = [
    (
      id: 'muscle',
      icon: Icons.fitness_center_rounded,
      title: 'Build Muscle',
      subtitle: 'Gain strength and size through progressive overload',
      color: primaryRed,
    ),
    (
      id: 'fat_loss',
      icon: Icons.local_fire_department_rounded,
      title: 'Lose Fat',
      subtitle: 'Burn calories, improve body composition and endurance',
      color: Color(0xFFFF8C00),
    ),
    (
      id: 'recomp',
      icon: Icons.swap_horiz_rounded,
      title: 'Build & Lose',
      subtitle: 'Recomposition — build muscle while shedding fat',
      color: steelBlue,
    ),
    (
      id: 'maintenance',
      icon: Icons.self_improvement_rounded,
      title: 'Stay Fit',
      subtitle: 'Maintain current fitness and stay healthy long-term',
      color: tealSuccess,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your fitness goal',
              style: Theme.of(context)
                  .textTheme
                  .headlineLarge
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(
            'Choose what you want to achieve. You can change this anytime.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color),
          ),
          const SizedBox(height: 20),
          ..._goals.map((g) => _GoalCard(
                id: g.id,
                icon: g.icon,
                title: g.title,
                subtitle: g.subtitle,
                color: g.color,
                isSelected: selected == g.id,
                onTap: () => onSelected(g.id),
              )),
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final String id;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _GoalCard({
    required this.id,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withAlpha(18) : Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color : Theme.of(context).dividerColor.withAlpha(60),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withAlpha(isSelected ? 40 : 20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isSelected ? color : null)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            const SizedBox(width: 8),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: isSelected ? 1 : 0,
              child: Icon(Icons.check_circle_rounded, color: color, size: 22),
            ),
          ],
        ),
      ),
    );
  }
}
