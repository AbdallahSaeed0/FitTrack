import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Used by any screen to request a shell tab change.
/// Write the target tab index (0–5); null means no pending request.
final shellTabProvider = StateProvider<int?>((ref) => null);
