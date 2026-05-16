import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/user_profile_model.dart';
import '../../data/services/hive_service.dart';

class UserProfileNotifier extends Notifier<UserProfileModel> {
  @override
  UserProfileModel build() {
    final box = HiveService.userProfile;
    if (box.isEmpty) {
      final profile = UserProfileModel();
      box.put('profile', profile);
      return profile;
    }
    return box.get('profile') ?? UserProfileModel();
  }

  Future<void> update(UserProfileModel profile) async {
    await HiveService.userProfile.put('profile', profile);
    state = profile;
  }

  Future<void> markOnboarded() async {
    final updated = state.copyWith(isFirstLaunch: false);
    await HiveService.userProfile.put('profile', updated);
    state = updated;
  }
}

final userProfileProvider = NotifierProvider<UserProfileNotifier, UserProfileModel>(
  UserProfileNotifier.new,
);
