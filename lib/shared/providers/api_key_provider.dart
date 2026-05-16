import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/hive_service.dart';

class ApiKeyNotifier extends Notifier<String> {
  static const _key = 'workoutx_api_key';

  @override
  String build() {
    return HiveService.settings.get(_key, defaultValue: '') as String;
  }

  Future<void> save(String key) async {
    await HiveService.settings.put(_key, key.trim());
    state = key.trim();
  }

  void clear() {
    HiveService.settings.delete(_key);
    state = '';
  }
}

final apiKeyProvider = NotifierProvider<ApiKeyNotifier, String>(ApiKeyNotifier.new);
