import 'package:flutter_riverpod/flutter_riverpod.dart';

class ApiKeyNotifier extends Notifier<String> {
  @override
  String build() => '';

  Future<void> save(String key) async {
    state = key.trim();
  }

  void clear() {
    state = '';
  }
}

final apiKeyProvider =
    NotifierProvider<ApiKeyNotifier, String>(ApiKeyNotifier.new);
