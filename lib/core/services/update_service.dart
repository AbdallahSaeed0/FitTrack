import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../data/models/github_release_model.dart';

class UpdateService {
  // ⚠️  Replace with your GitHub username/repo before publishing
  static const String githubRepo = 'YOUR_USERNAME/fittrack';
  static const String _apiUrl =
      'https://api.github.com/repos/$githubRepo/releases/latest';

  final Dio _dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 8)));

  /// Returns the latest [GitHubRelease] if it is newer than the installed
  /// build, or `null` when the app is already up-to-date or the check fails.
  Future<GitHubRelease?> checkForUpdates() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final currentBuild = int.tryParse(info.buildNumber) ?? 0;

      final response = await _dio.get<Map<String, dynamic>>(_apiUrl);
      if (response.statusCode == 200 && response.data != null) {
        final release = GitHubRelease.fromJson(response.data!);
        if (release.isNewerThan(currentBuild)) return release;
      }
    } catch (_) {
      // Network unavailable or repo not set up — silently ignore
    }
    return null;
  }

  /// Current app version string, e.g. "1.0.0 (Build 1)".
  static Future<String> currentVersionLabel() async {
    final info = await PackageInfo.fromPlatform();
    return '${info.version} (Build ${info.buildNumber})';
  }
}
