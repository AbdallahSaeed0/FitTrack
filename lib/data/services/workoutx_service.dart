import 'package:dio/dio.dart';

class WorkoutXService {
  static const _base = 'https://api.workoutxapp.com/v1';

  // Session-level cache: simplified exercise name → gif URL (or null on miss).
  // Caching null avoids retrying a failed lookup this session.
  static final Map<String, String?> _cache = {};

  final Dio _dio;
  final String? _apiKey;

  WorkoutXService({String? apiKey})
      : _apiKey = apiKey?.isNotEmpty == true ? apiKey : null,
        _dio = Dio(BaseOptions(
          baseUrl: _base,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ));

  bool get hasApiKey => _apiKey != null;

  /// Returns the animated GIF URL for [exerciseName].
  /// Strips descriptors like " - Medium Grip" or " (Barbell)" before querying
  /// so partial names match the WorkoutX catalogue.
  /// Result is cached for the session — the same name is never requested twice.
  Future<String?> getExerciseGif(String exerciseName) async {
    if (!hasApiKey) return null;

    final simplified = _simplifyName(exerciseName);
    final cacheKey = simplified.toLowerCase();

    if (_cache.containsKey(cacheKey)) return _cache[cacheKey];

    try {
      final response = await _dio.get<dynamic>(
        '/exercises/name/${Uri.encodeComponent(cacheKey)}',
        options: Options(headers: {'X-WorkoutX-Key': _apiKey}),
      );

      final gif = _extractGif(response.data);
      _cache[cacheKey] = gif;
      return gif;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      // Cache definitive server responses (404 = not in WorkoutX, 401/403 = bad key).
      // Do NOT cache network errors (null status = timeout/no connection) so the
      // next open can retry when connectivity is restored.
      if (status != null) {
        _cache[cacheKey] = null;
        if (status != 404) {
          // ignore: avoid_print
          print('[WorkoutX] HTTP $status for "$simplified"');
        }
      }
      return null;
    } catch (_) {
      // Unexpected error — don't cache, allow retry.
      return null;
    }
  }

  /// Returns exercises by body part, or empty list on failure.
  Future<List<Map<String, dynamic>>> getExercisesByBodyPart(
      String bodyPart) async {
    if (!hasApiKey) return [];
    try {
      final response = await _dio.get<dynamic>(
        '/exercises/bodyPart/${bodyPart.toLowerCase()}',
        options: Options(headers: {'X-WorkoutX-Key': _apiKey}),
      );
      return _toMapList(response.data);
    } catch (_) {
      return [];
    }
  }

  // ── Parsing helpers ────────────────────────────────────────────────────────

  /// Strips common name qualifiers so "Barbell Bench Press - Medium Grip"
  /// becomes "Barbell Bench Press" before hitting the API.
  static String _simplifyName(String name) {
    // Remove " - Variant" suffix (e.g. " - Medium Grip", " - With Bands")
    final dashIdx = name.indexOf(' - ');
    if (dashIdx > 0) return name.substring(0, dashIdx).trim();
    // Remove " (Variant)" suffix (e.g. " (Barbell)", " (kneeling)")
    final parenIdx = name.indexOf(' (');
    if (parenIdx > 0) return name.substring(0, parenIdx).trim();
    return name.trim();
  }

  /// Handles the actual response shape:
  ///   { "total": N, "count": N, "data": [ { "gifUrl": "..." }, ... ] }
  static String? _extractGif(dynamic data) {
    if (data == null) return null;

    // Direct list (fallback for APIs that don't wrap)
    if (data is List) {
      if (data.isEmpty) return null;
      return _gifFromMap(_asMap(data.first));
    }

    if (data is Map) {
      final map = _asMap(data);
      // Standard wrapped format: { "data": [...] }
      if (map['data'] is List) {
        final list = map['data'] as List;
        if (list.isEmpty) return null;
        return _gifFromMap(_asMap(list.first));
      }
      // Single object response
      return _gifFromMap(map);
    }

    return null;
  }

  /// Safely converts any Map to Map<String, dynamic>.
  static Map<String, dynamic> _asMap(dynamic item) {
    if (item is Map<String, dynamic>) return item;
    if (item is Map) return item.map((k, v) => MapEntry(k.toString(), v));
    return {};
  }

  /// Extracts the GIF URL, trying the most common field names in order.
  static String? _gifFromMap(Map<String, dynamic> item) {
    for (final field in [
      'gifUrl',
      'gif_url',
      'gif',
      'animatedUrl',
      'animated_url',
      'imageUrl',
      'image_url',
    ]) {
      final v = item[field];
      if (v is String && v.isNotEmpty) return v;
    }
    return null;
  }

  static List<Map<String, dynamic>> _toMapList(dynamic data) {
    List<dynamic> raw = [];
    if (data is List) {
      raw = data;
    } else if (data is Map) {
      final map = _asMap(data);
      if (map['data'] is List) raw = map['data'] as List;
    }
    return raw.map(_asMap).where((m) => m.isNotEmpty).toList();
  }
}
