import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/user_profile_model.dart';
import '../../data/repositories/user_profile_repository.dart';

class UserProfileNotifier extends Notifier<UserProfileModel> {
  @override
  UserProfileModel build() => UserProfileRepository.instance.get();

  Future<void> update(UserProfileModel profile) async {
    await UserProfileRepository.instance.save(profile);
    state = profile;
  }

  Future<void> markOnboarded() async {
    final updated = state.copyWith(isFirstLaunch: false);
    await UserProfileRepository.instance.save(updated);
    state = updated;
  }
}

final userProfileProvider =
    NotifierProvider<UserProfileNotifier, UserProfileModel>(
  UserProfileNotifier.new,
);
