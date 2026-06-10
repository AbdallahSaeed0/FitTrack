import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../data/models/github_release_model.dart';

class UpdateService {
  // ⚠️  Replace with your GitHub username/repo before publishing
  static const String githubRepo = 'AbdallahSaeed0/FitTrack';
  static const String _apiUrl =
      'https://api.github.com/repos/$githubRepo/releases/latest';

  final Dio _dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 8)));

  /// Returns the latest [GitHubRelease] if it is newer than the installed
  /// version, or `null` when the app is already up-to-date.
  ///
  /// Set [throwOnError] to `true` when the user manually triggered the check
  /// so they see a real error message instead of a silent "up-to-date".
  Future<GitHubRelease?> checkForUpdates({bool throwOnError = false}) async {
    try {
      final info = await PackageInfo.fromPlatform();
      // info.version is already "1.0.2" (no build suffix), but strip just in case
      final currentVersion = info.version.split('+').first;

      final response = await _dio.get<Map<String, dynamic>>(_apiUrl);
      if (response.statusCode == 200 && response.data != null) {
        final release = GitHubRelease.fromJson(response.data!);
        if (release.isNewerThan(currentVersion)) return release;
      }
    } catch (e) {
      if (throwOnError) rethrow;
      // Silent failure for the background auto-check on startup
    }
    return null;
  }

  /// Current app version string, e.g. "1.0.0 (Build 1)".
  static Future<String> currentVersionLabel() async {
    final info = await PackageInfo.fromPlatform();
    return '${info.version} (Build ${info.buildNumber})';
  }
}
