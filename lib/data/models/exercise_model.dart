class Exercise {
  final String name;
  final int amount;
  final bool isTimed;
  final int increment;
  final String videoLink;

  Exercise({
    required this.name,
    required this.amount,
    this.isTimed = false,
    this.increment = 1,
    this.videoLink = '',
  });

  Map<String, dynamic> toJson() {
    return {'name': name, 'amount': amount, 'isTimed': isTimed, 'increment': increment, 'videoLink': videoLink};
  }

  String formatText() {
    return isTimed ? '${amount}s $name' : '$amount $name';
  }

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      name: json['name'],
      amount: json['amount'],
      isTimed: json['isTimed'] ?? false,
      increment: json['increment'] ?? 1,
      videoLink: json['videoLink'] ?? '',
    );
  }
}

class WorkoutRoutine {
  final int sets;
  final int exercisesPerSet;
  final List<Exercise> exercises;

  WorkoutRoutine({required this.sets, required this.exercisesPerSet, required this.exercises});

  Map<String, dynamic> toJson() {
    return {
      'sets': sets,
      'exercisesPerSet': exercisesPerSet,
      'exercises': exercises.map((e) => e.toJson()).toList(),
    };
  }

  factory WorkoutRoutine.fromJson(Map<String, dynamic> json) {
    return WorkoutRoutine(
      sets: json['sets'],
      exercisesPerSet: json['exercisesPerSet'],
      exercises: (json['exercises'] as List).map((e) => Exercise.fromJson(e)).toList(),
    );
  }
}
