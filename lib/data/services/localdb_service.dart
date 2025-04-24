import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:pandacore/data/models/exercise_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../../utils/file_utils.dart';

class LocalDB {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    final path = join(await getDatabasesPath(), 'workout.db');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
        CREATE TABLE logs (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          date TEXT UNIQUE,
          routine TEXT
        )
      ''');
      },
    );
    return _db!;
  }

  static Future<void> insertLog(WorkoutRoutine routine) async {
    final db = await database;
    final now = DateTime.now().subtract(Duration(days: 0));
    final date = now.toIso8601String().substring(0, 10);
    await db.insert('logs', {
      'date': date,
      'routine': jsonEncode(routine.toJson()),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<Map<String, dynamic>>> fetchLogs() async {
    final db = await database;
    return db.query('logs', orderBy: 'date DESC');
  }

  static Future<List<DateTime>> getLoggedDates() async {
    final logs = await fetchLogs();
    return logs.map((log) => DateTime.parse(log['date'])).toList();
  }

  static Future<void> clearLogs() async {
    final db = await database;
    await db.delete('logs');
  }

  static Future<void> deleteToday() async {
    final db = await database;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    await db.delete('logs', where: 'date = ?', whereArgs: [today]);
  }

  static Future<String> exportProgress() async {
    final logs = await fetchLogs();

    final rows = <List<String>>[
      ['Date', 'Routine'],
      ...logs.map((log) => [log['date'], log['routine']]),
    ];

    final csvData = const ListToCsvConverter().convert(rows);
    String message = await saveWorkoutAsCsv('workout_history.csv', csvData);
    return message;
  }

  static Future<String> importProgress() async {
    final filePath = await pickLocation(['csv']);
    try {
      if (filePath != null) {
        final file = File(filePath);
        final csvString = await file.readAsString();
        final rows = const CsvToListConverter(eol: '\r\n').convert(csvString);

        final db = await database;

        for (int i = 1; i < rows.length; i++) {
          final date = rows[i][0] as String;
          final routineJsonString = rows[i][1] as String;

          await db.insert('logs', {
            'date': date,
            'routine': routineJsonString,
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }

        return 'Data imported successfully';
      } else {
        return 'Error: no file path provided';
      }
    } catch (e) {
      return 'Error importing workout history: $e';
    }
  }
}
