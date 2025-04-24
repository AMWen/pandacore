import 'dart:math';
import '../constants.dart';
import '../models/exercise_model.dart';

class WorkoutGenerator {
  static WorkoutRoutine generateDailyRoutineStructured([int? seed]) {
    if (seed == null) {
      final now = DateTime.now();
      seed = DateTime(now.year, now.month, now.day, now.hour).millisecondsSinceEpoch;
    }

    final random = Random(seed);
    final option = routineOptions[random.nextInt(routineOptions.length)];
    final sets = option[0];
    final exercisesPerSet = option[1];
    final totalExercises = sets * exercisesPerSet;

    final List<Exercise> chosen = List.of(exercisePool)..shuffle(random);
    final List<Exercise> selected = chosen.take(exercisesPerSet).toList();

    final factor = _calculateScalingFactor(totalExercises);
    final List<Exercise> setsList =
        selected.map((ex) {
          final amount = _scaleAmount(ex, factor);
          return Exercise(name: ex.name, amount: amount, isTimed: ex.isTimed, videoLink: ex.videoLink);
        }).toList();

    return WorkoutRoutine(sets: sets, exercisesPerSet: exercisesPerSet, exercises: setsList);
  }

  static double _calculateScalingFactor(int totalExercises) {
    const baseVolume = 10.0;
    return baseVolume / totalExercises;
  }

  static int _scaleAmount(Exercise exercise, double factor) {
    final random = Random();
    final raw = (exercise.amount * factor).round();
    int base = raw ~/ exercise.increment; // for rounding

    // 5% chance to adjust by +/- 1
    if (random.nextDouble() < 0.05) {
      int adjustment = random.nextBool() ? 1 : -1;
      base = max(base + adjustment, 1);
    }

    return base * exercise.increment;
  }
}
