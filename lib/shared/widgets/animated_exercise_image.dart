import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import 'fullscreen_image_viewer.dart';

class AnimatedExerciseImage extends StatefulWidget {
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
  State<AnimatedExerciseImage> createState() => _AnimatedExerciseImageState();
}

class _AnimatedExerciseImageState extends State<AnimatedExerciseImage> {
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

  bool _isLocal(String url) => url.startsWith('assets/');

  void _openFullScreen(BuildContext context, String url) {
    if (!widget.enableFullScreen) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullScreenImageViewer(
          imageUrl: url,
          title: widget.fullScreenTitle,
        ),
      ),
    );
  }

  Widget _buildItem(String url) {
    if (_isLocal(url)) {
      return Image.asset(
        url,
        height: widget.height,
        width: double.infinity,
        fit: widget.fit,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }
    if (kIsWeb) {
      return Image.network(
        url,
        height: widget.height,
        width: double.infinity,
        fit: widget.fit,
        loadingBuilder: (_, child, progress) =>
            progress == null ? child : _shimmer(),
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      height: widget.height,
      width: double.infinity,
      fit: widget.fit,
      placeholder: (_, __) => _shimmer(),
      errorWidget: (_, __, ___) => _placeholder(),
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
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                dragDevices: {
                  PointerDeviceKind.touch,
                  PointerDeviceKind.mouse,
                },
              ),
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
                        _buildItem(url),
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
