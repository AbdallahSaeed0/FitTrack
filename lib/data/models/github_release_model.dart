class GitHubRelease {
  final String version;
  final String tagName;
  final String name;
  final String body;
  final String publishedAt;
  final String downloadUrl;

  const GitHubRelease({
    required this.version,
    required this.tagName,
    required this.name,
    required this.body,
    required this.publishedAt,
    required this.downloadUrl,
  });

  factory GitHubRelease.fromJson(Map<String, dynamic> json) {
    final assets = json['assets'] as List<dynamic>? ?? [];
    final apkAsset = assets.cast<Map<String, dynamic>?>().firstWhere(
      (a) => a != null && (a['name'] as String? ?? '').endsWith('.apk'),
      orElse: () => null,
    );

    final tagName = json['tag_name'] as String? ?? '';
    // Strip leading 'v' and build suffix: "v1.2.3+4" → "1.2.3"
    final version = tagName
        .replaceFirst(RegExp(r'^[vV]'), '')
        .split('+')
        .first;

    return GitHubRelease(
      version: version,
      tagName: tagName,
      name: json['name'] as String? ?? '',
      body: json['body'] as String? ?? '',
      publishedAt: json['published_at'] as String? ?? '',
      downloadUrl: apkAsset?['browser_download_url'] as String? ?? '',
    );
  }

  /// Compares semver strings: "1.2.3" > "1.2.2" → true.
  /// Works with standard GitHub tag formats (v1.0.0, v1.2.3, etc.)
  bool isNewerThan(String currentVersion) {
    final remote = _parseVersion(version);
    final current = _parseVersion(currentVersion);
    for (int i = 0; i < 3; i++) {
      if (remote[i] > current[i]) return true;
      if (remote[i] < current[i]) return false;
    }
    return false;
  }

  static List<int> _parseVersion(String v) {
    // Strip leading 'v' and build metadata (e.g. "+3"), then split on '.'
    final clean = v
        .replaceFirst(RegExp(r'^[vV]'), '')
        .split('+')
        .first
        .split('.');
    return List.generate(
        3, (i) => i < clean.length ? (int.tryParse(clean[i]) ?? 0) : 0);
  }
}
