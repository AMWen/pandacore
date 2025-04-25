import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';

import '../data/constants.dart';
import '../data/models/exercise_model.dart';
import '../data/services/localdb_service.dart';
import '../data/services/workout_generator.dart';
import '../data/widgets/workoutcard_widget.dart';
import 'history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  WorkoutRoutine? routine;
  WorkoutRoutine? yesterdayRoutine;
  DateTime today = DateTime.now();
  DateTime yesterday = DateTime.now().subtract(Duration(days: 1));
  bool isWorkoutCompleted = false;
  bool isYesterdayCompleted = false;
  int? seed;
  int? prevSeed;
  late int todaySeed;
  late int yesterdaySeed;

  @override
  void initState() {
    super.initState();
    todaySeed = DateTime(today.year, today.month, today.day).millisecondsSinceEpoch;
    yesterdaySeed = DateTime(yesterday.year, yesterday.month, yesterday.day).millisecondsSinceEpoch;
    _loadRoutine();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _rebuild();
  }

  void _rebuild() {
    // Check if the date has changed and update accordingly
    final now = DateTime.now();

    if (DateTime(today.year, today.month, today.day) != DateTime(now.year, now.month, now.day)) {
      resetStates();
      _loadRoutine();
    }
  }

  void resetStates() {
    setState(() {
      routine = null;
      yesterdayRoutine = null;
      today = DateTime.now();
      yesterday = DateTime.now().subtract(Duration(days: 1));
      isWorkoutCompleted = false;
      isYesterdayCompleted = false;
      todaySeed = DateTime(today.year, today.month, today.day).millisecondsSinceEpoch;
      yesterdaySeed =
          DateTime(yesterday.year, yesterday.month, yesterday.day).millisecondsSinceEpoch;
    });
  }

  Future<void> _loadRoutine() async {
    final prefs = await SharedPreferences.getInstance();
    final todayStr = today.toIso8601String().substring(0, 10); // YYYY-MM-DD

    seed = prefs.getInt('seed');
    final savedDate = prefs.getString('routine_date');
    final savedRoutineJson = prefs.getString('routine_data');

    // Check if today's routine is saved in DB
    routine = await LocalDB.getRoutineForDate(today);
    if (routine != null) {
      setState(() {
        isWorkoutCompleted = true;
      });
    } else {
      if (savedDate == todayStr && savedRoutineJson != null) {
        setState(() {
          routine = WorkoutRoutine.fromJson(jsonDecode(savedRoutineJson));
        });
      } else {
        seed = todaySeed;
        _generateNewRoutine(seed!);
      }
    }

    // Check if yesterday's routine is saved, if not generate it
    yesterdayRoutine = await LocalDB.getRoutineForDate(yesterday);
    if (yesterdayRoutine != null) {
      setState(() {
        isYesterdayCompleted = true;
      });
    } else {
      _generateYesterdayRoutine(yesterdaySeed);
    }
  }

  Future<void> _generateNewRoutine(int seed) async {
    final prefs = await SharedPreferences.getInstance();
    final newRoutine = WorkoutGenerator.generateDailyRoutineStructured(seed);
    final today = DateTime.now().toIso8601String().substring(0, 10);

    await prefs.setInt('seed', seed);
    await prefs.setString('routine_date', today);
    await prefs.setString('routine_data', jsonEncode(newRoutine.toJson()));

    setState(() {
      routine = newRoutine;
    });
  }

  Future<void> _generateYesterdayRoutine(int seed) async {
    setState(() {
      isYesterdayCompleted = false;
      yesterdayRoutine = WorkoutGenerator.generateDailyRoutineStructured(seed);
    });
  }

  void showErrorSnackbar(BuildContext context, String message) {
    Duration duration =
        message.contains('Error') ? Duration(milliseconds: 1500) : Duration(milliseconds: 800);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), duration: duration));
  }

  Future<void> _launchUrl(String url) async {
    if (url == '') {
      showErrorSnackbar(context, 'No informational video for this exercise');
      return;
    }

    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'http://$url';
    }

    final Uri parsedUrl = Uri.parse(url);

    if (!await launchUrl(parsedUrl)) {
      if (mounted) {
        showErrorSnackbar(context, 'Error: could not launch $url');
      }
    }
  }

  Future<void> toggleWorkoutCompletion({
    required BuildContext context,
    required DateTime date,
    required WorkoutRoutine routine,
    required bool isCompleted,
    required void Function(bool) updateState,
  }) async {
    final formattedDate = date.toIso8601String().substring(0, 10);

    if (!isCompleted) {
      await LocalDB.insertLog(routine, formattedDate);
      updateState(true);
      if (context.mounted) {
        showErrorSnackbar(context, 'Workout completed! Great job 💪');
      }
    } else {
      await LocalDB.delete(date);
      updateState(false);
      if (context.mounted) {
        showErrorSnackbar(context, 'Workout incomplete. 😭');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (routine == null || yesterdayRoutine == null) {
      return Scaffold(
        appBar: AppBar(title: Text('PandaCore')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('PandaCore'),
        actions: [
          SizedBox(
            width: 34,
            child: IconButton(
              icon: Icon(Icons.calendar_month),
              tooltip: 'Workout History',
              onPressed:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => HistoryScreen()),
                  ).then((_) => _rebuild()),
            ),
          ),
          SizedBox(
            width: 34,
            child: IconButton(
              icon: Icon(Icons.refresh),
              tooltip: 'Generate New Workout',
              onPressed: () {
                setState(() {
                  seed = seed == null ? todaySeed : seed! + 1;
                });
                _generateNewRoutine(seed!);
              },
            ),
          ),
          SizedBox(width: 10),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Today Card
            Text(
              'Today: ${routine!.exercisesPerSet} exercises x ${routine!.sets}',
              style: TextStyles.titleText,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            buildWorkoutCard(
              context: context,
              routine: routine!,
              isCompleted: isWorkoutCompleted,
              onToggleComplete: () async {
                await toggleWorkoutCompletion(
                  context: context,
                  date: today,
                  isCompleted: isWorkoutCompleted,
                  routine: routine!,
                  updateState: (val) => setState(() => isWorkoutCompleted = val),
                );
              },
              onLaunchUrl: _launchUrl,
            ),

            // Yesterday Card
            SizedBox(height: 16),
            Text(
              'Yesterday: ${yesterdayRoutine!.exercisesPerSet} exercises x ${yesterdayRoutine!.sets}',
              style: TextStyles.titleText,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            buildWorkoutCard(
              context: context,
              routine: yesterdayRoutine!,
              isCompleted: isYesterdayCompleted,
              onToggleComplete: () async {
                await toggleWorkoutCompletion(
                  context: context,
                  date: yesterday,
                  isCompleted: isYesterdayCompleted,
                  routine: yesterdayRoutine!,
                  updateState: (val) => setState(() => isYesterdayCompleted = val),
                );
              },
              onLaunchUrl: _launchUrl,
            ),
          ],
        ),
      ),
    );
  }
}
