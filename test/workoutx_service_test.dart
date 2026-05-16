import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Mirrors the private WorkoutXService._simplifyName logic so we can test it
// without exposing internals.
// ---------------------------------------------------------------------------
String _simplifyName(String name) {
  final dashIdx = name.indexOf(' - ');
  if (dashIdx > 0) return name.substring(0, dashIdx).trim();
  final parenIdx = name.indexOf(' (');
  if (parenIdx > 0) return name.substring(0, parenIdx).trim();
  return name.trim();
}

// Mirrors WorkoutXService._extractGif and helpers.
Map<String, dynamic> _asMap(dynamic item) {
  if (item is Map<String, dynamic>) return item;
  if (item is Map) return item.map((k, v) => MapEntry(k.toString(), v));
  return {};
}

String? _gifFromMap(Map<String, dynamic> item) {
  for (final field in [
    'gifUrl', 'gif_url', 'gif', 'animatedUrl', 'animated_url',
    'imageUrl', 'image_url',
  ]) {
    final v = item[field];
    if (v is String && v.isNotEmpty) return v;
  }
  return null;
}

String? _extractGif(dynamic data) {
  if (data == null) return null;
  if (data is List) {
    if (data.isEmpty) return null;
    return _gifFromMap(_asMap(data.first));
  }
  if (data is Map) {
    final map = _asMap(data);
    if (map['data'] is List) {
      final list = map['data'] as List;
      if (list.isEmpty) return null;
      return _gifFromMap(_asMap(list.first));
    }
    return _gifFromMap(map);
  }
  return null;
}

bool _isWorkoutXUrl(String url) => url.contains('workoutxapp.com');

void main() {
  // ── Name simplification ──────────────────────────────────────────────────
  group('_simplifyName', () {
    test('strips " - Variant" suffix', () {
      expect(_simplifyName('Barbell Bench Press - Medium Grip'),
          'Barbell Bench Press');
      expect(_simplifyName('Close-Grip Front Lat Pulldown - Wide Grip'),
          'Close-Grip Front Lat Pulldown');
      expect(_simplifyName('Romanian Deadlift - With Bands'),
          'Romanian Deadlift');
    });

    test('strips " (Variant)" suffix', () {
      expect(_simplifyName('Assisted Chest Dip (kneeling)'),
          'Assisted Chest Dip');
      expect(_simplifyName('Romanian Deadlift (Barbell)'),
          'Romanian Deadlift');
    });

    test('leaves plain names unchanged', () {
      expect(_simplifyName('Romanian Deadlift'), 'Romanian Deadlift');
      expect(_simplifyName('Barbell Squat'), 'Barbell Squat');
      expect(_simplifyName('Jumping Jacks'), 'Jumping Jacks');
    });

    test('trims surrounding whitespace', () {
      expect(_simplifyName('  Bench Press  '), 'Bench Press');
    });
  });

  // ── Response parsing ─────────────────────────────────────────────────────
  group('_extractGif — response parsing', () {
    test('parses actual WorkoutX wrapped response', () {
      // This is the exact shape the WorkoutX API returns.
      final response = {
        'total': 1324,
        'count': 10,
        'data': [
          {
            'id': '0001',
            'name': '3/4 Sit-up',
            'gifUrl': 'https://api.workoutxapp.com/v1/gifs/0001.gif',
          },
        ],
      };
      expect(
        _extractGif(response),
        'https://api.workoutxapp.com/v1/gifs/0001.gif',
      );
    });

    test('returns null when data array is empty', () {
      final response = {'total': 0, 'count': 0, 'data': []};
      expect(_extractGif(response), isNull);
    });

    test('parses direct array response', () {
      final response = [
        {'gifUrl': 'https://api.workoutxapp.com/v1/gifs/0001.gif'},
      ];
      expect(
        _extractGif(response),
        'https://api.workoutxapp.com/v1/gifs/0001.gif',
      );
    });

    test('handles Map<dynamic,dynamic> (Dio runtime type)', () {
      // Dio can return Map<dynamic,dynamic> at runtime even when typed as JSON.
      final response = <dynamic, dynamic>{
        'data': <dynamic>[
          <dynamic, dynamic>{
            'gifUrl': 'https://api.workoutxapp.com/v1/gifs/0002.gif',
          },
        ],
      };
      expect(
        _extractGif(response),
        'https://api.workoutxapp.com/v1/gifs/0002.gif',
      );
    });

    test('returns null for null input', () {
      expect(_extractGif(null), isNull);
    });
  });

  // ── URL authentication check ─────────────────────────────────────────────
  group('WorkoutX URL detection', () {
    test('WorkoutX GIF URLs require auth headers', () {
      // GIF endpoint lives on the same domain as the API — same auth rules.
      const gifUrl = 'https://api.workoutxapp.com/v1/gifs/0001.gif';
      expect(_isWorkoutXUrl(gifUrl), isTrue,
          reason: 'Must send X-WorkoutX-Key header when loading this image');
    });

    test('free-exercise-db URLs do NOT need auth headers', () {
      const staticUrl =
          'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/Barbell_Squat/0.jpg';
      expect(_isWorkoutXUrl(staticUrl), isFalse);
    });
  });
}
