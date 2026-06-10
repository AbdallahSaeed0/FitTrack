import 'package:flutter/foundation.dart';
import '../models/session_model.dart';
import '../../core/services/supabase_service.dart';
import '../../core/services/local_cache_service.dart';

class SessionRepository {
  static final SessionRepository instance = SessionRepository._();
  SessionRepository._();

  List<WorkoutSessionModel> _cache = [];

  Future<void> init() async {
    // 1. Load local cache immediately
    final local = LocalCacheService.getSessions();
    if (local.isNotEmpty) {
      _cache = local.map((r) => WorkoutSessionModel.fromRow(r)).toList();
    }

    // 2. Push pending offline writes
    await _flushPending();

    // 3. Fetch from Supabase
    try {
      final data = await SupabaseService.client
          .from('workout_sessions')
          .select()
          .eq('user_id', SupabaseService.userId)
          .order('start_time', ascending: false);
      _cache = (data as List)
          .map((r) => WorkoutSessionModel.fromRow(r as Map<String, dynamic>))
          .toList();
      await LocalCacheService.saveSessions(
          _cache.map((s) => s.toRow(SupabaseService.userId)).toList());
    } catch (e) {
      debugPrint('[SessionRepo] offline — using local cache: $e');
    }
  }

  Future<void> _flushPending() async {
    final queue = LocalCacheService.getPendingSync()
        .where((e) => e['table'] == 'workout_sessions')
        .toList();
    for (final entry in queue) {
      try {
        if (entry['op'] == 'upsert') {
          await SupabaseService.client
              .from('workout_sessions')
              .upsert(entry['data'] as Map<String, dynamic>);
        } else if (entry['op'] == 'delete') {
          await SupabaseService.client
              .from('workout_sessions')
              .delete()
              .eq('id', entry['id'] as String);
        }
        await LocalCacheService.removePendingSync(
            'workout_sessions', entry['id'] as String);
      } catch (_) {
        break;
      }
    }
  }

  Future<void> _persistCache() async {
    await LocalCacheService.saveSessions(
        _cache.map((s) => s.toRow(SupabaseService.userId)).toList());
  }

  List<WorkoutSessionModel> getAll() =>
      List.of(_cache)..sort((a, b) => b.startTime.compareTo(a.startTime));

  List<WorkoutSessionModel> getRecent({int limit = 5}) =>
      getAll().take(limit).toList();

  List<WorkoutSessionModel> getThisWeek() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final start = DateTime(monday.year, monday.month, monday.day);
    return getAll()
        .where((s) => s.startTime.isAfter(start) && s.completed)
        .toList();
  }

  List<WorkoutSessionModel> getThisMonth() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    return getAll()
        .where((s) => s.startTime.isAfter(start) && s.completed)
        .toList();
  }

  List<WorkoutSessionModel> getLast12Weeks() {
    final cutoff = DateTime.now().subtract(const Duration(days: 84));
    return getAll()
        .where((s) => s.startTime.isAfter(cutoff) && s.completed)
        .toList();
  }

  WorkoutSessionModel? getById(String id) {
    try {
      return _cache.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> save(WorkoutSessionModel session) async {
    _cache.removeWhere((s) => s.id == session.id);
    _cache.add(session);
    await _persistCache();

    try {
      await SupabaseService.client
          .from('workout_sessions')
          .upsert(session.toRow(SupabaseService.userId));
      await LocalCacheService.removePendingSync(
          'workout_sessions', session.id);
    } catch (e) {
      debugPrint('[SessionRepo] offline save — queued: $e');
      await LocalCacheService.addPendingSync({
        'table': 'workout_sessions',
        'op': 'upsert',
        'id': session.id,
        'data': session.toRow(SupabaseService.userId),
      });
    }
  }

  Future<void> fetchFromRemote() async {
    await _flushPending();
    try {
      final data = await SupabaseService.client
          .from('workout_sessions')
          .select()
          .eq('user_id', SupabaseService.userId)
          .order('start_time', ascending: false);
      _cache = (data as List)
          .map((r) => WorkoutSessionModel.fromRow(r as Map<String, dynamic>))
          .toList();
      await _persistCache();
    } catch (e) {
      debugPrint('[SessionRepo] fetchFromRemote failed (offline?): $e');
    }
  }

  Future<void> delete(String id) async {
    _cache.removeWhere((s) => s.id == id);
    await _persistCache();

    try {
      await SupabaseService.client
          .from('workout_sessions')
          .delete()
          .eq('id', id);
      await LocalCacheService.removePendingSync('workout_sessions', id);
    } catch (e) {
      debugPrint('[SessionRepo] offline delete — queued: $e');
      await LocalCacheService.addPendingSync({
        'table': 'workout_sessions',
        'op': 'delete',
        'id': id,
        'data': {},
      });
    }
  }

  List<({DateTime date, List<LoggedSetModel> sets})> getExerciseHistory(
    String exerciseName, {
    int limit = 5,
  }) {
    final result = <({DateTime date, List<LoggedSetModel> sets})>[];
    for (final session in getAll().where((s) => s.completed)) {
      for (final ex in session.exercises) {
        if (ex.exerciseName.toLowerCase().trim() ==
                exerciseName.toLowerCase().trim() &&
            ex.sets.isNotEmpty) {
          result.add((date: session.startTime, sets: ex.sets));
          break;
        }
      }
      if (result.length >= limit) break;
    }
    return result;
  }

  int getConsecutiveWeeks() {
    final now = DateTime.now();
    int streak = 0;
    for (int i = 0; i < 52; i++) {
      final weekStart =
          now.subtract(Duration(days: now.weekday - 1 + i * 7));
      final weekEnd = weekStart.add(const Duration(days: 7));
      final hasSession = _cache.any(
        (s) =>
            s.completed &&
            s.startTime.isAfter(weekStart) &&
            s.startTime.isBefore(weekEnd),
      );
      if (hasSession) {
        streak++;
      } else if (i > 0) {
        break;
      }
    }
    return streak;
  }
}
