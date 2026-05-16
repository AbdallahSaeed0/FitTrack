import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/providers/api_key_provider.dart';
import 'fullscreen_image_viewer.dart';

/// Displays exercise images as a swipeable PageView.
/// Tap any image to open a full-screen pinch-to-zoom viewer.
class AnimatedExerciseImage extends ConsumerStatefulWidget {
  final List<String> imageUrls;
  final double height;
  final BoxFit fit;
  final bool enableFullScreen;
  final String fullScreenTitle;

  const AnimatedExerciseImage({
    super.key,
    required this.imageUrls,
    this.height = 260,
    this.fit = BoxFit.contain,
    this.enableFullScreen = true,
    this.fullScreenTitle = '',
  });

  @override
  ConsumerState<AnimatedExerciseImage> createState() =>
      _AnimatedExerciseImageState();
}

class _AnimatedExerciseImageState extends ConsumerState<AnimatedExerciseImage> {
  late final PageController _pageController;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Map<String, String>? _headersFor(String url) {
    if (!url.contains('workoutxapp.com')) return null;
    final key = ref.read(apiKeyProvider);
    if (key.isEmpty) return null;
    return {'X-WorkoutX-Key': key};
  }

  void _openFullScreen(BuildContext context, String url) {
    if (!widget.enableFullScreen) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullScreenImageViewer(
          imageUrl: url,
          title: widget.fullScreenTitle,
          httpHeaders: _headersFor(url),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrls.isEmpty) return _placeholder();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: widget.height,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (i) => setState(() => _index = i),
              itemCount: widget.imageUrls.length,
              itemBuilder: (_, i) {
                final url = widget.imageUrls[i];
                return GestureDetector(
                  onTap: () => _openFullScreen(context, url),
                  child: Stack(
                    children: [
                      CachedNetworkImage(
                        imageUrl: url,
                        httpHeaders: _headersFor(url),
                        height: widget.height,
                        width: double.infinity,
                        fit: widget.fit,
                        placeholder: (_, __) => _shimmer(),
                        errorWidget: (_, __, ___) => _placeholder(),
                      ),
                      if (widget.enableFullScreen)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha(100),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.fullscreen_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        if (widget.imageUrls.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.imageUrls.length, (i) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _index == i ? 18 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: _index == i
                        ? AppColors.activeDark
                        : AppColors.inactiveDark.withAlpha(120),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }

  Widget _shimmer() => Container(
        height: widget.height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.mediumGray.withAlpha(60),
          borderRadius: BorderRadius.circular(12),
        ),
      ).animate(onPlay: (c) => c.repeat()).shimmer(
            duration: 1200.ms,
            color: Colors.white.withAlpha(100),
          );

  Widget _placeholder() => Container(
        height: widget.height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.accentTeal.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Icon(
            Icons.fitness_center_rounded,
            size: 64,
            color: AppColors.accentTeal,
          ),
        ),
      );
}
