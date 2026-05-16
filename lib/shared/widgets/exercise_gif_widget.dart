import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import 'fullscreen_image_viewer.dart';

/// Thumbnail widget for exercises in lists and cards.
/// Tap to open a full-screen pinch-to-zoom viewer (when [enableFullScreen] is true).
class ExerciseGifWidget extends StatelessWidget {
  final String gifUrl;
  final String exerciseName;
  final double width;
  final double height;
  final double borderRadius;
  final bool enableFullScreen;

  const ExerciseGifWidget({
    super.key,
    required this.gifUrl,
    this.exerciseName = '',
    this.width = 52,
    this.height = 52,
    this.borderRadius = 8,
    this.enableFullScreen = false,
  });

  @override
  Widget build(BuildContext context) {
    if (gifUrl.isEmpty) return _fallback();

    final image = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: CachedNetworkImage(
        imageUrl: gifUrl,
        width: width,
        height: height,
        fit: BoxFit.cover,
        placeholder: (_, __) => _shimmer(),
        errorWidget: (_, __, ___) => _fallback(),
      ),
    );

    if (!enableFullScreen) return image;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FullScreenImageViewer(
            imageUrl: gifUrl,
            title: exerciseName,
          ),
        ),
      ),
      child: image,
    );
  }

  Widget _shimmer() => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.mediumGray.withAlpha(60),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ).animate(onPlay: (c) => c.repeat()).shimmer(
            duration: 1200.ms,
            color: Colors.white.withAlpha(120),
          );

  Widget _fallback() => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.accentTeal.withAlpha(20),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Center(
          child: Icon(
            Icons.fitness_center_rounded,
            color: AppColors.accentTeal,
            size: width * 0.46,
          ),
        ),
      );
}
