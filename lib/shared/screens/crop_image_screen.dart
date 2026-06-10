import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_colors.dart';

class CropImageScreen extends StatefulWidget {
  final XFile file;
  final double? aspectRatio;
  final bool withCircleUi;
  final Uint8List? preloadedBytes;

  const CropImageScreen({
    super.key,
    required this.file,
    this.aspectRatio,
    this.withCircleUi = false,
    this.preloadedBytes,
  });

  @override
  State<CropImageScreen> createState() => _CropImageScreenState();
}

class _CropImageScreenState extends State<CropImageScreen> {
  final _controller = CropController();
  Uint8List? _imageData;
  bool _cropping = false;

  @override
  void initState() {
    super.initState();
    if (widget.preloadedBytes != null) {
      _imageData = widget.preloadedBytes;
    } else {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    final bytes = await widget.file.readAsBytes();
    if (mounted) setState(() => _imageData = bytes);
  }

  void _doCrop() {
    setState(() => _cropping = true);
    _controller.crop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text('Crop Photo',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context, null),
          tooltip: 'Cancel',
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: (_cropping || _imageData == null) ? null : _doCrop,
              child: _cropping
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white))
                  : const Text('Done',
                      style: TextStyle(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.w700,
                          fontSize: 16)),
            ),
          ),
        ],
      ),
      body: _imageData == null
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Crop(
              image: _imageData!,
              controller: _controller,
              onCropped: (croppedBytes) => Navigator.pop(context, croppedBytes),
              aspectRatio: widget.aspectRatio,
              withCircleUi: widget.withCircleUi,
              maskColor: Colors.black54,
            ),
    );
  }
}
