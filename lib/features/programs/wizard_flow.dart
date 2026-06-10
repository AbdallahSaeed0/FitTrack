import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/exercise_model.dart';
import '../../data/models/program_model.dart';
import '../../data/models/workout_day_model.dart';
import '../../shared/widgets/exercise_gif_widget.dart';
import '../exercises/create_custom_exercise_sheet.dart';
import 'programs_provider.dart';
import 'wizard_provider.dart';
import '../templates/template_data.dart';
import '../templates/template_models.dart';
import '../templates/templates_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Main wizard scaffold
// ─────────────────────────────────────────────────────────────────────────────

class WizardFlow extends ConsumerWidget {
  const WizardFlow({super.key});

  static const _titles = [
    'Program Details',
    'Workout Days',
    'Add Exercises',
    'Sets & Reps',
    'Volume Analysis',
    'Review & Save',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final step = ref.watch(wizardProvider.select((s) => s.step));
    final canNext = ref.watch(wizardProvider.select((s) => s.canNext));
    final notifier = ref.read(wizardProvider.notifier);

    void goBack() {
      if (step > 0) {
        notifier.prevStep();
      } else {
        notifier.reset();
        context.pop();
      }
    }

    return PopScope(
      canPop: step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) goBack();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_titles[step]),
          leading: IconButton(
            icon: Icon(
                step == 0 ? Icons.close_rounded : Icons.arrow_back_rounded),
            onPressed: goBack,
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '${step + 1} / 6',
                  style: TextStyle(
                    color: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.color
                        ?.withAlpha(180),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            _StepIndicator(step: step),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(
                            begin: const Offset(0.04, 0), end: Offset.zero)
                        .animate(
                            CurvedAnimation(parent: anim, curve: Curves.easeOut)),
                    child: child,
                  ),
                ),
                child: _buildStep(step),
              ),
            ),
            if (step < 5)
              _NavBar(
                canNext: canNext,
                onBack: step > 0 ? notifier.prevStep : null,
                onNext: canNext ? notifier.nextStep : null,
              ),
          ],
        ),
      ),
    );
  }

  static Widget _buildStep(int step) {
    switch (step) {
      case 0:
        return const _Step0Details(key: ValueKey(0));
      case 1:
        return const _Step1Days(key: ValueKey(1));
      case 2:
        return const _Step2Exercises(key: ValueKey(2));
      case 3:
        return const _Step3Config(key: ValueKey(3));
      case 4:
        return const _Step4Analysis(key: ValueKey(4));
      case 5:
        return const _Step5Review(key: ValueKey(5));
      default:
        return const SizedBox.shrink();
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared chrome widgets
// ─────────────────────────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final int step;
  const _StepIndicator({required this.step});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Row(
        children: List.generate(6, (i) {
          final active = i == step;
          final done = i < step;
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: i < 5 ? 4 : 0),
              height: 4,
              decoration: BoxDecoration(
                color: done
                    ? primaryRed
                    : active
                        ? primaryRed.withAlpha(180)
                        : borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _NavBar extends StatelessWidget {
  final bool canNext;
  final VoidCallback? onBack;
  final VoidCallback? onNext;

  const _NavBar({required this.canNext, this.onBack, this.onNext});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, MediaQuery.of(context).viewPadding.bottom + 12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: borderLight)),
      ),
      child: Row(
        children: [
          if (onBack != null)
            OutlinedButton(
              onPressed: onBack,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF64748B),
                side: BorderSide(color: borderLight),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Back'),
            ),
          if (onBack != null) const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              onPressed: onNext,
              style: FilledButton.styleFrom(
                backgroundColor:
                    canNext ? primaryRed : primaryRed.withAlpha(80),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Next →',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 0 — Program Details
// ─────────────────────────────────────────────────────────────────────────────

class _Step0Details extends ConsumerStatefulWidget {
  const _Step0Details({super.key});

  @override
  ConsumerState<_Step0Details> createState() => _Step0DetailsState();
}

class _Step0DetailsState extends ConsumerState<_Step0Details> {
  late final TextEditingController _nameCtrl;
  late final PageController _tplPageCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl =
        TextEditingController(text: ref.read(wizardProvider).programName);
    _nameCtrl.addListener(
        () => ref.read(wizardProvider.notifier).setName(_nameCtrl.text));
    _tplPageCtrl = PageController(viewportFraction: 0.88);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _tplPageCtrl.dispose();
    super.dispose();
  }

  void _applyTemplate(String name, String split, String level) {
    _nameCtrl.text = name;
    ref.read(wizardProvider.notifier)
      ..setName(name)
      ..setSplit(split)
      ..setLevel(level);
  }

  Future<void> _useTemplate(
      BuildContext context, ProgramTemplate template) async {
    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final program = buildProgramFromTemplate(template);
      await ref.read(programsProvider.notifier).addProgram(program);
      ref.read(wizardProvider.notifier).reset();
      if (mounted) {
        router.pop(); // dismiss wizard
        router.push('/programs/${program.id}');
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final splitType = ref.watch(wizardProvider.select((s) => s.splitType));

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        // ── Template library ──────────────────────────────────────────────────
        Row(
          children: [
            const _SectionLabel('START FROM TEMPLATE'),
            const Spacer(),
            GestureDetector(
              onTap: () => context.push('/programs/templates'),
              child: const Text(
                'Browse all →',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: steelBlue,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 168,
          child: PageView.builder(
            controller: _tplPageCtrl,
            physics: const BouncingScrollPhysics(),
            itemCount: kProgramTemplates.length,
            itemBuilder: (_, i) {
              final t = kProgramTemplates[i];
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: _ProgramTemplateCard(
                  template: t,
                  onTap: () => showTemplatePreview(
                    context: context,
                    template: t,
                    onAdd: () => _useTemplate(context, t),
                  ),
                ),
              );
            },
          ),
        ),

        // ── Divider ───────────────────────────────────────────────────────────
        const SizedBox(height: 24),
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                'OR BUILD FROM SCRATCH',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                  color: const Color(0xFF64748B).withAlpha(160),
                ),
              ),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 20),

        // ── Quick-fill chips ──────────────────────────────────────────────────
        const _SectionLabel('QUICK START', icon: Icons.bolt_rounded),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _TemplateBtn(
                'Beginner',
                Icons.star_border_rounded,
                tealSuccess,
                () => _applyTemplate('Beginner Full Body', 'full_body', 'Beginner'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _TemplateBtn(
                'Upper/Lower',
                Icons.swap_vert_rounded,
                steelBlue,
                () => _applyTemplate('Upper/Lower Split', 'upper_lower', 'Intermediate'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _TemplateBtn(
                'PPL',
                Icons.sync_rounded,
                primaryRed,
                () => _applyTemplate('Push Pull Legs', 'push_pull_legs', 'Advanced'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        // Program name — prominent card style
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderLight),
          ),
          child: TextField(
            controller: _nameCtrl,
            textCapitalization: TextCapitalization.words,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              labelText: 'Program Name',
              hintText: 'e.g. My Upper/Lower Program',
              prefixIcon: Container(
                margin: const EdgeInsets.all(10),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryRed.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.edit_rounded, size: 16, color: primaryRed),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 28),
        const _SectionLabel('SPLIT TYPE', icon: Icons.account_tree_rounded),
        const SizedBox(height: 12),
        _SplitOption(
          value: 'upper_lower',
          title: 'Upper / Lower',
          subtitle: '4 days/week · Balanced strength & hypertrophy',
          icon: Icons.swap_vert_rounded,
          color: steelBlue,
          selected: splitType == 'upper_lower',
        ),
        const SizedBox(height: 10),
        _SplitOption(
          value: 'push_pull_legs',
          title: 'Push Pull Legs',
          subtitle: '3–6 days/week · High frequency per muscle group',
          icon: Icons.sync_rounded,
          color: tealSuccess,
          selected: splitType == 'push_pull_legs',
        ),
        const SizedBox(height: 10),
        _SplitOption(
          value: 'full_body',
          title: 'Full Body',
          subtitle: '2–4 days/week · Compound-focused, great for beginners',
          icon: Icons.fitness_center_rounded,
          color: primaryRed,
          selected: splitType == 'full_body',
        ),
        const SizedBox(height: 10),
        _SplitOption(
          value: 'custom',
          title: 'Custom Split',
          subtitle: 'Define your own workout structure from scratch',
          icon: Icons.tune_rounded,
          color: const Color(0xFF8899AA),
          selected: splitType == 'custom',
        ),
      ],
    );
  }
}

class _TemplateBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _TemplateBtn(this.label, this.icon, this.color, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () { HapticFeedback.selectionClick(); onTap(); },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(80)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 5),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Template card for Step 0 horizontal scroll
// ─────────────────────────────────────────────────────────────────────────────

class _ProgramTemplateCard extends StatelessWidget {
  final ProgramTemplate template;
  final VoidCallback onTap;
  const _ProgramTemplateCard({required this.template, required this.onTap});

  Color get _diffColor {
    switch (template.difficulty) {
      case 'Beginner':
        return const Color(0xFF34D399);
      case 'Intermediate':
        return const Color(0xFFFBBF24);
      default:
        return const Color(0xFFF87171);
    }
  }

  Color get _goalColor {
    switch (template.goal) {
      case 'Strength':
        return steelBlue;
      case 'Hypertrophy':
        return const Color(0xFFA78BFA);
      default:
        return tealSuccess;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        width: 172,
        height: 168,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // difficulty + goal badges
            Row(
              children: [
                _MiniChip(template.difficulty, _diffColor),
                const SizedBox(width: 5),
                _MiniChip(template.goal, _goalColor),
              ],
            ),
            const SizedBox(height: 10),
            // name
            Text(
              template.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            const Spacer(),
            // stats row
            Row(
              children: [
                const Icon(Icons.calendar_today_rounded,
                    size: 11, color: Color(0xFF64748B)),
                const SizedBox(width: 3),
                Text(
                  '${template.daysPerWeek}d/wk',
                  style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                const Icon(Icons.timer_rounded,
                    size: 11, color: Color(0xFF64748B)),
                const SizedBox(width: 3),
                Text(
                  '${template.avgMinutesPerSession}min',
                  style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // CTA
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: steelBlue.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: steelBlue.withAlpha(60)),
              ),
              child: const Text(
                'Preview →',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: steelBlue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String label;
  final Color color;
  const _MiniChip(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _SplitOption extends ConsumerWidget {
  final String value;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool selected;

  const _SplitOption({
    required this.value,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.selected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        ref.read(wizardProvider.notifier).setSplit(value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? color.withAlpha(20)
              : Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? color : borderLight,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withAlpha(selected ? 40 : 25),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            if (selected) Icon(Icons.check_circle_rounded, color: color, size: 20),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 1 — Workout Days
// ─────────────────────────────────────────────────────────────────────────────

class _Step1Days extends ConsumerWidget {
  const _Step1Days({super.key});

  static const _dayColors = [
    primaryRed, steelBlue, tealSuccess,
    Color(0xFFF97316), Color(0xFFA78BFA), Color(0xFFFBBF24), Color(0xFFF43F5E),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final days = ref.watch(wizardProvider.select((s) => s.days));
    final splitType = ref.watch(wizardProvider.select((s) => s.splitType));

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        // Header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: primaryRed.withAlpha(20),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: primaryRed.withAlpha(60)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_month_rounded, size: 14, color: primaryRed),
                  const SizedBox(width: 5),
                  Text('${days.length} days',
                      style: const TextStyle(
                          color: primaryRed, fontWeight: FontWeight.w700, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Name each workout day. Tap the field to rename.',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: const Color(0xFF8899AA)),
        ),
        const SizedBox(height: 16),
        ...List.generate(
          days.length,
          (i) => _DayNameField(
            key: ValueKey(i),
            index: i,
            accentColor: _dayColors[i % _dayColors.length],
            initialName: days[i].name,
            onChanged: (v) => ref.read(wizardProvider.notifier).setDayName(i, v),
            onRemove: days.length > 1
                ? () => ref.read(wizardProvider.notifier).removeDay(i)
                : null,
          ).animate().fadeIn(delay: (i * 50).ms, duration: 220.ms)
              .slideY(begin: 0.06, end: 0, duration: 220.ms),
        ),
        if (splitType == 'custom') ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              ref.read(wizardProvider.notifier).addDay();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: steelBlue.withAlpha(80), width: 1.5),
                color: steelBlue.withAlpha(10),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_rounded, size: 18, color: steelBlue),
                  SizedBox(width: 6),
                  Text('Add Day',
                      style: TextStyle(
                          color: steelBlue,
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _DayNameField extends StatefulWidget {
  final int index;
  final String initialName;
  final Color accentColor;
  final ValueChanged<String> onChanged;
  final VoidCallback? onRemove;

  const _DayNameField({
    super.key,
    required this.index,
    required this.initialName,
    required this.accentColor,
    required this.onChanged,
    this.onRemove,
  });

  @override
  State<_DayNameField> createState() => _DayNameFieldState();
}

class _DayNameFieldState extends State<_DayNameField> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.accentColor;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(
        children: [
          // Colored left accent bar
          Container(
            width: 5,
            height: 64,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                bottomLeft: Radius.circular(14),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Day number badge
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              shape: BoxShape.circle,
              border: Border.all(color: color.withAlpha(80)),
            ),
            child: Center(
              child: Text(
                '${widget.index + 1}',
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 13),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: color.withAlpha(12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withAlpha(50)),
              ),
              child: TextField(
                controller: _ctrl,
                onChanged: widget.onChanged,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText: 'e.g. Chest & Triceps',
                  hintStyle: TextStyle(
                      color: color.withAlpha(80),
                      fontSize: 13,
                      fontWeight: FontWeight.w500),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          if (widget.onRemove != null)
            GestureDetector(
              onTap: widget.onRemove,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Icon(Icons.delete_outline_rounded,
                    size: 20, color: color.withAlpha(140)),
              ),
            )
          else
            const SizedBox(width: 14),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 2 — Exercise Library
// ─────────────────────────────────────────────────────────────────────────────

class _Step2Exercises extends ConsumerStatefulWidget {
  const _Step2Exercises({super.key});

  @override
  ConsumerState<_Step2Exercises> createState() => _Step2ExercisesState();
}

class _Step2ExercisesState extends ConsumerState<_Step2Exercises>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _searchCtrl = TextEditingController();
  String _bodyPart = 'all';
  List<ExerciseModel> _exercises = [];
  bool _loading = false;
  String _lastKey = '';

  static const _filters = [
    ('All', 'all', Icons.apps_rounded),
    ('Chest', 'chest', Icons.accessibility_new_rounded),
    ('Back', 'back', Icons.swap_horiz_rounded),
    ('Shoulders', 'shoulders', Icons.sports_handball_rounded),
    ('Arms', 'upper arms', Icons.fitness_center_rounded),
    ('Legs', 'upper legs', Icons.directions_walk_rounded),
    ('Calves', 'lower legs', Icons.directions_run_rounded),
    ('Core', 'waist', Icons.crop_square_rounded),
    ('Cardio', 'cardio', Icons.favorite_rounded),
  ];

  @override
  void initState() {
    super.initState();
    final days = ref.read(wizardProvider).days;
    _tabCtrl = TabController(length: days.length, vsync: this);
    _tabCtrl.addListener(() {
      if (!_tabCtrl.indexIsChanging) {
        ref.read(wizardProvider.notifier).setCurrentDay(_tabCtrl.index);
      }
    });
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showCreateCustom(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreateCustomExerciseSheet(
        onCreated: (exercise) {
          // Toggle it on immediately in the wizard day.
          ref.read(wizardProvider.notifier).toggleExercise(exercise);
          // Reload list so it appears.
          setState(() => _lastKey = '');
          _load();
        },
      ),
    );
  }

  Future<void> _load() async {
    final q = _searchCtrl.text.trim();
    final key = '$_bodyPart:$q';
    if (key == _lastKey) return;
    _lastKey = key;

    if (!mounted) return;
    setState(() => _loading = true);

    try {
      final repo = ref.read(exerciseRepositoryProvider);
      List<ExerciseModel> results;

      if (q.isNotEmpty) {
        results = await repo.searchByName(q, limit: 40);
      } else if (_bodyPart == 'all') {
        final parts = await Future.wait([
          repo.getSimilarExercises('chest', limit: 8),
          repo.getSimilarExercises('back', limit: 8),
          repo.getSimilarExercises('shoulders', limit: 6),
          repo.getSimilarExercises('upper arms', limit: 6),
          repo.getSimilarExercises('upper legs', limit: 8),
          repo.getSimilarExercises('waist', limit: 4),
        ]);
        results = parts.expand((e) => e).toList();
      } else {
        results = await repo.getSimilarExercises(_bodyPart, limit: 30);
      }

      if (mounted) setState(() => _exercises = results);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(wizardProvider);
    final days = state.days;
    final selectedIds =
        days[state.currentDayIndex].exercises.map((e) => e.id).toSet();

    return Column(
      children: [
        // ── Day tabs ────────────────────────────────────────────────────────
        Container(
          color: Theme.of(context).cardTheme.color,
          child: TabBar(
            controller: _tabCtrl,
            isScrollable: true,
            indicatorColor: primaryRed,
            labelColor: primaryRed,
            unselectedLabelColor: const Color(0xFF64748B),
            tabs: days.asMap().entries.map((e) {
              final count = e.value.exercises.length;
              return Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(e.value.name),
                    if (count > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        width: 18,
                        height: 18,
                        decoration: const BoxDecoration(
                            color: primaryRed, shape: BoxShape.circle),
                        child: Center(
                          child: Text(
                            '$count',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
          ),
        ),

        // ── Search bar + Create Custom ──────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (_) => _load(),
                  decoration: InputDecoration(
                    hintText: 'Search exercises…',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              _load();
                            },
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: borderLight)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: borderLight)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _showCreateCustom(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 10),
                  decoration: BoxDecoration(
                    color: steelBlue.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: steelBlue.withAlpha(80)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_circle_rounded,
                          size: 16, color: steelBlue),
                      SizedBox(width: 5),
                      Text('Custom',
                          style: TextStyle(
                              color: steelBlue,
                              fontWeight: FontWeight.w700,
                              fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Body part filter chips ──────────────────────────────────────────
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Colors.white, Colors.white, Colors.transparent],
            stops: [0.0, 0.85, 1.0],
          ).createShader(bounds),
          blendMode: BlendMode.dstIn,
          child: SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(12, 4, 40, 4),
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (_, i) {
                final (label, value, icon) = _filters[i];
                final sel = _bodyPart == value;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _bodyPart = value);
                    _load();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: sel ? primaryRed : Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: sel ? primaryRed : borderLight, width: 1.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon,
                            size: 13,
                            color: sel ? Colors.white : const Color(0xFF64748B)),
                        const SizedBox(width: 5),
                        Text(label,
                            style: TextStyle(
                              color: sel ? Colors.white : const Color(0xFF64748B),
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            )),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        const SizedBox(height: 8),

        // ── Exercise grid ───────────────────────────────────────────────────
        Expanded(
          child: ref.watch(wizardProvider.select((s) => s.isAutoFilling))
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text('Loading exercises…',
                          style: TextStyle(color: Color(0xFF64748B))),
                    ],
                  ),
                )
              : _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _exercises.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.search_off_rounded,
                              size: 48, color: Color(0xFF64748B)),
                          const SizedBox(height: 10),
                          Text('No exercises found',
                              style: Theme.of(context).textTheme.bodyLarge),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 0.72,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: _exercises.length,
                      itemBuilder: (_, i) {
                        final ex = _exercises[i];
                        return _ExerciseCard(
                          exercise: ex,
                          selected: selectedIds.contains(ex.id),
                          onTap: () {
                            HapticFeedback.selectionClick();
                            ref
                                .read(wizardProvider.notifier)
                                .toggleExercise(ex);
                          },
                        ).animate().fadeIn(
                            duration: 250.ms,
                            delay: (i * 20).clamp(0, 200).ms);
                      },
                    ),
        ),
      ],
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  final ExerciseModel exercise;
  final bool selected;
  final VoidCallback onTap;

  const _ExerciseCard({
    required this.exercise,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final muscle = exercise.targetMuscles.isNotEmpty
        ? exercise.targetMuscles.first
        : exercise.bodyParts.isNotEmpty
            ? exercise.bodyParts.first
            : '';

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? primaryRed : borderLight,
            width: selected ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // GIF area
                Expanded(
                  flex: 3,
                  child: ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(13)),
                    child: SizedBox(
                      width: double.infinity,
                      child: _buildGif(exercise.gifUrl),
                    ),
                  ),
                ),
                // Info area
                SizedBox(
                  height: 50,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(6, 4, 6, 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          exercise.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 9.5, fontWeight: FontWeight.w700),
                        ),
                        if (muscle.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(muscle,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: steelBlue,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Selection tint
            if (selected)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: primaryRed.withAlpha(20),
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
              ),
            // Badge top-right
            Positioned(
              top: 4,
              right: 4,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: selected ? primaryRed : Colors.black45,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  selected ? Icons.check_rounded : Icons.add_rounded,
                  size: 11,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGif(String url) {
    final placeholder = Container(
      color: const Color(0xFF1A2840),
      child: const Center(
        child: Icon(Icons.fitness_center_rounded,
            size: 36, color: Color(0xFF334155)),
      ),
    );
    if (url.isEmpty) return placeholder;
    if (url.startsWith('assets/')) {
      return Image.asset(url,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => placeholder);
    }
    return Image.network(url,
        fit: BoxFit.cover, errorBuilder: (_, __, ___) => placeholder);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 3 — Sets & Reps
// ─────────────────────────────────────────────────────────────────────────────

class _Step3Config extends ConsumerStatefulWidget {
  const _Step3Config({super.key});

  @override
  ConsumerState<_Step3Config> createState() => _Step3ConfigState();
}

class _Step3ConfigState extends ConsumerState<_Step3Config>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    final count = ref.read(wizardProvider).days.length;
    _tabCtrl = TabController(length: count, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final days = ref.watch(wizardProvider.select((s) => s.days));

    return Column(
      children: [
        Container(
          color: Theme.of(context).cardTheme.color,
          child: TabBar(
            controller: _tabCtrl,
            isScrollable: true,
            indicatorColor: primaryRed,
            labelColor: primaryRed,
            unselectedLabelColor: const Color(0xFF64748B),
            tabs: days.map((d) => Tab(text: d.name)).toList(),
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: days.asMap().entries.map((e) {
              return _DayConfigPanel(dayIndex: e.key);
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// Reuse the same label helper from program_detail_screen (duplicate to avoid cross-feature import).
List<String?> _wizardSupersetLabels(List<ExerciseModel> exercises) {
  final out = List<String?>.filled(exercises.length, null);
  int letterIdx = 0;
  int i = 0;
  while (i < exercises.length) {
    final groupId = exercises[i].supersetGroupId;
    if (groupId == null) { i++; continue; }
    int j = i;
    while (j < exercises.length && exercises[j].supersetGroupId == groupId) { j++; }
    final runLen = j - i;
    if (runLen >= 2) {
      final letter = String.fromCharCode('A'.codeUnitAt(0) + letterIdx);
      for (int k = 0; k < runLen; k++) { out[i + k] = '$letter${k + 1}'; }
      letterIdx++;
    }
    i = j;
  }
  return out;
}

class _DayConfigPanel extends ConsumerWidget {
  final int dayIndex;
  const _DayConfigPanel({required this.dayIndex});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercises =
        ref.watch(wizardProvider.select((s) => s.days[dayIndex].exercises));

    if (exercises.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add_circle_outline_rounded,
                size: 48, color: Color(0xFF64748B)),
            const SizedBox(height: 12),
            const Text('No exercises in this day',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('Go back to add exercises',
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      );
    }

    final labels = _wizardSupersetLabels(exercises);

    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: exercises.length,
      onReorder: (oldIdx, newIdx) =>
          ref.read(wizardProvider.notifier).reorderExercise(dayIndex, oldIdx, newIdx),
      itemBuilder: (_, i) {
        final label = labels[i];
        final prevSame = i > 0 &&
            exercises[i].supersetGroupId != null &&
            exercises[i - 1].supersetGroupId == exercises[i].supersetGroupId;
        final nextSame = i < exercises.length - 1 &&
            exercises[i].supersetGroupId != null &&
            exercises[i + 1].supersetGroupId == exercises[i].supersetGroupId;

        final card = _ExerciseConfigCard(
          key: ValueKey(exercises[i].id),
          dayIndex: dayIndex,
          exIndex: i,
          supersetLabel: label,
        );

        if (label == null) return card;

        // Wrap with superset header + left bar — same visual as live workout.
        return _SupersetWrapper(
          key: ValueKey('ss_${exercises[i].id}'),
          label: label,
          showHeader: !prevSame,
          continuesBelow: nextSame,
          child: card,
        );
      },
    );
  }
}

class _SupersetWrapper extends StatelessWidget {
  final String label;
  final bool showHeader;
  final bool continuesBelow;
  final Widget child;
  const _SupersetWrapper({
    super.key,
    required this.label,
    required this.showHeader,
    required this.continuesBelow,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showHeader)
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 2),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: steelBlue.withAlpha(30),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: steelBlue.withAlpha(80)),
              ),
              child: const Text('SUPERSET',
                  style: TextStyle(
                      fontSize: 10,
                      color: steelBlue,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5)),
            ),
          ),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 4,
                margin: EdgeInsets.only(bottom: continuesBelow ? 2 : 10),
                decoration: BoxDecoration(
                  color: steelBlue,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(child: child),
            ],
          ),
        ),
      ],
    );
  }
}

class _ExerciseConfigCard extends ConsumerStatefulWidget {
  final int dayIndex;
  final int exIndex;
  final String? supersetLabel;
  const _ExerciseConfigCard(
      {super.key, required this.dayIndex, required this.exIndex, this.supersetLabel});

  @override
  ConsumerState<_ExerciseConfigCard> createState() =>
      _ExerciseConfigCardState();
}

class _ExerciseConfigCardState extends ConsumerState<_ExerciseConfigCard> {
  late final TextEditingController _repsCtrl;

  @override
  void initState() {
    super.initState();
    final ex = ref
        .read(wizardProvider)
        .days[widget.dayIndex]
        .exercises[widget.exIndex];
    final text = ex.repsFrom == ex.repsTo
        ? ex.repsFrom
        : '${ex.repsFrom}-${ex.repsTo}';
    _repsCtrl = TextEditingController(text: text);
  }

  @override
  void dispose() {
    _repsCtrl.dispose();
    super.dispose();
  }

  void _applyTemplate(int sets, String from, String to) {
    ref.read(wizardProvider.notifier).updateExercise(
          widget.dayIndex,
          widget.exIndex,
          sets: sets,
          repsFrom: from,
          repsTo: to,
        );
    _repsCtrl.text = from == to ? from : '$from-$to';
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    final exercises = ref.watch(
        wizardProvider.select((s) => s.days[widget.dayIndex].exercises));
    if (widget.exIndex >= exercises.length) return const SizedBox.shrink();
    final ex = exercises[widget.exIndex];
    final isLinked = widget.supersetLabel != null;
    final canLink = widget.exIndex > 0;

    return Card(
      margin: EdgeInsets.only(
        bottom: isLinked ? 2 : 10,
        left: isLinked ? 4 : 0,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: isLinked
            ? BorderSide(color: steelBlue.withAlpha(140), width: 1.5)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top row: drag handle + GIF thumbnail + name ──────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(Icons.drag_handle_rounded,
                    color: Color(0xFF64748B), size: 20),
                const SizedBox(width: 8),
                // GIF thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: ExerciseGifWidget(
                    gifUrl: ex.gifUrl,
                    exerciseName: ex.name,
                    width: 48,
                    height: 48,
                    borderRadius: 0,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (isLinked) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: steelBlue,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(widget.supersetLabel!,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800)),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Expanded(
                            child: Text(ex.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                      if (ex.targetMuscles.isNotEmpty)
                        Text(ex.targetMuscles.first,
                            style: const TextStyle(
                                fontSize: 11,
                                color: steelBlue,
                                fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                // ── Superset link toggle ──────────────────────────────────
                if (canLink)
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      ref.read(wizardProvider.notifier).linkSuperset(
                            widget.dayIndex,
                            widget.exIndex,
                            !isLinked,
                          );
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: isLinked
                            ? steelBlue.withAlpha(25)
                            : Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isLinked
                              ? steelBlue
                              : Theme.of(context).dividerColor.withAlpha(80),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isLinked
                                ? Icons.link_rounded
                                : Icons.link_off_rounded,
                            size: 14,
                            color: isLinked ? steelBlue : const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isLinked ? 'Superset' : 'Link',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isLinked ? steelBlue : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // ── Controls ─────────────────────────────────────────────────────
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: primaryRed.withAlpha(15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: primaryRed.withAlpha(50)),
                  ),
                  child: const Text('Sets',
                      style: TextStyle(
                          fontSize: 11,
                          color: primaryRed,
                          fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 8),
                _NumStepper(
                  value: ex.sets,
                  min: 1,
                  max: 10,
                  onChanged: (v) =>
                      ref.read(wizardProvider.notifier).updateExercise(
                            widget.dayIndex,
                            widget.exIndex,
                            sets: v,
                          ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: steelBlue.withAlpha(15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: steelBlue.withAlpha(50)),
                  ),
                  child: const Text('Reps',
                      style: TextStyle(
                          fontSize: 11,
                          color: steelBlue,
                          fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 62,
                  child: TextField(
                    controller: _repsCtrl,
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 7),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: borderLight)),
                    ),
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                    keyboardType: TextInputType.text,
                    onChanged: (v) {
                      if (v.contains('-')) {
                        final parts = v.split('-');
                        if (parts.length == 2) {
                          ref.read(wizardProvider.notifier).updateExercise(
                                widget.dayIndex,
                                widget.exIndex,
                                repsFrom: parts[0].trim(),
                                repsTo: parts[1].trim(),
                              );
                        }
                      } else if (v.trim().isNotEmpty) {
                        ref.read(wizardProvider.notifier).updateExercise(
                              widget.dayIndex,
                              widget.exIndex,
                              repsFrom: v.trim(),
                              repsTo: v.trim(),
                            );
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // ── Quick preset chips ────────────────────────────────────────────
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                _TplChip('5×5', () => _applyTemplate(5, '5', '5')),
                _TplChip('3×8-12', () => _applyTemplate(3, '8', '12')),
                _TplChip('4×15', () => _applyTemplate(4, '15', '15')),
                _TplChip('4×4-6', () => _applyTemplate(4, '4', '6')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NumStepper extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  const _NumStepper(
      {required this.value,
      required this.min,
      required this.max,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StepBtn(Icons.remove_rounded,
            value > min ? () => onChanged(value - 1) : null),
        SizedBox(
          width: 26,
          child: Text('$value',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        ),
        _StepBtn(
            Icons.add_rounded, value < max ? () => onChanged(value + 1) : null),
      ],
    );
  }
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  const _StepBtn(this.icon, this.onPressed);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: onPressed != null ? primaryRed.withAlpha(20) : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
              color: onPressed != null
                  ? primaryRed.withAlpha(80)
                  : borderLight),
        ),
        child: Icon(icon,
            size: 14,
            color: onPressed != null ? primaryRed : const Color(0xFF64748B)),
      ),
    );
  }
}

class _TplChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _TplChip(this.label, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: borderLight),
        ),
        child: Text(label,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B))),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 4 — Volume Analysis
// ─────────────────────────────────────────────────────────────────────────────

class _Step4Analysis extends ConsumerWidget {
  const _Step4Analysis({super.key});

  static const _palette = {
    'chest': Color(0xFF38BDF8),
    'back': Color(0xFF34D399),
    'shoulders': Color(0xFFFBBF24),
    'upper arms': Color(0xFFA78BFA),
    'upper legs': Color(0xFFF97316),
    'lower legs': Color(0xFFF43F5E),
    'waist': Color(0xFF06B6D4),
    'cardio': Color(0xFF84CC16),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final days = ref.watch(wizardProvider.select((s) => s.days));
    final muscleSets = _computeSets(days);
    final maxSets = muscleSets.values.isEmpty
        ? 1
        : muscleSets.values.reduce((a, b) => a > b ? a : b);
    final warnings = _warnings(muscleSets);
    final suggestions = _suggestions(muscleSets);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        Text('Volume Overview',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text('Weekly sets per muscle group across all days',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: const Color(0xFF8899AA))),
        const SizedBox(height: 20),
        if (muscleSets.isEmpty)
          const Center(child: Text('No exercises added yet'))
        else
          ...muscleSets.entries.map((e) {
            final color = _palette[e.key] ?? steelBlue;
            return _MuscleBar(
                muscle: e.key, sets: e.value, maxSets: maxSets, color: color);
          }),
        if (warnings.isNotEmpty) ...[
          const SizedBox(height: 24),
          const _SectionLabel('IMBALANCE WARNINGS',
              color: Color(0xFFF97316)),
          const SizedBox(height: 10),
          ...warnings.map((w) => _AlertCard(
              w, const Color(0xFFF97316), Icons.warning_amber_rounded)),
        ],
        if (suggestions.isNotEmpty) ...[
          const SizedBox(height: 20),
          const _SectionLabel('SMART SUGGESTIONS'),
          const SizedBox(height: 10),
          ...suggestions.map((s) =>
              _AlertCard(s, steelBlue, Icons.lightbulb_outline_rounded)),
        ],
        if (warnings.isEmpty && suggestions.isEmpty) ...[
          const SizedBox(height: 24),
          _AlertCard('Your program looks well-balanced!', tealSuccess,
              Icons.check_circle_outline_rounded),
        ],
      ],
    );
  }

  static Map<String, int> _computeSets(List<WizardDay> days) {
    final map = <String, int>{};
    for (final day in days) {
      for (final ex in day.exercises) {
        for (final bp in ex.bodyParts) {
          map[bp] = (map[bp] ?? 0) + ex.sets;
        }
      }
    }
    final sorted = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sorted);
  }

  static List<String> _warnings(Map<String, int> sets) {
    final list = <String>[];
    final push = (sets['chest'] ?? 0) + (sets['shoulders'] ?? 0);
    final pull = sets['back'] ?? 0;
    if (pull > 0 && push > pull * 1.5) {
      list.add(
          'Push volume (chest + shoulders) is much higher than pull volume. Add more back exercises to protect your shoulders.');
    }
    if (push > 0 && pull > push * 1.5) {
      list.add(
          'Pull volume is much higher than push volume. Balance with more chest and shoulder work.');
    }
    final upper = push + pull + (sets['upper arms'] ?? 0);
    final lower = (sets['upper legs'] ?? 0) + (sets['lower legs'] ?? 0);
    if (upper > 0 && lower == 0) {
      list.add(
          'No leg exercises detected. Lower body training is critical for overall strength and hormonal health.');
    }
    return list;
  }

  static List<String> _suggestions(Map<String, int> sets) {
    final list = <String>[];
    if ((sets['chest'] ?? 0) > 0 && (sets['upper arms'] ?? 0) == 0) {
      list.add(
          'Add tricep work to complement your chest training — triceps are heavily involved in all pressing movements.');
    }
    if ((sets['back'] ?? 0) > 0 && (sets['upper arms'] ?? 0) == 0) {
      list.add(
          'Add bicep work to complement your back training for a complete arm stimulus.');
    }
    if ((sets['upper legs'] ?? 0) > 0 && (sets['lower legs'] ?? 0) == 0) {
      list.add('Consider adding calf raises to complete your leg training.');
    }
    if ((sets['waist'] ?? 0) == 0) {
      list.add(
          'Core training (planks, ab work) improves stability and performance in all other lifts.');
    }
    return list;
  }
}

class _MuscleBar extends StatelessWidget {
  final String muscle;
  final int sets;
  final int maxSets;
  final Color color;
  const _MuscleBar(
      {required this.muscle,
      required this.sets,
      required this.maxSets,
      required this.color});

  @override
  Widget build(BuildContext context) {
    final label = muscle.length > 11 ? muscle.substring(0, 11) : muscle;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: Text(label.toUpperCase(),
                style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B))),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: maxSets > 0 ? sets / maxSets : 0,
                color: color,
                backgroundColor: color.withAlpha(30),
                minHeight: 10,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 40,
            child: Text('$sets sets',
                style: const TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final String message;
  final Color color;
  final IconData icon;
  const _AlertCard(this.message, this.color, this.icon);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
              child: Text(message,
                  style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 5 — Review & Save
// ─────────────────────────────────────────────────────────────────────────────

class _Step5Review extends ConsumerStatefulWidget {
  const _Step5Review({super.key});

  @override
  ConsumerState<_Step5Review> createState() => _Step5ReviewState();
}

class _Step5ReviewState extends ConsumerState<_Step5Review> {
  bool _setActive = true;
  bool _saving = false;

  Future<void> _save() async {
    final wizState = ref.read(wizardProvider);
    if (wizState.days.isEmpty || wizState.programName.trim().isEmpty) return;

    setState(() => _saving = true);
    HapticFeedback.mediumImpact();

    try {
      const uuid = Uuid();
      final builtDays = wizState.days
          .asMap()
          .entries
          .map(
            (e) => WorkoutDayModel(
              id: uuid.v4(),
              name: e.value.name,
              dayNumber: e.key + 1,
              exercises: e.value.exercises,
            ),
          )
          .toList();

      final program = ProgramModel(
        id: uuid.v4(),
        name: wizState.programName.trim(),
        splitType: wizState.splitType,
        goal: wizState.goal,
        experienceLevel: wizState.level,
        days: builtDays,
      );

      await ref.read(programsProvider.notifier).addProgram(program);
      if (_setActive) {
        await ref.read(programsProvider.notifier).setActive(program.id);
      }

      ref.read(wizardProvider.notifier).reset();
      if (mounted) {
        context.pop();
        context.push('/programs/${program.id}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving program: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(wizardProvider);
    final totalEx = state.days.fold(0, (s, d) => s + d.exercises.length);
    final totalSets = state.days.fold(
        0, (s, d) => s + d.exercises.fold(0, (ss, e) => ss + e.sets));

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
          children: [
            // ── Program header ──────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryRed.withAlpha(30), steelBlue.withAlpha(20)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: primaryRed.withAlpha(60)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(state.programName,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _Badge(
                          state.splitType
                              .replaceAll('_', '/')
                              .toUpperCase(),
                          primaryRed),
                      _Badge(state.level.toUpperCase(), steelBlue),
                      _Badge('${state.days.length} DAYS', tealSuccess),
                      _Badge('$totalEx EXERCISES',
                          const Color(0xFFF97316)),
                      _Badge('$totalSets TOTAL SETS',
                          const Color(0xFFA78BFA)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Day cards ───────────────────────────────────────────────────
            ...state.days.asMap().entries.map((e) {
              return _ReviewDayCard(day: e.value, index: e.key)
                  .animate()
                  .fadeIn(delay: (e.key * 60).ms);
            }),

            const SizedBox(height: 16),

            // ── Set Active toggle ───────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderLight),
              ),
              child: Row(
                children: [
                  const Icon(Icons.play_circle_outline_rounded,
                      color: tealSuccess, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Set as Active Program',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                        Text('Start training with this program immediately',
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  Switch(
                    value: _setActive,
                    onChanged: (v) => setState(() => _setActive = v),
                    activeThumbColor: Colors.white,
                    activeTrackColor: tealSuccess,
                    inactiveThumbColor: const Color(0xFF94A3B8),
                    inactiveTrackColor: const Color(0xFF1E293B),
                  ),
                ],
              ),
            ),
          ],
        ),

        // ── Save button (pinned) ────────────────────────────────────────────
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: EdgeInsets.fromLTRB(
                20, 14, 20, MediaQuery.of(context).viewPadding.bottom + 14),
            color: Theme.of(context).scaffoldBackgroundColor,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: primaryRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Save Program',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

class _ReviewDayCard extends StatelessWidget {
  final WizardDay day;
  final int index;
  const _ReviewDayCard({required this.day, required this.index});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                      color: primaryRed, shape: BoxShape.circle),
                  child: Center(
                    child: Text('${index + 1}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(day.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15)),
                ),
                Text('${day.exercises.length} exercises',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            if (day.exercises.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...day.exercises.map(
                (ex) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      const Icon(Icons.circle,
                          size: 5, color: Color(0xFF64748B)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(ex.name,
                            style: Theme.of(context).textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis),
                      ),
                      Text(
                        '${ex.sets}×${ex.repsFrom == ex.repsTo ? ex.repsFrom : '${ex.repsFrom}-${ex.repsTo}'}',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared helpers
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  final Color? color;
  final IconData? icon;
  const _SectionLabel(this.text, {this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    final c = color ?? const Color(0xFF64748B);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 13, color: c),
          const SizedBox(width: 5),
        ],
        Text(
          text,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
            color: c,
          ),
        ),
      ],
    );
  }
}
