import 'package:flutter/material.dart';
import '../../data/models/muscle_groups.dart';
import '../../data/models/muscle_intensity_model.dart';

class MuscleHeatMap extends StatelessWidget {
  final List<MuscleIntensity> intensities;

  const MuscleHeatMap({super.key, required this.intensities});

  @override
  Widget build(BuildContext context) {
    final colorMap = {for (final i in intensities) i.muscle: i.color};
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: [
              Text(
                'Front',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              CustomPaint(
                size: const Size(150, 360),
                painter: _BodyPainter(colorMap: colorMap, viewType: 'front'),
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            children: [
              Text(
                'Back',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              CustomPaint(
                size: const Size(150, 360),
                painter: _BodyPainter(colorMap: colorMap, viewType: 'back'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BodyPainter extends CustomPainter {
  final Map<MuscleGroup, Color> colorMap;
  final String viewType;

  const _BodyPainter({required this.colorMap, required this.viewType});

  static const Color _skin = Color(0xFFCBD5E1);
  static const Color _outline = Color(0xFF78909C);
  static const Color _lineDivider = Color(0xFF90A4AE);

  Color _muscleColor(MuscleGroup muscle) => colorMap[muscle] ?? _skin;

  Paint get _basePaint => Paint()..color = _skin;
  Paint get _strokePaint => Paint()
    ..color = _outline
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.2;
  Paint get _dividerPaint => Paint()
    ..color = _lineDivider
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.8;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    _drawHead(canvas, w, h);
    _drawNeck(canvas, w, h);

    if (viewType == 'front') {
      _drawFrontBody(canvas, w, h);
    } else {
      _drawBackBody(canvas, w, h);
    }
  }

  // ── HEAD ──────────────────────────────────────────────────────────────────
  void _drawHead(Canvas canvas, double w, double h) {
    final path = Path();
    final cx = w * 0.5;
    final cy = h * 0.052;
    final rx = w * 0.13;
    final ry = h * 0.052;
    // Slightly wider jaw at bottom
    path.moveTo(cx, cy - ry);
    path.cubicTo(cx + rx * 1.1, cy - ry, cx + rx * 1.1, cy + ry * 0.6, cx + rx * 0.85, cy + ry);
    path.cubicTo(cx + rx * 0.5, cy + ry * 1.3, cx - rx * 0.5, cy + ry * 1.3, cx - rx * 0.85, cy + ry);
    path.cubicTo(cx - rx * 1.1, cy + ry * 0.6, cx - rx * 1.1, cy - ry, cx, cy - ry);
    path.close();
    canvas.drawPath(path, _basePaint);
    canvas.drawPath(path, _strokePaint);
  }

  // ── NECK ──────────────────────────────────────────────────────────────────
  void _drawNeck(Canvas canvas, double w, double h) {
    final path = Path();
    path.moveTo(w * 0.43, h * 0.1);
    path.cubicTo(w * 0.42, h * 0.105, w * 0.41, h * 0.13, w * 0.42, h * 0.138);
    path.lineTo(w * 0.58, h * 0.138);
    path.cubicTo(w * 0.59, h * 0.13, w * 0.58, h * 0.105, w * 0.57, h * 0.1);
    path.close();
    canvas.drawPath(path, _basePaint);
    canvas.drawPath(path, _strokePaint);
  }

  // ── FRONT BODY ────────────────────────────────────────────────────────────
  void _drawFrontBody(Canvas canvas, double w, double h) {
    // Draw base body silhouette first, then muscles on top
    _drawFrontSilhouette(canvas, w, h);
    _drawFrontMuscles(canvas, w, h);
  }

  void _drawFrontSilhouette(Canvas canvas, double w, double h) {
    // Left arm
    final leftArm = Path();
    leftArm.moveTo(w * 0.27, h * 0.145); // left shoulder top
    leftArm.cubicTo(w * 0.14, h * 0.14, w * 0.06, h * 0.17, w * 0.05, h * 0.21);
    leftArm.cubicTo(w * 0.03, h * 0.26, w * 0.03, h * 0.34, w * 0.05, h * 0.38);
    // forearm
    leftArm.cubicTo(w * 0.04, h * 0.42, w * 0.04, h * 0.5, w * 0.06, h * 0.52);
    // hand
    leftArm.cubicTo(w * 0.07, h * 0.53, w * 0.1, h * 0.545, w * 0.12, h * 0.54);
    leftArm.cubicTo(w * 0.14, h * 0.535, w * 0.15, h * 0.51, w * 0.15, h * 0.5);
    leftArm.cubicTo(w * 0.15, h * 0.45, w * 0.16, h * 0.38, w * 0.16, h * 0.345);
    leftArm.cubicTo(w * 0.2, h * 0.32, w * 0.23, h * 0.265, w * 0.27, h * 0.215);
    leftArm.close();
    canvas.drawPath(leftArm, _basePaint);
    canvas.drawPath(leftArm, _strokePaint);

    // Right arm (mirror)
    final rightArm = Path();
    rightArm.moveTo(w * 0.73, h * 0.145);
    rightArm.cubicTo(w * 0.86, h * 0.14, w * 0.94, h * 0.17, w * 0.95, h * 0.21);
    rightArm.cubicTo(w * 0.97, h * 0.26, w * 0.97, h * 0.34, w * 0.95, h * 0.38);
    rightArm.cubicTo(w * 0.96, h * 0.42, w * 0.96, h * 0.5, w * 0.94, h * 0.52);
    rightArm.cubicTo(w * 0.93, h * 0.53, w * 0.9, h * 0.545, w * 0.88, h * 0.54);
    rightArm.cubicTo(w * 0.86, h * 0.535, w * 0.85, h * 0.51, w * 0.85, h * 0.5);
    rightArm.cubicTo(w * 0.85, h * 0.45, w * 0.84, h * 0.38, w * 0.84, h * 0.345);
    rightArm.cubicTo(w * 0.8, h * 0.32, w * 0.77, h * 0.265, w * 0.73, h * 0.215);
    rightArm.close();
    canvas.drawPath(rightArm, _basePaint);
    canvas.drawPath(rightArm, _strokePaint);

    // Torso
    final torso = Path();
    torso.moveTo(w * 0.27, h * 0.138); // left shoulder
    // clavicle sweep left to center
    torso.cubicTo(w * 0.28, h * 0.14, w * 0.35, h * 0.148, w * 0.5, h * 0.148);
    torso.cubicTo(w * 0.65, h * 0.148, w * 0.72, h * 0.14, w * 0.73, h * 0.138);
    // right side down to hip
    torso.cubicTo(w * 0.79, h * 0.16, w * 0.82, h * 0.22, w * 0.80, h * 0.31);
    torso.cubicTo(w * 0.79, h * 0.36, w * 0.77, h * 0.38, w * 0.74, h * 0.4);
    torso.cubicTo(w * 0.73, h * 0.42, w * 0.72, h * 0.44, w * 0.73, h * 0.46);
    torso.cubicTo(w * 0.745, h * 0.475, w * 0.745, h * 0.49, w * 0.72, h * 0.50);
    torso.cubicTo(w * 0.68, h * 0.51, w * 0.60, h * 0.515, w * 0.5, h * 0.515);
    torso.cubicTo(w * 0.40, h * 0.515, w * 0.32, h * 0.51, w * 0.28, h * 0.50);
    torso.cubicTo(w * 0.255, h * 0.49, w * 0.255, h * 0.475, w * 0.27, h * 0.46);
    torso.cubicTo(w * 0.28, h * 0.44, w * 0.27, h * 0.42, w * 0.26, h * 0.4);
    torso.cubicTo(w * 0.23, h * 0.38, w * 0.21, h * 0.36, w * 0.20, h * 0.31);
    torso.cubicTo(w * 0.18, h * 0.22, w * 0.21, h * 0.16, w * 0.27, h * 0.138);
    torso.close();
    canvas.drawPath(torso, _basePaint);
    canvas.drawPath(torso, _strokePaint);

    // Left leg
    final leftLeg = Path();
    leftLeg.moveTo(w * 0.28, h * 0.505);
    leftLeg.cubicTo(w * 0.255, h * 0.51, w * 0.23, h * 0.52, w * 0.225, h * 0.545);
    leftLeg.cubicTo(w * 0.22, h * 0.57, w * 0.225, h * 0.61, w * 0.23, h * 0.64);
    leftLeg.cubicTo(w * 0.235, h * 0.67, w * 0.24, h * 0.695, w * 0.245, h * 0.71);
    // knee notch
    leftLeg.cubicTo(w * 0.24, h * 0.725, w * 0.235, h * 0.74, w * 0.24, h * 0.755);
    // calf
    leftLeg.cubicTo(w * 0.245, h * 0.78, w * 0.255, h * 0.82, w * 0.26, h * 0.855);
    // ankle taper
    leftLeg.cubicTo(w * 0.265, h * 0.885, w * 0.265, h * 0.915, w * 0.27, h * 0.935);
    leftLeg.lineTo(w * 0.35, h * 0.935);
    leftLeg.cubicTo(w * 0.355, h * 0.915, w * 0.355, h * 0.885, w * 0.355, h * 0.855);
    leftLeg.cubicTo(w * 0.36, h * 0.82, w * 0.365, h * 0.78, w * 0.365, h * 0.755);
    leftLeg.cubicTo(w * 0.37, h * 0.74, w * 0.365, h * 0.725, w * 0.36, h * 0.71);
    leftLeg.cubicTo(w * 0.365, h * 0.695, w * 0.375, h * 0.67, w * 0.38, h * 0.64);
    leftLeg.cubicTo(w * 0.39, h * 0.59, w * 0.39, h * 0.545, w * 0.375, h * 0.515);
    leftLeg.cubicTo(w * 0.36, h * 0.505, w * 0.33, h * 0.5, w * 0.28, h * 0.505);
    leftLeg.close();
    canvas.drawPath(leftLeg, _basePaint);
    canvas.drawPath(leftLeg, _strokePaint);

    // Right leg (mirror)
    final rightLeg = Path();
    rightLeg.moveTo(w * 0.72, h * 0.505);
    rightLeg.cubicTo(w * 0.745, h * 0.51, w * 0.77, h * 0.52, w * 0.775, h * 0.545);
    rightLeg.cubicTo(w * 0.78, h * 0.57, w * 0.775, h * 0.61, w * 0.77, h * 0.64);
    rightLeg.cubicTo(w * 0.765, h * 0.67, w * 0.76, h * 0.695, w * 0.755, h * 0.71);
    rightLeg.cubicTo(w * 0.76, h * 0.725, w * 0.765, h * 0.74, w * 0.76, h * 0.755);
    rightLeg.cubicTo(w * 0.755, h * 0.78, w * 0.745, h * 0.82, w * 0.74, h * 0.855);
    rightLeg.cubicTo(w * 0.735, h * 0.885, w * 0.735, h * 0.915, w * 0.73, h * 0.935);
    rightLeg.lineTo(w * 0.65, h * 0.935);
    rightLeg.cubicTo(w * 0.645, h * 0.915, w * 0.645, h * 0.885, w * 0.645, h * 0.855);
    rightLeg.cubicTo(w * 0.64, h * 0.82, w * 0.635, h * 0.78, w * 0.635, h * 0.755);
    rightLeg.cubicTo(w * 0.63, h * 0.74, w * 0.635, h * 0.725, w * 0.64, h * 0.71);
    rightLeg.cubicTo(w * 0.635, h * 0.695, w * 0.625, h * 0.67, w * 0.62, h * 0.64);
    rightLeg.cubicTo(w * 0.61, h * 0.59, w * 0.61, h * 0.545, w * 0.625, h * 0.515);
    rightLeg.cubicTo(w * 0.64, h * 0.505, w * 0.67, h * 0.5, w * 0.72, h * 0.505);
    rightLeg.close();
    canvas.drawPath(rightLeg, _basePaint);
    canvas.drawPath(rightLeg, _strokePaint);
  }

  void _drawFrontMuscles(Canvas canvas, double w, double h) {
    final stroke = _strokePaint;
    final div = _dividerPaint;

    // Chest — two pec shapes
    _paintMuscle(canvas, MuscleGroup.chest, () {
      final p = Path();
      // Left pec
      p.moveTo(w * 0.42, h * 0.148);
      p.cubicTo(w * 0.36, h * 0.15, w * 0.28, h * 0.16, w * 0.275, h * 0.195);
      p.cubicTo(w * 0.27, h * 0.23, w * 0.3, h * 0.265, w * 0.345, h * 0.275);
      p.cubicTo(w * 0.375, h * 0.28, w * 0.41, h * 0.275, w * 0.43, h * 0.265);
      p.cubicTo(w * 0.455, h * 0.253, w * 0.46, h * 0.235, w * 0.46, h * 0.215);
      p.cubicTo(w * 0.46, h * 0.188, w * 0.45, h * 0.165, w * 0.42, h * 0.148);
      p.close();
      return p;
    }, stroke);
    _paintMuscle(canvas, MuscleGroup.chest, () {
      final p = Path();
      // Right pec
      p.moveTo(w * 0.58, h * 0.148);
      p.cubicTo(w * 0.64, h * 0.15, w * 0.72, h * 0.16, w * 0.725, h * 0.195);
      p.cubicTo(w * 0.73, h * 0.23, w * 0.70, h * 0.265, w * 0.655, h * 0.275);
      p.cubicTo(w * 0.625, h * 0.28, w * 0.59, h * 0.275, w * 0.57, h * 0.265);
      p.cubicTo(w * 0.545, h * 0.253, w * 0.54, h * 0.235, w * 0.54, h * 0.215);
      p.cubicTo(w * 0.54, h * 0.188, w * 0.55, h * 0.165, w * 0.58, h * 0.148);
      p.close();
      return p;
    }, stroke);
    // sternum divider line
    canvas.drawLine(Offset(w * 0.5, h * 0.148), Offset(w * 0.5, h * 0.275), div);

    // Front deltoids
    _paintMuscle(canvas, MuscleGroup.frontalDeltoids, () {
      final p = Path();
      p.moveTo(w * 0.27, h * 0.145);
      p.cubicTo(w * 0.21, h * 0.142, w * 0.15, h * 0.155, w * 0.12, h * 0.185);
      p.cubicTo(w * 0.10, h * 0.205, w * 0.09, h * 0.228, w * 0.10, h * 0.25);
      p.cubicTo(w * 0.115, h * 0.27, w * 0.155, h * 0.275, w * 0.19, h * 0.265);
      p.cubicTo(w * 0.225, h * 0.255, w * 0.255, h * 0.235, w * 0.265, h * 0.215);
      p.cubicTo(w * 0.275, h * 0.19, w * 0.28, h * 0.165, w * 0.27, h * 0.145);
      p.close();
      return p;
    }, stroke);
    _paintMuscle(canvas, MuscleGroup.frontalDeltoids, () {
      final p = Path();
      p.moveTo(w * 0.73, h * 0.145);
      p.cubicTo(w * 0.79, h * 0.142, w * 0.85, h * 0.155, w * 0.88, h * 0.185);
      p.cubicTo(w * 0.90, h * 0.205, w * 0.91, h * 0.228, w * 0.90, h * 0.25);
      p.cubicTo(w * 0.885, h * 0.27, w * 0.845, h * 0.275, w * 0.81, h * 0.265);
      p.cubicTo(w * 0.775, h * 0.255, w * 0.745, h * 0.235, w * 0.735, h * 0.215);
      p.cubicTo(w * 0.725, h * 0.19, w * 0.72, h * 0.165, w * 0.73, h * 0.145);
      p.close();
      return p;
    }, stroke);

    // Biceps
    _paintMuscle(canvas, MuscleGroup.biceps, () {
      final p = Path();
      p.moveTo(w * 0.11, h * 0.258);
      p.cubicTo(w * 0.065, h * 0.265, w * 0.04, h * 0.29, w * 0.04, h * 0.32);
      p.cubicTo(w * 0.04, h * 0.355, w * 0.06, h * 0.385, w * 0.10, h * 0.39);
      p.cubicTo(w * 0.135, h * 0.395, w * 0.165, h * 0.38, w * 0.175, h * 0.355);
      p.cubicTo(w * 0.185, h * 0.33, w * 0.175, h * 0.28, w * 0.145, h * 0.263);
      p.cubicTo(w * 0.13, h * 0.257, w * 0.12, h * 0.256, w * 0.11, h * 0.258);
      p.close();
      return p;
    }, stroke);
    _paintMuscle(canvas, MuscleGroup.biceps, () {
      final p = Path();
      p.moveTo(w * 0.89, h * 0.258);
      p.cubicTo(w * 0.935, h * 0.265, w * 0.96, h * 0.29, w * 0.96, h * 0.32);
      p.cubicTo(w * 0.96, h * 0.355, w * 0.94, h * 0.385, w * 0.90, h * 0.39);
      p.cubicTo(w * 0.865, h * 0.395, w * 0.835, h * 0.38, w * 0.825, h * 0.355);
      p.cubicTo(w * 0.815, h * 0.33, w * 0.825, h * 0.28, w * 0.855, h * 0.263);
      p.cubicTo(w * 0.87, h * 0.257, w * 0.88, h * 0.256, w * 0.89, h * 0.258);
      p.close();
      return p;
    }, stroke);

    // Forearms
    _paintMuscle(canvas, MuscleGroup.forearms, () {
      final p = Path();
      p.moveTo(w * 0.09, h * 0.395);
      p.cubicTo(w * 0.055, h * 0.40, w * 0.04, h * 0.425, w * 0.045, h * 0.46);
      p.cubicTo(w * 0.05, h * 0.495, w * 0.065, h * 0.52, w * 0.09, h * 0.525);
      p.cubicTo(w * 0.115, h * 0.53, w * 0.15, h * 0.515, w * 0.16, h * 0.485);
      p.cubicTo(w * 0.17, h * 0.455, w * 0.16, h * 0.415, w * 0.135, h * 0.4);
      p.cubicTo(w * 0.12, h * 0.394, w * 0.105, h * 0.393, w * 0.09, h * 0.395);
      p.close();
      return p;
    }, stroke);
    _paintMuscle(canvas, MuscleGroup.forearms, () {
      final p = Path();
      p.moveTo(w * 0.91, h * 0.395);
      p.cubicTo(w * 0.945, h * 0.40, w * 0.96, h * 0.425, w * 0.955, h * 0.46);
      p.cubicTo(w * 0.95, h * 0.495, w * 0.935, h * 0.52, w * 0.91, h * 0.525);
      p.cubicTo(w * 0.885, h * 0.53, w * 0.85, h * 0.515, w * 0.84, h * 0.485);
      p.cubicTo(w * 0.83, h * 0.455, w * 0.84, h * 0.415, w * 0.865, h * 0.4);
      p.cubicTo(w * 0.88, h * 0.394, w * 0.895, h * 0.393, w * 0.91, h * 0.395);
      p.close();
      return p;
    }, stroke);

    // Abs — 3 rows × 2 cols as rounded rects inside torso
    final absPaint = Paint()..color = _muscleColor(MuscleGroup.abs);
    for (int row = 0; row < 3; row++) {
      for (int col = 0; col < 2; col++) {
        final x = w * (0.365 + col * 0.135);
        final y = h * (0.285 + row * 0.062);
        final rr = RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, w * 0.115, h * 0.048),
          const Radius.circular(5),
        );
        canvas.drawRRect(rr, absPaint);
        canvas.drawRRect(rr, div);
      }
    }
    // vertical line between ab columns
    canvas.drawLine(Offset(w * 0.5, h * 0.278), Offset(w * 0.5, h * 0.46), div);

    // Obliques
    _paintMuscle(canvas, MuscleGroup.obliques, () {
      final p = Path();
      p.moveTo(w * 0.27, h * 0.255);
      p.cubicTo(w * 0.26, h * 0.29, w * 0.26, h * 0.355, w * 0.265, h * 0.395);
      p.cubicTo(w * 0.275, h * 0.415, w * 0.295, h * 0.42, w * 0.315, h * 0.41);
      p.cubicTo(w * 0.34, h * 0.40, w * 0.355, h * 0.375, w * 0.355, h * 0.34);
      p.cubicTo(w * 0.355, h * 0.305, w * 0.34, h * 0.275, w * 0.315, h * 0.265);
      p.cubicTo(w * 0.295, h * 0.258, w * 0.28, h * 0.255, w * 0.27, h * 0.255);
      p.close();
      return p;
    }, stroke);
    _paintMuscle(canvas, MuscleGroup.obliques, () {
      final p = Path();
      p.moveTo(w * 0.73, h * 0.255);
      p.cubicTo(w * 0.74, h * 0.29, w * 0.74, h * 0.355, w * 0.735, h * 0.395);
      p.cubicTo(w * 0.725, h * 0.415, w * 0.705, h * 0.42, w * 0.685, h * 0.41);
      p.cubicTo(w * 0.66, h * 0.40, w * 0.645, h * 0.375, w * 0.645, h * 0.34);
      p.cubicTo(w * 0.645, h * 0.305, w * 0.66, h * 0.275, w * 0.685, h * 0.265);
      p.cubicTo(w * 0.705, h * 0.258, w * 0.72, h * 0.255, w * 0.73, h * 0.255);
      p.close();
      return p;
    }, stroke);

    // Hip flexors — small band at groin
    _paintMuscle(canvas, MuscleGroup.hipFlexors, () {
      final p = Path();
      p.moveTo(w * 0.29, h * 0.465);
      p.cubicTo(w * 0.29, h * 0.475, w * 0.30, h * 0.495, w * 0.335, h * 0.505);
      p.cubicTo(w * 0.36, h * 0.512, w * 0.395, h * 0.505, w * 0.41, h * 0.488);
      p.cubicTo(w * 0.415, h * 0.475, w * 0.41, h * 0.465, w * 0.395, h * 0.46);
      p.cubicTo(w * 0.37, h * 0.455, w * 0.315, h * 0.455, w * 0.29, h * 0.465);
      p.close();
      return p;
    }, stroke);
    _paintMuscle(canvas, MuscleGroup.hipFlexors, () {
      final p = Path();
      p.moveTo(w * 0.71, h * 0.465);
      p.cubicTo(w * 0.71, h * 0.475, w * 0.70, h * 0.495, w * 0.665, h * 0.505);
      p.cubicTo(w * 0.64, h * 0.512, w * 0.605, h * 0.505, w * 0.59, h * 0.488);
      p.cubicTo(w * 0.585, h * 0.475, w * 0.59, h * 0.465, w * 0.605, h * 0.46);
      p.cubicTo(w * 0.63, h * 0.455, w * 0.685, h * 0.455, w * 0.71, h * 0.465);
      p.close();
      return p;
    }, stroke);

    // Quadriceps
    _paintMuscle(canvas, MuscleGroup.quadriceps, () {
      final p = Path();
      p.moveTo(w * 0.235, h * 0.52);
      p.cubicTo(w * 0.215, h * 0.535, w * 0.21, h * 0.575, w * 0.215, h * 0.615);
      p.cubicTo(w * 0.22, h * 0.655, w * 0.235, h * 0.69, w * 0.25, h * 0.708);
      p.cubicTo(w * 0.275, h * 0.718, w * 0.35, h * 0.715, w * 0.375, h * 0.705);
      p.cubicTo(w * 0.395, h * 0.692, w * 0.40, h * 0.655, w * 0.395, h * 0.615);
      p.cubicTo(w * 0.39, h * 0.57, w * 0.375, h * 0.535, w * 0.355, h * 0.515);
      p.cubicTo(w * 0.33, h * 0.505, w * 0.265, h * 0.507, w * 0.235, h * 0.52);
      p.close();
      return p;
    }, stroke);
    _paintMuscle(canvas, MuscleGroup.quadriceps, () {
      final p = Path();
      p.moveTo(w * 0.765, h * 0.52);
      p.cubicTo(w * 0.785, h * 0.535, w * 0.79, h * 0.575, w * 0.785, h * 0.615);
      p.cubicTo(w * 0.78, h * 0.655, w * 0.765, h * 0.69, w * 0.75, h * 0.708);
      p.cubicTo(w * 0.725, h * 0.718, w * 0.65, h * 0.715, w * 0.625, h * 0.705);
      p.cubicTo(w * 0.605, h * 0.692, w * 0.60, h * 0.655, w * 0.605, h * 0.615);
      p.cubicTo(w * 0.61, h * 0.57, w * 0.625, h * 0.535, w * 0.645, h * 0.515);
      p.cubicTo(w * 0.67, h * 0.505, w * 0.735, h * 0.507, w * 0.765, h * 0.52);
      p.close();
      return p;
    }, stroke);
    // quad divisions
    canvas.drawLine(Offset(w * 0.305, h * 0.52), Offset(w * 0.3, h * 0.705), div);
    canvas.drawLine(Offset(w * 0.695, h * 0.52), Offset(w * 0.70, h * 0.705), div);

    // Calves
    _paintMuscle(canvas, MuscleGroup.calves, () {
      final p = Path();
      p.moveTo(w * 0.245, h * 0.755);
      p.cubicTo(w * 0.23, h * 0.77, w * 0.225, h * 0.805, w * 0.235, h * 0.845);
      p.cubicTo(w * 0.245, h * 0.875, w * 0.265, h * 0.895, w * 0.29, h * 0.895);
      p.cubicTo(w * 0.33, h * 0.898, w * 0.36, h * 0.878, w * 0.368, h * 0.845);
      p.cubicTo(w * 0.375, h * 0.808, w * 0.37, h * 0.77, w * 0.355, h * 0.755);
      p.cubicTo(w * 0.335, h * 0.748, w * 0.27, h * 0.748, w * 0.245, h * 0.755);
      p.close();
      return p;
    }, stroke);
    _paintMuscle(canvas, MuscleGroup.calves, () {
      final p = Path();
      p.moveTo(w * 0.755, h * 0.755);
      p.cubicTo(w * 0.77, h * 0.77, w * 0.775, h * 0.805, w * 0.765, h * 0.845);
      p.cubicTo(w * 0.755, h * 0.875, w * 0.735, h * 0.895, w * 0.71, h * 0.895);
      p.cubicTo(w * 0.67, h * 0.898, w * 0.64, h * 0.878, w * 0.632, h * 0.845);
      p.cubicTo(w * 0.625, h * 0.808, w * 0.63, h * 0.77, w * 0.645, h * 0.755);
      p.cubicTo(w * 0.665, h * 0.748, w * 0.73, h * 0.748, w * 0.755, h * 0.755);
      p.close();
      return p;
    }, stroke);
  }

  // ── BACK BODY ─────────────────────────────────────────────────────────────
  void _drawBackBody(Canvas canvas, double w, double h) {
    _drawBackSilhouette(canvas, w, h);
    _drawBackMuscles(canvas, w, h);
  }

  void _drawBackSilhouette(Canvas canvas, double w, double h) {
    // Reuse same silhouette as front (body outline is symmetric)
    _drawFrontSilhouette(canvas, w, h);
  }

  void _drawBackMuscles(Canvas canvas, double w, double h) {
    final stroke = _strokePaint;
    final div = _dividerPaint;

    // Trapezius — large trapezoid across upper back
    _paintMuscle(canvas, MuscleGroup.trapezius, () {
      final p = Path();
      p.moveTo(w * 0.42, h * 0.138); // neck left
      p.cubicTo(w * 0.35, h * 0.14, w * 0.28, h * 0.155, w * 0.27, h * 0.18);
      p.cubicTo(w * 0.27, h * 0.215, w * 0.30, h * 0.245, w * 0.345, h * 0.255);
      p.cubicTo(w * 0.40, h * 0.265, w * 0.46, h * 0.268, w * 0.50, h * 0.268);
      p.cubicTo(w * 0.54, h * 0.268, w * 0.60, h * 0.265, w * 0.655, h * 0.255);
      p.cubicTo(w * 0.70, h * 0.245, w * 0.73, h * 0.215, w * 0.73, h * 0.18);
      p.cubicTo(w * 0.72, h * 0.155, w * 0.65, h * 0.14, w * 0.58, h * 0.138);
      p.close();
      return p;
    }, stroke);
    // spine divider
    canvas.drawLine(Offset(w * 0.5, h * 0.138), Offset(w * 0.5, h * 0.268), div);

    // Rear deltoids
    _paintMuscle(canvas, MuscleGroup.rearDeltoids, () {
      final p = Path();
      p.moveTo(w * 0.27, h * 0.145);
      p.cubicTo(w * 0.21, h * 0.142, w * 0.15, h * 0.158, w * 0.12, h * 0.188);
      p.cubicTo(w * 0.10, h * 0.208, w * 0.09, h * 0.232, w * 0.10, h * 0.255);
      p.cubicTo(w * 0.115, h * 0.275, w * 0.155, h * 0.28, w * 0.19, h * 0.27);
      p.cubicTo(w * 0.225, h * 0.26, w * 0.255, h * 0.24, w * 0.265, h * 0.218);
      p.cubicTo(w * 0.275, h * 0.195, w * 0.28, h * 0.165, w * 0.27, h * 0.145);
      p.close();
      return p;
    }, stroke);
    _paintMuscle(canvas, MuscleGroup.rearDeltoids, () {
      final p = Path();
      p.moveTo(w * 0.73, h * 0.145);
      p.cubicTo(w * 0.79, h * 0.142, w * 0.85, h * 0.158, w * 0.88, h * 0.188);
      p.cubicTo(w * 0.90, h * 0.208, w * 0.91, h * 0.232, w * 0.90, h * 0.255);
      p.cubicTo(w * 0.885, h * 0.275, w * 0.845, h * 0.28, w * 0.81, h * 0.27);
      p.cubicTo(w * 0.775, h * 0.26, w * 0.745, h * 0.24, w * 0.735, h * 0.218);
      p.cubicTo(w * 0.725, h * 0.195, w * 0.72, h * 0.165, w * 0.73, h * 0.145);
      p.close();
      return p;
    }, stroke);

    // Triceps
    _paintMuscle(canvas, MuscleGroup.triceps, () {
      final p = Path();
      p.moveTo(w * 0.11, h * 0.258);
      p.cubicTo(w * 0.065, h * 0.268, w * 0.04, h * 0.295, w * 0.04, h * 0.325);
      p.cubicTo(w * 0.04, h * 0.358, w * 0.06, h * 0.388, w * 0.10, h * 0.393);
      p.cubicTo(w * 0.135, h * 0.398, w * 0.165, h * 0.382, w * 0.175, h * 0.358);
      p.cubicTo(w * 0.185, h * 0.333, w * 0.175, h * 0.283, w * 0.145, h * 0.265);
      p.cubicTo(w * 0.13, h * 0.258, w * 0.12, h * 0.256, w * 0.11, h * 0.258);
      p.close();
      return p;
    }, stroke);
    _paintMuscle(canvas, MuscleGroup.triceps, () {
      final p = Path();
      p.moveTo(w * 0.89, h * 0.258);
      p.cubicTo(w * 0.935, h * 0.268, w * 0.96, h * 0.295, w * 0.96, h * 0.325);
      p.cubicTo(w * 0.96, h * 0.358, w * 0.94, h * 0.388, w * 0.90, h * 0.393);
      p.cubicTo(w * 0.865, h * 0.398, w * 0.835, h * 0.382, w * 0.825, h * 0.358);
      p.cubicTo(w * 0.815, h * 0.333, w * 0.825, h * 0.283, w * 0.855, h * 0.265);
      p.cubicTo(w * 0.87, h * 0.258, w * 0.88, h * 0.256, w * 0.89, h * 0.258);
      p.close();
      return p;
    }, stroke);

    // Forearms (back)
    _paintMuscle(canvas, MuscleGroup.forearms, () {
      final p = Path();
      p.moveTo(w * 0.09, h * 0.395);
      p.cubicTo(w * 0.055, h * 0.403, w * 0.04, h * 0.428, w * 0.045, h * 0.462);
      p.cubicTo(w * 0.05, h * 0.496, w * 0.065, h * 0.522, w * 0.09, h * 0.527);
      p.cubicTo(w * 0.115, h * 0.532, w * 0.15, h * 0.517, w * 0.16, h * 0.487);
      p.cubicTo(w * 0.17, h * 0.457, w * 0.16, h * 0.415, w * 0.135, h * 0.4);
      p.cubicTo(w * 0.12, h * 0.394, w * 0.105, h * 0.393, w * 0.09, h * 0.395);
      p.close();
      return p;
    }, stroke);
    _paintMuscle(canvas, MuscleGroup.forearms, () {
      final p = Path();
      p.moveTo(w * 0.91, h * 0.395);
      p.cubicTo(w * 0.945, h * 0.403, w * 0.96, h * 0.428, w * 0.955, h * 0.462);
      p.cubicTo(w * 0.95, h * 0.496, w * 0.935, h * 0.522, w * 0.91, h * 0.527);
      p.cubicTo(w * 0.885, h * 0.532, w * 0.85, h * 0.517, w * 0.84, h * 0.487);
      p.cubicTo(w * 0.83, h * 0.457, w * 0.84, h * 0.415, w * 0.865, h * 0.4);
      p.cubicTo(w * 0.88, h * 0.394, w * 0.895, h * 0.393, w * 0.91, h * 0.395);
      p.close();
      return p;
    }, stroke);

    // Lats — V-taper shape each side
    _paintMuscle(canvas, MuscleGroup.lats, () {
      final p = Path();
      p.moveTo(w * 0.27, h * 0.18);
      p.cubicTo(w * 0.245, h * 0.22, w * 0.24, h * 0.28, w * 0.25, h * 0.34);
      p.cubicTo(w * 0.255, h * 0.375, w * 0.265, h * 0.40, w * 0.28, h * 0.41);
      p.cubicTo(w * 0.305, h * 0.418, w * 0.34, h * 0.41, w * 0.355, h * 0.39);
      p.cubicTo(w * 0.365, h * 0.37, w * 0.365, h * 0.34, w * 0.355, h * 0.31);
      p.cubicTo(w * 0.34, h * 0.27, w * 0.32, h * 0.23, w * 0.295, h * 0.20);
      p.cubicTo(w * 0.285, h * 0.185, w * 0.278, h * 0.178, w * 0.27, h * 0.18);
      p.close();
      return p;
    }, stroke);
    _paintMuscle(canvas, MuscleGroup.lats, () {
      final p = Path();
      p.moveTo(w * 0.73, h * 0.18);
      p.cubicTo(w * 0.755, h * 0.22, w * 0.76, h * 0.28, w * 0.75, h * 0.34);
      p.cubicTo(w * 0.745, h * 0.375, w * 0.735, h * 0.40, w * 0.72, h * 0.41);
      p.cubicTo(w * 0.695, h * 0.418, w * 0.66, h * 0.41, w * 0.645, h * 0.39);
      p.cubicTo(w * 0.635, h * 0.37, w * 0.635, h * 0.34, w * 0.645, h * 0.31);
      p.cubicTo(w * 0.66, h * 0.27, w * 0.68, h * 0.23, w * 0.705, h * 0.20);
      p.cubicTo(w * 0.715, h * 0.185, w * 0.722, h * 0.178, w * 0.73, h * 0.18);
      p.close();
      return p;
    }, stroke);

    // Lower back — erectors
    _paintMuscle(canvas, MuscleGroup.lowerBack, () {
      final p = Path();
      p.moveTo(w * 0.36, h * 0.355);
      p.cubicTo(w * 0.35, h * 0.37, w * 0.345, h * 0.40, w * 0.35, h * 0.43);
      p.cubicTo(w * 0.355, h * 0.45, w * 0.37, h * 0.462, w * 0.5, h * 0.462);
      p.cubicTo(w * 0.63, h * 0.462, w * 0.645, h * 0.45, w * 0.65, h * 0.43);
      p.cubicTo(w * 0.655, h * 0.40, w * 0.65, h * 0.37, w * 0.64, h * 0.355);
      p.cubicTo(w * 0.615, h * 0.345, w * 0.555, h * 0.34, w * 0.5, h * 0.34);
      p.cubicTo(w * 0.445, h * 0.34, w * 0.385, h * 0.345, w * 0.36, h * 0.355);
      p.close();
      return p;
    }, stroke);
    canvas.drawLine(Offset(w * 0.5, h * 0.34), Offset(w * 0.5, h * 0.462), div);

    // Glutes
    _paintMuscle(canvas, MuscleGroup.glutes, () {
      final p = Path();
      p.moveTo(w * 0.27, h * 0.462);
      p.cubicTo(w * 0.245, h * 0.475, w * 0.23, h * 0.498, w * 0.235, h * 0.525);
      p.cubicTo(w * 0.24, h * 0.555, w * 0.265, h * 0.575, w * 0.31, h * 0.578);
      p.cubicTo(w * 0.36, h * 0.582, w * 0.41, h * 0.565, w * 0.435, h * 0.54);
      p.cubicTo(w * 0.455, h * 0.52, w * 0.455, h * 0.495, w * 0.44, h * 0.475);
      p.cubicTo(w * 0.42, h * 0.458, w * 0.38, h * 0.46, w * 0.27, h * 0.462);
      p.close();
      return p;
    }, stroke);
    _paintMuscle(canvas, MuscleGroup.glutes, () {
      final p = Path();
      p.moveTo(w * 0.73, h * 0.462);
      p.cubicTo(w * 0.755, h * 0.475, w * 0.77, h * 0.498, w * 0.765, h * 0.525);
      p.cubicTo(w * 0.76, h * 0.555, w * 0.735, h * 0.575, w * 0.69, h * 0.578);
      p.cubicTo(w * 0.64, h * 0.582, w * 0.59, h * 0.565, w * 0.565, h * 0.54);
      p.cubicTo(w * 0.545, h * 0.52, w * 0.545, h * 0.495, w * 0.56, h * 0.475);
      p.cubicTo(w * 0.58, h * 0.458, w * 0.62, h * 0.46, w * 0.73, h * 0.462);
      p.close();
      return p;
    }, stroke);

    // Hamstrings
    _paintMuscle(canvas, MuscleGroup.hamstrings, () {
      final p = Path();
      p.moveTo(w * 0.235, h * 0.535);
      p.cubicTo(w * 0.215, h * 0.55, w * 0.21, h * 0.59, w * 0.218, h * 0.63);
      p.cubicTo(w * 0.225, h * 0.668, w * 0.24, h * 0.700, w * 0.255, h * 0.712);
      p.cubicTo(w * 0.28, h * 0.722, w * 0.352, h * 0.718, w * 0.375, h * 0.708);
      p.cubicTo(w * 0.395, h * 0.695, w * 0.40, h * 0.658, w * 0.395, h * 0.618);
      p.cubicTo(w * 0.39, h * 0.575, w * 0.375, h * 0.542, w * 0.355, h * 0.528);
      p.cubicTo(w * 0.33, h * 0.518, w * 0.265, h * 0.52, w * 0.235, h * 0.535);
      p.close();
      return p;
    }, stroke);
    _paintMuscle(canvas, MuscleGroup.hamstrings, () {
      final p = Path();
      p.moveTo(w * 0.765, h * 0.535);
      p.cubicTo(w * 0.785, h * 0.55, w * 0.79, h * 0.59, w * 0.782, h * 0.63);
      p.cubicTo(w * 0.775, h * 0.668, w * 0.76, h * 0.700, w * 0.745, h * 0.712);
      p.cubicTo(w * 0.72, h * 0.722, w * 0.648, h * 0.718, w * 0.625, h * 0.708);
      p.cubicTo(w * 0.605, h * 0.695, w * 0.60, h * 0.658, w * 0.605, h * 0.618);
      p.cubicTo(w * 0.61, h * 0.575, w * 0.625, h * 0.542, w * 0.645, h * 0.528);
      p.cubicTo(w * 0.67, h * 0.518, w * 0.735, h * 0.52, w * 0.765, h * 0.535);
      p.close();
      return p;
    }, stroke);
    // ham divisions
    canvas.drawLine(Offset(w * 0.305, h * 0.535), Offset(w * 0.302, h * 0.71), div);
    canvas.drawLine(Offset(w * 0.695, h * 0.535), Offset(w * 0.698, h * 0.71), div);

    // Calves (back)
    _paintMuscle(canvas, MuscleGroup.calves, () {
      final p = Path();
      p.moveTo(w * 0.245, h * 0.755);
      p.cubicTo(w * 0.23, h * 0.772, w * 0.225, h * 0.808, w * 0.235, h * 0.848);
      p.cubicTo(w * 0.245, h * 0.878, w * 0.265, h * 0.898, w * 0.29, h * 0.898);
      p.cubicTo(w * 0.33, h * 0.90, w * 0.36, h * 0.88, w * 0.368, h * 0.848);
      p.cubicTo(w * 0.375, h * 0.81, w * 0.37, h * 0.772, w * 0.355, h * 0.755);
      p.cubicTo(w * 0.335, h * 0.748, w * 0.27, h * 0.748, w * 0.245, h * 0.755);
      p.close();
      return p;
    }, stroke);
    _paintMuscle(canvas, MuscleGroup.calves, () {
      final p = Path();
      p.moveTo(w * 0.755, h * 0.755);
      p.cubicTo(w * 0.77, h * 0.772, w * 0.775, h * 0.808, w * 0.765, h * 0.848);
      p.cubicTo(w * 0.755, h * 0.878, w * 0.735, h * 0.898, w * 0.71, h * 0.898);
      p.cubicTo(w * 0.67, h * 0.90, w * 0.64, h * 0.88, w * 0.632, h * 0.848);
      p.cubicTo(w * 0.625, h * 0.81, w * 0.63, h * 0.772, w * 0.645, h * 0.755);
      p.cubicTo(w * 0.665, h * 0.748, w * 0.73, h * 0.748, w * 0.755, h * 0.755);
      p.close();
      return p;
    }, stroke);
  }

  void _paintMuscle(Canvas canvas, MuscleGroup muscle, Path Function() pathBuilder, Paint stroke) {
    final fill = Paint()..color = _muscleColor(muscle);
    final path = pathBuilder();
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(covariant _BodyPainter old) =>
      old.colorMap != colorMap || old.viewType != viewType;
}
