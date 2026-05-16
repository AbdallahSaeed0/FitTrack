import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/hive_service.dart';

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final val = HiveService.settings.get('themeMode', defaultValue: 'system');
    return _fromString(val as String);
  }

  Future<void> setMode(ThemeMode mode) async {
    await HiveService.settings.put('themeMode', _toString(mode));
    state = mode;
  }

  static ThemeMode _fromString(String s) => switch (s) {
        'dark' => ThemeMode.dark,
        'light' => ThemeMode.light,
        _ => ThemeMode.system,
      };

  static String _toString(ThemeMode m) => switch (m) {
        ThemeMode.dark => 'dark',
        ThemeMode.light => 'light',
        _ => 'system',
      };
}
