import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class TechniqueBadge extends StatelessWidget {
  final String technique;

  const TechniqueBadge({super.key, required this.technique});

  static String label(String technique) {
    switch (technique) {
      case 'drop_sets':
        return 'Drop Sets';
      case 'supersets':
        return 'Supersets';
      case 'rest_pause':
        return 'Rest-Pause';
      case 'pyramid_sets':
        return 'Pyramid';
      case 'tempo_training':
        return 'Tempo';
      case 'giant_sets':
        return 'Giant Sets';
      case 'cluster_sets':
        return 'Cluster';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = label(technique);
    if (text.isEmpty || technique == 'standard') return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: steelBlue.withAlpha(30),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: steelBlue.withAlpha(80)),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 11, color: steelBlue, fontWeight: FontWeight.w600),
      ),
    );
  }
}
