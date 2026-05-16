import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/exercise_model.dart';
import '../../data/repositories/exercise_repository.dart';

final exerciseRepositoryProvider = Provider((_) => ExerciseRepository());

class ExerciseSearchState {
  final List<ExerciseModel> results;
  final bool isLoading;
  final String? error;
  final String query;

  const ExerciseSearchState({
    this.results = const [],
    this.isLoading = false,
    this.error,
    this.query = '',
  });

  ExerciseSearchState copyWith({
    List<ExerciseModel>? results,
    bool? isLoading,
    String? error,
    String? query,
  }) {
    return ExerciseSearchState(
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      query: query ?? this.query,
    );
  }
}

class ExerciseSearchNotifier extends Notifier<ExerciseSearchState> {
  @override
  ExerciseSearchState build() => const ExerciseSearchState();

  Future<void> search(String query) async {
    if (query.isEmpty) {
      state = const ExerciseSearchState();
      return;
    }
    state = state.copyWith(isLoading: true, query: query);
    try {
      final repo = ref.read(exerciseRepositoryProvider);
      final results = await repo.searchByName(query);
      state = state.copyWith(results: results, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> loadSimilar(String bodyPart) async {
    state = state.copyWith(isLoading: true);
    try {
      final repo = ref.read(exerciseRepositoryProvider);
      final results = await repo.getSimilarExercises(bodyPart);
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
