class GitHubRelease {
  final String version;
  final String tagName;
  final String name;
  final String body;
  final String publishedAt;
  final String downloadUrl;
  final int buildNumber;

  const GitHubRelease({
    required this.version,
    required this.tagName,
    required this.name,
    required this.body,
    required this.publishedAt,
    required this.downloadUrl,
    required this.buildNumber,
  });

  factory GitHubRelease.fromJson(Map<String, dynamic> json) {
    final assets = json['assets'] as List<dynamic>? ?? [];
    final apkAsset = assets.cast<Map<String, dynamic>?>().firstWhere(
      (a) => a != null && (a['name'] as String? ?? '').endsWith('.apk'),
      orElse: () => null,
    );

    final tagName = json['tag_name'] as String? ?? '';
    final version = tagName.replaceFirst('v', '');
    final buildNumber = _parseBuild(json['name'] as String? ?? tagName);

    return GitHubRelease(
      version: version,
      tagName: tagName,
      name: json['name'] as String? ?? '',
      body: json['body'] as String? ?? '',
      publishedAt: json['published_at'] as String? ?? '',
      downloadUrl: apkAsset?['browser_download_url'] as String? ?? '',
      buildNumber: buildNumber,
    );
  }

  static int _parseBuild(String text) {
    // "FitTrack v1.0.1 (Build 2)" → 2
    final m = RegExp(r'[Bb]uild\s+(\d+)').firstMatch(text);
    if (m != null) return int.tryParse(m.group(1) ?? '') ?? 0;
    // Fallback: parse patch version as build indicator
    final parts = text.replaceFirst('v', '').split('.');
    return parts.length >= 3 ? (int.tryParse(parts[2]) ?? 0) : 0;
  }

  bool isNewerThan(int currentBuild) => buildNumber > currentBuild;
}
