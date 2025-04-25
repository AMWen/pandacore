import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';

import '../data/constants.dart';
import '../data/models/exercise_model.dart';
import '../data/services/localdb_service.dart';
import '../data/services/workout_generator.dart';
import '../data/widgets/countdown_widget.dart';
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
            Card(
              margin: EdgeInsets.symmetric(vertical: 0, horizontal: 12),
              color: primaryColor,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 6, horizontal: 0),
                child: Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...routine!.exercises.map((e) {
                          final isTimed = e.isTimed;
                          final text = e.formatText();
                          return ListTile(
                            minTileHeight: 0,
                            contentPadding: EdgeInsets.zero,
                            horizontalTitleGap: 0,
                            leading:
                                isTimed
                                    ? GestureDetector(
                                      onTap:
                                          () => showDialog(
                                            context: context,
                                            builder: (_) => CountdownDialog(seconds: e.amount),
                                          ),
                                      child: Container(
                                        color: primaryColor,
                                        child: SizedBox(
                                          width: 36,
                                          height: 36,
                                          child: Center(child: Text('⏰')),
                                        ),
                                      ),
                                    )
                                    : SizedBox(width: 36, height: 36),
                            title: Text(text, style: TextStyles.whiteText),
                            onTap: () {
                              _launchUrl(e.videoLink);
                            },
                          );
                        }),
                      ],
                    ),
                    // Add checkbox icon in top-right corner
                    Positioned(
                      right: 12,
                      top: 6,
                      child: GestureDetector(
                        onTap: () async {
                          if (!isWorkoutCompleted) {
                            await LocalDB.insertLog(routine!);
                            setState(() {
                              isWorkoutCompleted = true;
                            });
                            if (context.mounted) {
                              showErrorSnackbar(context, 'Workout completed! Great job 💪');
                            }
                          } else {
                            await LocalDB.delete(today);
                            setState(() {
                              isWorkoutCompleted = false;
                            });
                            if (context.mounted) {
                              showErrorSnackbar(context, 'Workout incomplete. 😭');
                            }
                          }
                        },
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: isWorkoutCompleted ? Colors.green.shade600 : dullColor,
                          child: Icon(Icons.check, color: secondaryColor),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Yesterday Card
            SizedBox(height: 16),
            Text(
              'Yesterday: ${yesterdayRoutine!.exercisesPerSet} exercises x ${yesterdayRoutine!.sets}',
              style: TextStyles.titleText,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            Card(
              margin: EdgeInsets.symmetric(vertical: 0, horizontal: 12),
              color: primaryColor,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 6, horizontal: 0),
                child: Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...yesterdayRoutine!.exercises.map((e) {
                          final isTimed = e.isTimed;
                          final text = e.formatText();
                          return ListTile(
                            minTileHeight: 0,
                            contentPadding: EdgeInsets.zero,
                            horizontalTitleGap: 0,
                            leading:
                                isTimed
                                    ? GestureDetector(
                                      onTap:
                                          () => showDialog(
                                            context: context,
                                            builder: (_) => CountdownDialog(seconds: e.amount),
                                          ),
                                      child: Container(
                                        color: primaryColor,
                                        child: SizedBox(
                                          width: 36,
                                          height: 36,
                                          child: Center(child: Text('⏰')),
                                        ),
                                      ),
                                    )
                                    : SizedBox(width: 36, height: 36),
                            title: Text(text, style: TextStyles.whiteText),
                            onTap: () {
                              _launchUrl(e.videoLink);
                            },
                          );
                        }),
                      ],
                    ),
                    // Add checkbox icon in top-right corner
                    Positioned(
                      right: 12,
                      top: 6,
                      child: GestureDetector(
                        onTap: () async {
                          if (!isYesterdayCompleted) {
                            await LocalDB.insertLog(
                              routine!,
                              yesterday.toIso8601String().substring(0, 10),
                            );
                            setState(() {
                              isYesterdayCompleted = true;
                            });
                            if (context.mounted) {
                              showErrorSnackbar(context, 'Workout completed! Great job 💪');
                            }
                          } else {
                            await LocalDB.delete(yesterday);
                            setState(() {
                              isYesterdayCompleted = false;
                            });
                            if (context.mounted) {
                              showErrorSnackbar(context, 'Workout incomplete. 😭');
                            }
                          }
                        },
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: isYesterdayCompleted ? Colors.green.shade600 : dullColor,
                          child: Icon(Icons.check, color: secondaryColor),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
