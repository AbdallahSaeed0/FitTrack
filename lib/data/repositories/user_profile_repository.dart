import 'package:flutter/foundation.dart';
import '../models/user_profile_model.dart';
import '../../core/services/supabase_service.dart';
import '../../core/services/local_cache_service.dart';

class UserProfileRepository {
  static final UserProfileRepository instance = UserProfileRepository._();
  UserProfileRepository._();

  UserProfileModel _profile = UserProfileModel();

  Future<void> init() async {
    // 1. Load local cache immediately
    final local = LocalCacheService.getProfile();
    if (local != null) {
      _profile = UserProfileModel.fromRow(local);
    }

    // 2. Fetch from Supabase.
    // avatar_url is stored in Supabase (uploaded via Storage).
    // photo_path is a device-local fallback kept only in local cache.
    // If Supabase has avatar_url, it wins; otherwise keep whatever the local
    // cache has so native users don't lose their photo offline.
    try {
      final data = await SupabaseService.client
          .from('profiles')
          .select()
          .eq('id', SupabaseService.userId)
          .maybeSingle();
      if (data != null) {
        final remoteProfile = UserProfileModel.fromRow(data);
        // Prefer remote avatar_url; fall back to locally-cached path.
        final resolvedPhoto = (remoteProfile.photoPath != null && remoteProfile.photoPath!.isNotEmpty)
            ? remoteProfile.photoPath
            : _profile.photoPath;
        _profile = remoteProfile.copyWith(photoPath: resolvedPhoto);
        await LocalCacheService.saveProfile(_profile.toRow());
      }
    } catch (e) {
      debugPrint('[ProfileRepo] offline — using local cache: $e');
    }
  }

  UserProfileModel get() => _profile;

  Future<void> save(UserProfileModel profile) async {
    _profile = profile;
    await LocalCacheService.saveProfile(profile.toRow());

    try {
      await SupabaseService.client
          .from('profiles')
          .update(profile.toSupabaseRow())
          .eq('id', SupabaseService.userId);
    } catch (e) {
      debugPrint('[ProfileRepo] offline save — will sync on next launch: $e');
    }
  }
}
