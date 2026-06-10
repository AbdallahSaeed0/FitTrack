import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'core/services/supabase_service.dart';
import 'core/services/update_service.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'main.dart' show scaffoldMessengerKey;
import 'shared/providers/theme_provider.dart';
import 'shared/widgets/update_dialog.dart';
import 'data/models/exercise_model.dart';
import 'data/models/program_model.dart';
import 'data/models/session_model.dart';
import 'data/repositories/meal_log_repository.dart';
import 'data/repositories/program_repository.dart';
import 'data/repositories/session_repository.dart';
import 'data/repositories/user_profile_repository.dart';
import 'features/analytics/analytics_screen.dart';
import 'features/history/session_detail_screen.dart';
import 'features/history/exercise_progression_screen.dart';
import 'features/share/share_workout_screen.dart';
import 'features/auth/auth_screen.dart';
import 'features/exercises/exercise_detail_screen.dart';
import 'features/exercises/replace_exercise_screen.dart';
import 'features/home/calendar_view_screen.dart';
import 'features/home/home_screen.dart';
import 'features/nutrition/nutrition_home_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/programs/wizard_flow.dart';
import 'features/templates/templates_screen.dart';
import 'features/programs/program_detail_screen.dart';
import 'features/programs/programs_screen.dart';
import 'features/onboarding/onboarding_flow.dart';
import 'features/workout/live_workout_screen.dart';
import 'features/workout/workout_provider.dart';
import 'features/workout/workout_screen.dart';
import 'shared/providers/shell_tab_provider.dart';
import 'shared/providers/user_profile_provider.dart';
import 'core/utils/date_utils.dart';
import 'core/utils/program_seeder.dart';

/// Enables drag-to-scroll with mouse and trackpad on Flutter Web/Desktop.
/// On mobile, touch is already included by default — this just adds the rest.
class _AppScrollBehavior extends MaterialScrollBehavior {
  const _AppScrollBehavior();
  @override
  Set<PointerDeviceKind> get dragDevices => const {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}

final _router = GoRouter(
  initialLocation: '/home',
  routes: [
    ShellRoute(
      builder: (context, state, child) => _MainShell(child: child),
      routes: [
        GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
        GoRoute(path: '/workout', builder: (_, __) => const WorkoutScreen()),
        GoRoute(path: '/programs', builder: (_, __) => const ProgramsScreen()),
        GoRoute(
            path: '/nutrition',
            builder: (_, __) => const NutritionHomeScreen()),
        GoRoute(
            path: '/analytics', builder: (_, __) => const AnalyticsScreen()),
        GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
      ],
    ),
    GoRoute(
      path: '/calendar',
      builder: (_, __) => const CalendarViewScreen(),
    ),
    GoRoute(
      path: '/workout/active',
      builder: (_, __) => const LiveWorkoutScreen(),
    ),
    GoRoute(
      path: '/programs/create',
      builder: (_, __) => const WizardFlow(),
    ),
    GoRoute(
      path: '/programs/templates',
      builder: (_, __) => const TemplatesScreen(),
    ),
    GoRoute(
      path: '/programs/:id',
      builder: (_, state) => ProgramDetailScreen(
        programId: state.pathParameters['id'] ?? '',
      ),
    ),
    GoRoute(
      path: '/exercises/replace',
      builder: (_, state) {
        final extra = state.extra as Map<String, dynamic>;
        return ReplaceExerciseScreen(
          program: extra['program'] as ProgramModel,
          dayIndex: extra['dayIndex'] as int,
          exerciseIndex: extra['exerciseIndex'] as int,
          currentExercise: extra['exercise'] as ExerciseModel,
        );
      },
    ),
    GoRoute(
      path: '/exercises/:id',
      builder: (_, state) {
        final exercise = state.extra as ExerciseModel?;
        return ExerciseDetailScreen(
          exerciseId: state.pathParameters['id'] ?? '',
          exercise: exercise,
        );
      },
    ),
    GoRoute(
      path: '/session/:id',
      builder: (_, state) => SessionDetailScreen(
        sessionId: state.pathParameters['id'] ?? '',
      ),
    ),
    GoRoute(
      path: '/exercise-progress',
      builder: (_, state) => ExerciseProgressionScreen(
        exerciseName: state.extra as String? ?? '',
      ),
    ),
    GoRoute(
      path: '/share-workout',
      builder: (_, state) {
        final session = state.extra as WorkoutSessionModel;
        return ShareWorkoutScreen(session: session);
      },
    ),
  ],
);

class FitTrackApp extends ConsumerStatefulWidget {
  const FitTrackApp({super.key});

  @override
  ConsumerState<FitTrackApp> createState() => _FitTrackAppState();
}

class _FitTrackAppState extends ConsumerState<FitTrackApp> {
  bool _loggedIn = false;
  bool _dataLoaded = false;
  late final StreamSubscription<dynamic> _authSub;

  @override
  void initState() {
    super.initState();
    _loggedIn = SupabaseService.isLoggedIn;
    _dataLoaded = _loggedIn;
    _authSub = SupabaseService.client.auth.onAuthStateChange.listen((data) {
      if (!mounted) return;
      final signedIn = data.session != null;
      if (!signedIn && _loggedIn) {
        setState(() {
          _loggedIn = false;
          _dataLoaded = false;
        });
      }
    });
    if (_loggedIn) {
      Future.delayed(const Duration(seconds: 3), _checkForUpdates);
    }
  }

  @override
  void dispose() {
    _authSub.cancel();
    super.dispose();
  }

