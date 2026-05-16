import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/github_release_model.dart';
import '../../core/services/update_service.dart';

class UpdateDialog extends StatelessWidget {
  final GitHubRelease release;

  const UpdateDialog({super.key, required this.release});

  @override
  Widget build(BuildContext context) {
    final notes = release.body.trim().isNotEmpty
        ? release.body.trim()
        : 'Bug fixes and performance improvements.';

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.activeDark.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.system_update_rounded, color: AppColors.activeDark, size: 22),
          ),
          const SizedBox(width: 12),
          const Text('Update Available'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Version badge
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.activeDark.withAlpha(15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.activeDark.withAlpha(60)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('New Version',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  Text(
                    release.version,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: AppColors.activeDark,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text("What's New",
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(notes,
                  style: const TextStyle(fontSize: 13, height: 1.5)),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Later'),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.download_rounded, size: 18),
          label: const Text('Update Now'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.activeDark,
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            Navigator.pop(context);
            _handleUpdate();
          },
        ),
      ],
    );
  }

  Future<void> _handleUpdate() async {
    Uri url;
    if (Platform.isAndroid && release.downloadUrl.isNotEmpty) {
      // Direct APK download — browser will handle install prompt
      url = Uri.parse(release.downloadUrl);
    } else {
      // iOS / other: open GitHub releases page
      url = Uri.parse(
          'https://github.com/${UpdateService.githubRepo}/releases/latest');
    }
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}
