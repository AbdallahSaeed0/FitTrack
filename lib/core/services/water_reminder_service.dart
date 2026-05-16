import 'dart:async';

/// In-app water reminder using a periodic timer.
/// When the app is foregrounded, shows a SnackBar every 10 minutes.
/// For background notifications, platform setup for flutter_local_notifications is required.
class WaterReminderService {
  static final WaterReminderService _instance = WaterReminderService._internal();
  factory WaterReminderService() => _instance;
  WaterReminderService._internal();

  Timer? _timer;
  bool _isEnabled = true;
  void Function()? _onReminder;

  void initialize({required void Function() onReminder}) {
    _onReminder = onReminder;
  }

  void startReminders() {
    if (_timer != null) return;
    _timer = Timer.periodic(const Duration(minutes: 10), (_) {
      if (_isEnabled) _onReminder?.call();
    });
  }

  void stopReminders() {
    _timer?.cancel();
    _timer = null;
  }

  void toggleReminders(bool enabled) {
    _isEnabled = enabled;
    if (enabled) {
      startReminders();
    } else {
      stopReminders();
    }
  }

  bool get isEnabled => _isEnabled;

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}
