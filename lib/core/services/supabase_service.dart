import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static const _url = 'https://cekgrxnevwhfpissnlwc.supabase.co';
  static const _anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNla2dyeG5ldndoZnBpc3NubHdjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg5NjYyMjcsImV4cCI6MjA5NDU0MjIyN30.xCHqUBn0xnGqqP2f10drIH1l4UvtUIQgR1tKgrlUjJw';

  static Future<void> init() async {
    await Supabase.initialize(url: _url, anonKey: _anonKey);
  }

  static SupabaseClient get client => Supabase.instance.client;

  static User? get currentUser => client.auth.currentUser;

  static String get userId => currentUser!.id;

  static bool get isLoggedIn => currentUser != null;
}
