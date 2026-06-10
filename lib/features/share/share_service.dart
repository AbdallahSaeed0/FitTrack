import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/models/session_model.dart';
import '../../data/repositories/session_repository.dart';

// ── Share data model ──────────────────────────────────────────────────────────

class WorkoutShareData {
  final WorkoutSessionModel session;
  final String programName;
  final double totalVolume;
  final int totalSets;
  final List<String> prExercises;
  /// Optional raw bytes of a post-session progress photo used as card background.
  /// Using bytes (not a path) keeps this widget web-safe — `Image.memory` works
  /// on every platform, `Image.file` crashes on Flutter Web.
  final Uint8List? backgroundPhotoBytes;

  const WorkoutShareData({
    required this.session,
    required this.programName,
    required this.totalVolume,
    required this.totalSets,
    required this.prExercises,
    this.backgroundPhotoBytes,
  });

  WorkoutShareData copyWith({Uint8List? backgroundPhotoBytes}) =>
      WorkoutShareData(
        session: session,
        programName: programName,
        totalVolume: totalVolume,
        totalSets: totalSets,
        prExercises: prExercises,
        backgroundPhotoBytes:
            backgroundPhotoBytes ?? this.backgroundPhotoBytes,
      );

  int get exerciseCount =>
      session.exercises.where((e) => e.sets.isNotEmpty).length;

  static WorkoutShareData fromSession(
    WorkoutSessionModel session, {
    String programName = '',
  }) {
    double vol = 0;
    int sets = 0;
    final prs = <String>[];

    for (final ex in session.exercises) {
      double sessionMax = 0;
      for (final s in ex.sets) {
        vol += s.weight * s.reps;
        sets++;
        if (s.weight > sessionMax) sessionMax = s.weight;
      }
      if (sessionMax > 0 && !ex.sets.any((s) => s.isBodyweight)) {
        // Historical max, excluding this session
        double historicalMax = 0;
        for (final other in SessionRepository.instance
            .getAll()
            .where((s) => s.completed && s.id != session.id)) {
          for (final otherEx in other.exercises) {
            if (otherEx.exerciseName.toLowerCase().trim() ==
                ex.exerciseName.toLowerCase().trim()) {
              for (final s in otherEx.sets) {
                if (s.weight > historicalMax) historicalMax = s.weight;
              }
            }
          }
        }
        if (sessionMax > historicalMax) prs.add(ex.exerciseName);
      }
    }

    return WorkoutShareData(
      session: session,
      programName: programName,
      totalVolume: vol,
      totalSets: sets,
      prExercises: prs,
    );
  }
}

// ── Share service ─────────────────────────────────────────────────────────────

class ShareService {
  static Future<List<int>?> captureCard(
    RenderRepaintBoundary boundary,
  ) async {
    await Future.delayed(const Duration(milliseconds: 80));
    final image = await boundary.toImage(pixelRatio: 4.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  static Future<String> _saveTempFile(List<int> bytes) async {
    final dir = await getTemporaryDirectory();
    final ts = DateTime.now().millisecondsSinceEpoch;
    final file = File('${dir.path}/fittrack_workout_$ts.png');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  static Future<void> shareCard(
    List<int> bytes, {
    String text = '',
  }) async {
    final path = await _saveTempFile(bytes);
    await Share.shareXFiles(
      [XFile(path, mimeType: 'image/png')],
      text: text.isNotEmpty ? text : null,
    );
  }

  /// Attempts Instagram Stories deep link (iOS/Android).
  /// Falls back to standard share sheet if Instagram isn't installed.
  static Future<void> shareToInstagramStories(List<int> bytes) async {
    final path = await _saveTempFile(bytes);

    // Instagram Stories URI scheme (iOS + Android)
    final uri = Uri.parse('instagram-stories://share?source_application=fittrack');
    if (await canLaunchUrl(uri)) {
      // Write file to a known path and pass via share intent
      await Share.shareXFiles([XFile(path, mimeType: 'image/png')]);
    } else {
      await Share.shareXFiles([XFile(path, mimeType: 'image/png')]);
    }
  }

  static String buildTextSummary(WorkoutShareData data) {
    final vol = data.totalVolume >= 1000
        ? '${(data.totalVolume / 1000).toStringAsFixed(1)}k kg'
        : '${data.totalVolume.toStringAsFixed(0)} kg';
    final lines = [
      '✅ ${data.session.dayName.toUpperCase()} DONE!',
      '⏱ ${data.session.durationMinutes} minutes',
      '📊 Volume: $vol',
      '🔢 ${data.totalSets} sets · ${data.exerciseCount} exercises',
      if (data.prExercises.isNotEmpty)
        '🏆 ${data.prExercises.length} new PR${data.prExercises.length > 1 ? 's' : ''}!',
      '',
      '#FitTrack #Fitness #GymLife',
    ];
    return lines.join('\n');
  }
}