  Future<void> _onAuthenticated() async {
    await Future.wait([
      UserProfileRepository.instance.init(),
      ProgramRepository.instance.init(),
      SessionRepository.instance.init(),
      MealLogRepository.instance.init(),
    ]);
    await ProgramSeeder.seedIfEmpty();

    if (mounted) {
      setState(() {
        _loggedIn = true;
        _dataLoaded = true;
      });
      // Rebuild providers with fresh data
      ref.invalidate(userProfileProvider);
    }
  }

  Future<void> _checkForUpdates() async {
    final release = await UpdateService().checkForUpdates();
    if (release != null && mounted) {
      showDialog<void>(
        context: context,
        builder: (_) => UpdateDialog(release: release),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    if (!_loggedIn || !_dataLoaded) {
      return MaterialApp(
        title: 'FitTrack',
        debugShowCheckedModeBanner: false,
        theme: lightTheme(),
        darkTheme: darkTheme(),
        themeMode: themeMode,
        scrollBehavior: const _AppScrollBehavior(),
        scaffoldMessengerKey: scaffoldMessengerKey,
        home: AuthScreen(onAuthenticated: _onAuthenticated),
      );
    }

    final profile = ref.watch(userProfileProvider);

    if (profile.isFirstLaunch) {
      return MaterialApp(
        title: 'FitTrack',
        debugShowCheckedModeBanner: false,
        theme: lightTheme(),
        darkTheme: darkTheme(),
        themeMode: themeMode,
        scrollBehavior: const _AppScrollBehavior(),
        scaffoldMessengerKey: scaffoldMessengerKey,
        home: const OnboardingFlow(),
      );
    }

    return MaterialApp.router(
      title: 'FitTrack',
      debugShowCheckedModeBanner: false,
      theme: lightTheme(),
      darkTheme: darkTheme(),
      themeMode: themeMode,
      scrollBehavior: const _AppScrollBehavior(),
      routerConfig: _router,
      scaffoldMessengerKey: scaffoldMessengerKey,
    );
  }
}

class _MainShell extends ConsumerStatefulWidget {
  final Widget child;
  const _MainShell({required this.child});

  @override
  ConsumerState<_MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<_MainShell> {
  late final PageController _pageController;
  int _currentIndex = 0;

  static const _tabs = [
    '/home',
    '/workout',
    '/programs',
    '/nutrition',
    '/analytics',
    '/profile',
  ];

  static const _screens = <Widget>[
    HomeScreen(),
    WorkoutScreen(),
    ProgramsScreen(),
    NutritionHomeScreen(),
    AnalyticsScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _MainShell old) {
    super.didUpdateWidget(old);
    final targetIndex = _indexFromChild(widget.child);
    if (targetIndex != -1 && targetIndex != _currentIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _currentIndex = targetIndex);
        _pageController.jumpToPage(targetIndex);
      });
    }
  }

  int _indexFromChild(Widget child) {
    if (child is HomeScreen) return 0;
    if (child is WorkoutScreen) return 1;
    if (child is ProgramsScreen) return 2;
    if (child is NutritionHomeScreen) return 3;
    if (child is AnalyticsScreen) return 4;
    if (child is ProfileScreen) return 5;
    return -1;
  }

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
    _pageController.jumpToPage(index);
    context.go(_tabs[index]);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int?>(shellTabProvider, (_, next) {
      if (next == null) return;
      if (next != _currentIndex) {
        setState(() => _currentIndex = next);
        _pageController.jumpToPage(next);
        context.go(_tabs[next]);
      }
      // consume the request
      Future.microtask(
          () => ref.read(shellTabProvider.notifier).state = null);
    });

    final workoutState = ref.watch(workoutProvider);
    final isWorkoutActive = workoutState.isActive;

    return Scaffold(
      body: SafeArea(
        // top: true lets status bar not overlap; bottom: false because
        // BottomNavigationBar already insets itself
        bottom: false,
        child: PageView(
          controller: _pageController,
          physics: const ClampingScrollPhysics(),
          onPageChanged: (index) {
            setState(() => _currentIndex = index);
            context.go(_tabs[index]);
          },
          children: _screens,
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Persistent mini workout banner — tap to return to active session
          if (isWorkoutActive)
            _WorkoutMiniBanner(
              dayName: workoutState.currentDay?.name ?? 'Workout',
              elapsed: workoutState.elapsedSeconds,
            ),
          SafeArea(
            top: false,
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: _onTabTapped,
              selectedItemColor: AppColors.primaryBlue,
              unselectedItemColor: AppColors.mediumGray,
              items: const [
                BottomNavigationBarItem(
                    icon: Icon(Icons.home_rounded), label: 'Home'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.fitness_center_rounded), label: 'Workout'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.list_alt_rounded), label: 'Programs'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.restaurant_rounded), label: 'Nutrition'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.bar_chart_rounded), label: 'Progress'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.person_rounded), label: 'Profile'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkoutMiniBanner extends StatelessWidget {
  final String dayName;
  final int elapsed;
  const _WorkoutMiniBanner({required this.dayName, required this.elapsed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/workout/active'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.primaryBlue,
          border: Border(
              top: BorderSide(color: AppColors.primaryBlue.withAlpha(80))),
        ),
        child: Row(
          children: [
            const Icon(Icons.fitness_center_rounded,
                color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                dayName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
            Text(
              FitDateUtils.formatTime(elapsed),
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
                fontSize: 13,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white70, size: 14),
          ],
        ),
      ),
    );
  }
}
