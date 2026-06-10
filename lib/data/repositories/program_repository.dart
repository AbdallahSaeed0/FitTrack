import 'package:flutter/foundation.dart';
import '../models/program_model.dart';
import '../../core/services/supabase_service.dart';
import '../../core/services/local_cache_service.dart';

class ProgramRepository {
  static final ProgramRepository instance = ProgramRepository._();
  ProgramRepository._();

  List<ProgramModel> _cache = [];

  Future<void> init() async {
    // 1. Load local cache immediately (works offline)
    final local = LocalCacheService.getPrograms();
    if (local.isNotEmpty) {
      _cache = local.map((r) => ProgramModel.fromRow(r)).toList();
    }

    // 2. Push any pending offline writes
    await _flushPending();

    // 3. Fetch fresh data from Supabase
    try {
      final data = await SupabaseService.client
          .from('programs')
          .select()
          .eq('user_id', SupabaseService.userId)
          .order('created_at');
      _cache = (data as List)
          .map((r) => ProgramModel.fromRow(r as Map<String, dynamic>))
          .toList();
      await LocalCacheService.savePrograms(
          _cache.map((p) => p.toRow(SupabaseService.userId)).toList());
    } catch (e) {
      debugPrint('[ProgramRepo] offline — using local cache: $e');
    }
  }

  Future<void> _flushPending() async {
    final queue = LocalCacheService.getPendingSync()
        .where((e) => e['table'] == 'programs')
        .toList();
    for (final entry in queue) {
      try {
        if (entry['op'] == 'upsert') {
          await SupabaseService.client
              .from('programs')
              .upsert(entry['data'] as Map<String, dynamic>);
        } else if (entry['op'] == 'delete') {
          await SupabaseService.client
              .from('programs')
              .delete()
              .eq('id', entry['id'] as String);
        }
        await LocalCacheService.removePendingSync('programs', entry['id'] as String);
      } catch (_) {
        break; // still offline — stop trying
      }
    }
  }

  Future<void> _persistCache() async {
    await LocalCacheService.savePrograms(
        _cache.map((p) => p.toRow(SupabaseService.userId)).toList());
  }

  List<ProgramModel> getAll() =>
      List.of(_cache)..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  ProgramModel? getById(String id) {
    try {
      return _cache.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  ProgramModel? getActive() {
    try {
      return _cache.firstWhere((p) => p.isActive);
    } catch (_) {
      return null;
    }
  }

  Future<void> save(ProgramModel program) async {
    _cache.removeWhere((p) => p.id == program.id);
    _cache.add(program);
    await _persistCache();

    try {
      await SupabaseService.client
          .from('programs')
          .upsert(program.toRow(SupabaseService.userId));
      await LocalCacheService.removePendingSync('programs', program.id);
    } catch (e) {
      debugPrint('[ProgramRepo] offline save — queued: $e');
      await LocalCacheService.addPendingSync({
        'table': 'programs',
        'op': 'upsert',
        'id': program.id,
        'data': program.toRow(SupabaseService.userId),
      });
    }
  }

  Future<void> setActive(String id) async {
    for (final p in _cache.where((p) => p.isActive && p.id != id).toList()) {
      await save(p.copyWith(isActive: false));
    }
    final target = getById(id);
    if (target != null) await save(target.copyWith(isActive: true));
  }

  Future<void> delete(String id) async {
    _cache.removeWhere((p) => p.id == id);
    await _persistCache();

    try {
      await SupabaseService.client.from('programs').delete().eq('id', id);
      await LocalCacheService.removePendingSync('programs', id);
    } catch (e) {
      debugPrint('[ProgramRepo] offline delete — queued: $e');
      await LocalCacheService.addPendingSync({
        'table': 'programs',
        'op': 'delete',
        'id': id,
        'data': {},
      });
    }
  }

  /// Re-fetches programs from Supabase and updates the local cache.
  /// Falls back silently when offline.
  Future<void> fetchFromRemote() async {
    await _flushPending();
    try {
      final data = await SupabaseService.client
          .from('programs')
          .select()
          .eq('user_id', SupabaseService.userId)
          .order('created_at');
      _cache = (data as List)
          .map((r) => ProgramModel.fromRow(r as Map<String, dynamic>))
          .toList();
      await _persistCache();
    } catch (e) {
      debugPrint('[ProgramRepo] fetchFromRemote failed (offline?): $e');
    }
  }

  Future<void> advanceDay(String programId) async {
    final program = getById(programId);
    if (program == null) return;
    final nextIndex = (program.currentDayIndex + 1) % program.days.length;
    await save(program.copyWith(currentDayIndex: nextIndex));
  }

  /// Roll the program back so [dayName] becomes the current (next) day.
  /// Called when a session for that day is deleted from history.
  Future<void> revertToDay(String programId, String dayName) async {
    final program = getById(programId);
    if (program == null || program.days.isEmpty) return;
    final idx = program.days.indexWhere(
      (d) => d.name.trim().toLowerCase() == dayName.trim().toLowerCase(),
    );
    if (idx == -1) return; // day not found in this program
    await save(program.copyWith(currentDayIndex: idx));
  }
}
