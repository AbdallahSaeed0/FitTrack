import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/services/update_service.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'main.dart' show scaffoldMessengerKey;
import 'shared/providers/theme_provider.dart';
import 'shared/widgets/update_dialog.dart';
import 'data/models/exercise_model.dart';
import 'data/models/program_model.dart';
import 'features/analytics/analytics_screen.dart';
import 'features/exercises/exercise_detail_screen.dart';
import 'features/exercises/replace_exercise_screen.dart';
import 'features/home/calendar_view_screen.dart';
import 'features/home/home_screen.dart';
import 'features/nutrition/nutrition_home_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/programs/create_program_flow.dart';
import 'features/programs/program_detail_screen.dart';
import 'features/programs/programs_screen.dart';
import 'features/workout/live_workout_screen.dart';
import 'features/workout/workout_screen.dart';

final _router = GoRouter(
  initialLocation: '/home',
  routes: [
    ShellRoute(
      builder: (context, state, child) => _MainShell(child: child),
      routes: [
        GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
        GoRoute(path: '/workout', builder: (_, __) => const WorkoutScreen()),
        GoRoute(path: '/programs', builder: (_, __) => const ProgramsScreen()),
        GoRoute(path: '/nutrition', builder: (_, __) => const NutritionHomeScreen()),
        GoRoute(path: '/analytics', builder: (_, __) => const AnalyticsScreen()),
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
      builder: (_, __) => const CreateProgramFlow(),
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
  ],
);

class FitTrackApp extends ConsumerStatefulWidget {
  const FitTrackApp({super.key});

  @override
  ConsumerState<FitTrackApp> createState() => _FitTrackAppState();
}

class _FitTrackAppState extends ConsumerState<FitTrackApp> {
  @override
  void initState() {
    super.initState();
    // Check for updates 3 seconds after launch so it doesn't block startup
    Future.delayed(const Duration(seconds: 3), _checkForUpdates);
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
    return MaterialApp.router(
      title: 'FitTrack',
      debugShowCheckedModeBanner: false,
      theme: lightTheme(),
      darkTheme: darkTheme(),
      themeMode: themeMode,
      routerConfig: _router,
      scaffoldMessengerKey: scaffoldMessengerKey,
    );
  }
}

class _MainShell extends StatefulWidget {
  final Widget child;

  const _MainShell({required this.child});

  @override
  State<_MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<_MainShell> {
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
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const ClampingScrollPhysics(),
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
          context.go(_tabs[index]);
        },
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        selectedItemColor: AppColors.primaryBlue,
        unselectedItemColor: AppColors.mediumGray,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.fitness_center_rounded), label: 'Workout'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt_rounded), label: 'Programs'),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant_rounded), label: 'Nutrition'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart_rounded), label: 'Progress'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}
