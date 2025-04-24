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
  bool isWorkoutCompleted = false;

  @override
  void initState() {
    super.initState();
    _loadRoutine();
  }

  Future<void> _loadRoutine() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10); // YYYY-MM-DD
    final savedDate = prefs.getString('routine_date');
    final savedRoutineJson = prefs.getString('routine_data');

    if (savedDate == today && savedRoutineJson != null) {
      setState(() {
        routine = WorkoutRoutine.fromJson(jsonDecode(savedRoutineJson));
      });
      _checkIfWorkoutCompleted(today);
    } else {
      _generateNewRoutine();
    }
  }

  Future<void> _generateNewRoutine() async {
    final prefs = await SharedPreferences.getInstance();
    final newRoutine = WorkoutGenerator.generateDailyRoutineStructured();
    final today = DateTime.now().toIso8601String().substring(0, 10);

    await prefs.setString('routine_date', today);
    await prefs.setString('routine_data', jsonEncode(newRoutine.toJson()));

    setState(() {
      routine = newRoutine;
    });

    _checkIfWorkoutCompleted(today);
  }

  Future<void> _checkIfWorkoutCompleted(String date) async {
    final logs = await LocalDB.fetchLogs();
    final completedRoutine = logs.firstWhere((log) => log['date'] == date, orElse: () => {});

    setState(() {
      isWorkoutCompleted = completedRoutine.isNotEmpty;
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
    if (routine == null) {
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
                    MaterialPageRoute(builder: (_) => const HistoryScreen()),
                  ),
            ),
          ),
          SizedBox(
            width: 34,
            child: IconButton(
              icon: Icon(Icons.refresh),
              tooltip: 'Generate New Workout',
              onPressed: _generateNewRoutine,
            ),
          ),
          SizedBox(width: 10),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'Today: ${routine!.exercisesPerSet} exercises x ${routine!.sets}',
              style: TextStyles.boldText,
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
                            await LocalDB.deleteToday();
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
          ],
        ),
      ),
    );
  }
}
