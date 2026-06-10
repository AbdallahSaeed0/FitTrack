import 'package:flutter/foundation.dart';
import '../models/meal_log_model.dart';
import '../../core/services/supabase_service.dart';
import '../../core/services/local_cache_service.dart';

class MealLogRepository {
  static final MealLogRepository instance = MealLogRepository._();
  MealLogRepository._();

  List<MealLog> _cache = [];

  Future<void> init() async {
    // 1. Load local cache immediately
    final local = LocalCacheService.getMealLogs();
    if (local.isNotEmpty) {
      _cache = local.map((r) => MealLog.fromRow(r)).toList();
    }

    // 2. Push pending offline writes
    await _flushPending();

    // 3. Fetch from Supabase
    try {
      final data = await SupabaseService.client
          .from('meal_logs')
          .select()
          .eq('user_id', SupabaseService.userId)
          .order('timestamp', ascending: false);
      _cache = (data as List)
          .map((r) => MealLog.fromRow(r as Map<String, dynamic>))
          .toList();
      await LocalCacheService.saveMealLogs(
          _cache.map((l) => l.toRow(SupabaseService.userId)).toList());
    } catch (e) {
      debugPrint('[MealLogRepo] offline — using local cache: $e');
    }
  }

  Future<void> _flushPending() async {
    final queue = LocalCacheService.getPendingSync()
        .where((e) => e['table'] == 'meal_logs')
        .toList();
    for (final entry in queue) {
      try {
        if (entry['op'] == 'insert') {
          await SupabaseService.client
              .from('meal_logs')
              .insert(entry['data'] as Map<String, dynamic>);
        } else if (entry['op'] == 'delete') {
          await SupabaseService.client
              .from('meal_logs')
              .delete()
              .eq('id', entry['id'] as String);
        }
        await LocalCacheService.removePendingSync(
            'meal_logs', entry['id'] as String);
      } catch (_) {
        break;
      }
    }
  }

  Future<void> _persistCache() async {
    await LocalCacheService.saveMealLogs(
        _cache.map((l) => l.toRow(SupabaseService.userId)).toList());
  }

  List<MealLog> getAll() =>
      List.of(_cache)..sort((a, b) => b.timestamp.compareTo(a.timestamp));

  List<MealLog> getToday() {
    final today = DateTime.now();
    return getAll().where((log) {
      final t = log.timestamp;
      return t.year == today.year &&
          t.month == today.month &&
          t.day == today.day;
    }).toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  Future<void> add(MealLog log) async {
    _cache.add(log);
    await _persistCache();

    try {
      await SupabaseService.client
          .from('meal_logs')
          .insert(log.toRow(SupabaseService.userId));
      await LocalCacheService.removePendingSync('meal_logs', log.id);
    } catch (e) {
      debugPrint('[MealLogRepo] offline add — queued: $e');
      await LocalCacheService.addPendingSync({
        'table': 'meal_logs',
        'op': 'insert',
        'id': log.id,
        'data': log.toRow(SupabaseService.userId),
      });
    }
  }

  Future<void> delete(String id) async {
    _cache.removeWhere((l) => l.id == id);
    await _persistCache();

    try {
      await SupabaseService.client.from('meal_logs').delete().eq('id', id);
      await LocalCacheService.removePendingSync('meal_logs', id);
    } catch (e) {
      debugPrint('[MealLogRepo] offline delete — queued: $e');
      await LocalCacheService.addPendingSync({
        'table': 'meal_logs',
        'op': 'delete',
        'id': id,
        'data': {},
      });
    }
  }
}
