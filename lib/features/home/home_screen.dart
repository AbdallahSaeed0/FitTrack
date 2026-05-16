import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_utils.dart';
import '../../data/models/session_model.dart';
import '../../shared/providers/user_profile_provider.dart';
import '../../shared/widgets/stat_card.dart';
import '../home/home_provider.dart';
import '../home/calendar_view_screen.dart';
import '../programs/programs_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(homeRefreshProvider);
    final profile = ref.watch(userProfileProvider);
    final weekSessions = ref.watch(thisWeekSessionsProvider);
    final streak = ref.watch(streakProvider);
    final activeProgram = ref.watch(activeProgramProvider);
    final recentSessions = ref.watch(recentSessionsProvider);

    final weekDays = FitDateUtils.currentWeek();
    final trainedDays = weekSessions.map((s) => s.startTime).toSet();

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back,',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    Text(
                      profile.name,
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: StatCard(
                            title: 'This Week',
                            value: '${weekSessions.length}/7',
                            subtitle: 'sessions completed',
                            color: tealSuccess,
                            icon: Icons.calendar_today_rounded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: StatCard(
                            title: 'Streak',
                            value: '$streak',
                            subtitle: streak == 1 ? 'week' : 'weeks',
                            color: primaryRed,
                            icon: Icons.local_fire_department_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('This Week',
                            style: Theme.of(context).textTheme.titleMedium),
                        GestureDetector(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const CalendarViewScreen(),
                            ),
                          ),
                          child: const Text(
                            'View Calendar',
                            style: TextStyle(
                              color: primaryRed,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _WeekCalendar(weekDays: weekDays, trainedDays: trainedDays),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Recent Workouts', style: Theme.of(context).textTheme.titleMedium),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            if (recentSessions.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
                  child: Center(
                    child: Column(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: tealSuccess.withAlpha(20),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.fitness_center_rounded, color: tealSuccess, size: 36),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No workouts yet.\nStart your first session!',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final session = recentSessions[index];
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                      child: _SessionCard(session: session),
                    );
                  },
                  childCount: recentSessions.length,
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                child: activeProgram == null
                    ? ElevatedButton.icon(
                        onPressed: () => context.push('/programs/create'),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Set Up Program'),
                        style: ElevatedButton.styleFrom(backgroundColor: primaryRed),
                      )
                    : ElevatedButton.icon(
                        onPressed: () {
                          final day = activeProgram.days[
                              activeProgram.currentDayIndex % activeProgram.days.length];
                          if (!day.isRestDay) {
                            context.push('/workout/active');
                          } else {
                            final nextIndex =
                                (activeProgram.currentDayIndex + 1) % activeProgram.days.length;
                            final nextDay = activeProgram.days[nextIndex];
                            context.push('/workout/active',
                                extra: {'day': nextDay, 'program': activeProgram});
                          }
                        },
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('Start Today\'s Workout'),
                        style: ElevatedButton.styleFrom(backgroundColor: primaryRed),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekCalendar extends StatelessWidget {
  final List<DateTime> weekDays;
  final Set<DateTime> trainedDays;

  const _WeekCalendar({required this.weekDays, required this.trainedDays});

  bool _isTrained(DateTime day) {
    return trainedDays.any((d) => FitDateUtils.isSameDay(d, day));
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: weekDays.map((day) {
        final isToday = FitDateUtils.isToday(day);
        final isTrained = _isTrained(day);
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: isTrained ? tealSuccess : Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isToday ? steelBlue : (isTrained ? tealSuccess : Theme.of(context).dividerColor.withAlpha(60)),
                width: isToday ? 2 : 1,
              ),
            ),
            child: Column(
              children: [
                Text(
                  FitDateUtils.formatDayName(day),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isTrained ? Colors.white : Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
                const SizedBox(height: 4),
                isTrained
                    ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                    : Text(
                        day.day.toString(),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isToday ? steelBlue : Theme.of(context).textTheme.titleMedium?.color,
                        ),
                      ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final WorkoutSessionModel session;

  const _SessionCard({required this.session});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: tealSuccess.withAlpha(25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.fitness_center_rounded, color: tealSuccess, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(session.dayName, style: Theme.of(context).textTheme.titleMedium),
                  Text(
                    '${session.durationMinutes} min · ${DateFormat('MMM d').format(session.startTime)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF8899AA)),
          ],
        ),
      ),
    );
  }
}
