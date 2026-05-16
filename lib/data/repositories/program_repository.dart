import 'package:flutter/foundation.dart';
import '../models/program_model.dart';
import '../services/hive_service.dart';

class ProgramRepository {
  List<ProgramModel> getAll() {
    final box = HiveService.programs;
    final result = <ProgramModel>[];
    for (final key in List.of(box.keys)) {
      try {
        final p = box.get(key);
        if (p != null) result.add(p);
      } catch (e) {
        debugPrint('[ProgramRepo] Corrupt entry at $key — deleting: $e');
        box.delete(key);
      }
    }
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }

  ProgramModel? getById(String id) {
    try {
      final p = HiveService.programs.get(id);
      return p;
    } catch (e) {
      debugPrint('[ProgramRepo] Corrupt program $id — deleting: $e');
      HiveService.programs.delete(id);
      return null;
    }
  }

  ProgramModel? getActive() {
    for (final program in getAll()) {
      if (program.isActive) return program;
    }
    return null;
  }

  Future<void> save(ProgramModel program) async {
    await HiveService.programs.put(program.id, program);
  }

  Future<void> setActive(String id) async {
    for (final program in getAll()) {
      if (program.isActive && program.id != id) {
        await HiveService.programs.put(program.id, program.copyWith(isActive: false));
      }
    }
    final target = getById(id);
    if (target != null) {
      await HiveService.programs.put(id, target.copyWith(isActive: true));
    }
  }

  Future<void> delete(String id) async {
    await HiveService.programs.delete(id);
  }

  Future<void> advanceDay(String programId) async {
    final program = getById(programId);
    if (program == null) return;
    final nextIndex = (program.currentDayIndex + 1) % program.days.length;
    await save(program.copyWith(currentDayIndex: nextIndex));
  }
}
