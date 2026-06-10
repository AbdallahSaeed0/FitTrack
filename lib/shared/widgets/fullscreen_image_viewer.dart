import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;
  final String title;
  final Map<String, String>? httpHeaders;

  const FullScreenImageViewer({
    super.key,
    required this.imageUrl,
    this.title = '',
    this.httpHeaders,
  });

  bool get _isLocal => imageUrl.startsWith('assets/');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(title, style: const TextStyle(fontSize: 16)),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 5.0,
          child: _isLocal ? _localImage() : _networkImage(),
        ),
      ),
    );
  }

  Widget _localImage() => Image.asset(
        imageUrl,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Center(
          child: Icon(Icons.broken_image_rounded,
              size: 64, color: Colors.white38),
        ),
      );

  Widget _networkImage() {
    if (kIsWeb) {
      return Image.network(
        imageUrl,
        fit: BoxFit.contain,
        loadingBuilder: (_, child, progress) => progress == null
            ? child
            : const Center(
                child: CircularProgressIndicator(color: Colors.white)),
        errorBuilder: (_, __, ___) => const Center(
          child: Icon(Icons.broken_image_rounded,
              size: 64, color: Colors.white38),
        ),
      );
    }
    return CachedNetworkImage(
      imageUrl: imageUrl,
      httpHeaders: httpHeaders,
      fit: BoxFit.contain,
      placeholder: (_, __) =>
          const Center(child: CircularProgressIndicator(color: Colors.white)),
      errorWidget: (_, __, ___) => const Center(
        child: Icon(Icons.broken_image_rounded,
            size: 64, color: Colors.white38),
      ),
    );
  }
}
