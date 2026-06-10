import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local cache backed by SharedPreferences — Android/iOS only.
/// All methods are no-ops on web (kIsWeb == true).
class LocalCacheService {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    if (kIsWeb) return;
    _prefs = await SharedPreferences.getInstance();
  }

  // ── Generic helpers ──────────────────────────────────────────────────────

  static List<Map<String, dynamic>> _getList(String key) {
    if (kIsWeb || _prefs == null) return [];
    final raw = _prefs!.getString(key);
    if (raw == null) return [];
    try {
      return List<Map<String, dynamic>>.from(
          jsonDecode(raw) as List);
    } catch (_) {
      return [];
    }
  }

  static Future<void> _setList(
      String key, List<Map<String, dynamic>> data) async {
    if (kIsWeb || _prefs == null) return;
    await _prefs!.setString(key, jsonEncode(data));
  }

  static Map<String, dynamic>? _getMap(String key) {
    if (kIsWeb || _prefs == null) return null;
    final raw = _prefs!.getString(key);
    if (raw == null) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return null;
    }
  }

  static Future<void> _setMap(
      String key, Map<String, dynamic> data) async {
    if (kIsWeb || _prefs == null) return;
    await _prefs!.setString(key, jsonEncode(data));
  }

  // ── Programs ─────────────────────────────────────────────────────────────

  static List<Map<String, dynamic>> getPrograms() => _getList('cache_programs');

  static Future<void> savePrograms(List<Map<String, dynamic>> data) =>
      _setList('cache_programs', data);

  // ── Sessions ─────────────────────────────────────────────────────────────

  static List<Map<String, dynamic>> getSessions() => _getList('cache_sessions');

  static Future<void> saveSessions(List<Map<String, dynamic>> data) =>
      _setList('cache_sessions', data);

  // ── Meal logs ────────────────────────────────────────────────────────────

  static List<Map<String, dynamic>> getMealLogs() =>
      _getList('cache_meal_logs');

  static Future<void> saveMealLogs(List<Map<String, dynamic>> data) =>
      _setList('cache_meal_logs', data);

  // ── Profile ──────────────────────────────────────────────────────────────

  static Map<String, dynamic>? getProfile() => _getMap('cache_profile');

  static Future<void> saveProfile(Map<String, dynamic> data) =>
      _setMap('cache_profile', data);

  // ── Pending sync queue ───────────────────────────────────────────────────
  // Each entry: { 'table': String, 'op': 'upsert'|'delete', 'data': Map, 'id': String }

  static List<Map<String, dynamic>> getPendingSync() =>
      _getList('pending_sync');

  static Future<void> addPendingSync(Map<String, dynamic> entry) async {
    if (kIsWeb) return;
    final queue = getPendingSync();
    // Replace existing entry for same table+id to avoid duplicates
    queue.removeWhere(
        (e) => e['table'] == entry['table'] && e['id'] == entry['id']);
    queue.add(entry);
    await _setList('pending_sync', queue);
  }

  static Future<void> removePendingSync(String table, String id) async {
    if (kIsWeb) return;
    final queue = getPendingSync()
      ..removeWhere((e) => e['table'] == table && e['id'] == id);
    await _setList('pending_sync', queue);
  }

  static Future<void> clearPendingSync() async {
    if (kIsWeb) return;
    await _prefs?.remove('pending_sync');
  }
}
