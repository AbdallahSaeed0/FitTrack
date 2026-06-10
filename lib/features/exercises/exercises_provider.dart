import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/exercise_model.dart';
import '../../data/repositories/exercise_repository.dart';

final exerciseRepositoryProvider = Provider((_) => ExerciseRepository());

class ExerciseSearchState {
  final List<ExerciseModel> results;
  final bool isLoading;
  final String? error;
  final String query;
  final String? selectedBodyPart;

  const ExerciseSearchState({
    this.results = const [],
    this.isLoading = false,
    this.error,
    this.query = '',
    this.selectedBodyPart,
  });

  ExerciseSearchState copyWith({
    List<ExerciseModel>? results,
    bool? isLoading,
    String? error,
    String? query,
    Object? selectedBodyPart = _keep,
  }) {
    return ExerciseSearchState(
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      query: query ?? this.query,
      selectedBodyPart: identical(selectedBodyPart, _keep)
          ? this.selectedBodyPart
          : selectedBodyPart as String?,
    );
  }
}

// Sentinel for copyWith — distinguishes "not passed" from "explicitly null"
const _keep = Object();

class ExerciseSearchNotifier extends Notifier<ExerciseSearchState> {
  @override
  ExerciseSearchState build() => const ExerciseSearchState();

  /// Run query + optional body-part filter together.
  Future<void> search(String query, {String? bodyPart}) async {
    final bp = bodyPart ?? state.selectedBodyPart;
    final hasQuery = query.length > 1;
    final hasFilter = bp != null && bp.isNotEmpty;

    if (!hasQuery && !hasFilter) {
      state = const ExerciseSearchState();
      return;
    }

    state = state.copyWith(
        isLoading: true, query: query, selectedBodyPart: bp ?? _keep);

    try {
      final repo = ref.read(exerciseRepositoryProvider);
      List<ExerciseModel> results;

      if (hasQuery && hasFilter) {
        // Search by name then filter by body part
        final all = await repo.searchByName(query, limit: 200);
        results = all
            .where((e) =>
                e.bodyParts.any((b) => b.toLowerCase() == bp.toLowerCase()) ||
                e.targetMuscles
                    .any((m) => m.toLowerCase().contains(bp.toLowerCase())))
            .take(150)
            .toList();
      } else if (hasQuery) {
        results = await repo.searchByName(query, limit: 40);
      } else {
        // Filter only
        results = await repo.getSimilarExercises(bp!, limit: 150);
      }

      state = state.copyWith(results: results, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> setBodyPart(String? bodyPart, {String? currentQuery}) async {
    await search(currentQuery ?? state.query, bodyPart: bodyPart);
  }

  Future<void> loadSimilar(String bodyPart) async {
    state = state.copyWith(isLoading: true, selectedBodyPart: bodyPart);
    try {
      final repo = ref.read(exerciseRepositoryProvider);
      final results = await repo.getSimilarExercises(bodyPart, limit: 150);
      state = state.copyWith(results: results, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  void clear() => state = const ExerciseSearchState();
}

final exerciseSearchProvider =
    NotifierProvider<ExerciseSearchNotifier, ExerciseSearchState>(
  ExerciseSearchNotifier.new,
);
