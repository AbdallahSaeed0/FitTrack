import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kPremiumKey = 'is_premium';

class PremiumNotifier extends Notifier<bool> {
  @override
  bool build() {
    Future.microtask(_load);
    return false;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_kPremiumKey) ?? false;
  }

  Future<void> setPremium(bool value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kPremiumKey, value);
  }
}

final premiumProvider =
    NotifierProvider<PremiumNotifier, bool>(PremiumNotifier.new);
