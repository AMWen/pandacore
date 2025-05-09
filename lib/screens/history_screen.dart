import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../data/constants.dart';
import '../data/services/localdb_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  HistoryScreenState createState() => HistoryScreenState();
}

class HistoryScreenState extends State<HistoryScreen> {
  Map<DateTime, List<String>> _events = {};
  int _streak = 0;
  bool _todayCompleted = false;

  @override
  void initState() {
    super.initState();
    _loadWorkoutDates();
  }

  void _loadWorkoutDates() async {
    final dates = await LocalDB.getLoggedDates();
    final events = <DateTime, List<String>>{};

    for (var date in dates) {
      final clean = DateTime(date.year, date.month, date.day);
      events[clean] = ['Workout'];
    }

    final result = _calculateStreak(dates);

    setState(() {
      _events = events;
      _streak = result.streak;
      _todayCompleted = result.todayCompleted;
    });
  }

  ({int streak, bool todayCompleted}) _calculateStreak(List<DateTime> dates) {
    if (dates.isEmpty) return (streak: 0, todayCompleted: false);

    final dateSet = dates.map((d) => DateTime(d.year, d.month, d.day)).toSet();

    int streak = 0;
    DateTime current = DateTime.now();
    bool todayCompleted = false;

    if (dateSet.contains(DateTime(current.year, current.month, current.day))) {
      streak++;
      todayCompleted = true;
    }
    current = current.subtract(Duration(days: 1));

    while (dateSet.contains(DateTime(current.year, current.month, current.day))) {
      streak++;
      current = current.subtract(Duration(days: 1));
    }

    return (streak: streak, todayCompleted: todayCompleted);
  }

  List<String> _getEventsForDay(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    return _events[key] ?? [];
  }

  Future<void> _showRoutineForDate(DateTime date) async {
    final routine = await LocalDB.getRoutineForDate(date);
    final dateString = date.toIso8601String().substring(0, 10);

    if (routine == null && mounted) {
      showErrorSnackbar(context, 'No workout found for this date');
      return;
    }

    if (mounted) {
      showDialog(
        context: context,
        builder:
            (_) => AlertDialog(
              title: Text('Workout for $dateString', style: TextStyles.dialogTitle),
              content: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(text: '${routine!.sets} sets\n', style: TextStyles.mediumText),
                    TextSpan(
                      text: routine.exercises.map((e) => e.formatText()).join('\n'),
                      style: TextStyles.normalText,
                    ),
                  ],
                ),
              ),
              actions: [FilledButton(onPressed: () => Navigator.pop(context), child: Text('OK'))],
            ),
      );
    }
  }

  void showErrorSnackbar(BuildContext context, String message) {
    Duration duration =
        message.contains('Error') ? Duration(milliseconds: 1500) : Duration(milliseconds: 800);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), duration: duration));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Workout History'),
        actions: [
          SizedBox(
            width: 34,
            child: IconButton(
              icon: Icon(Icons.upload),
              tooltip: 'Import',
              onPressed: () async {
                String result = await LocalDB.importProgress();
                if (context.mounted) {
                  showErrorSnackbar(context, result);
                }
              },
            ),
          ),
          SizedBox(
            width: 34,
            child: IconButton(
              icon: Icon(Icons.save),
              tooltip: 'Export',
              onPressed: () async {
                String result = await LocalDB.exportProgress();
                if (context.mounted) {
                  showErrorSnackbar(context, result);
                }
              },
            ),
          ),
          SizedBox(width: 10),
        ],
      ),
      body: Column(
        children: [
          SizedBox(height: 16),
          TableCalendar(
            firstDay: DateTime.utc(2025, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: DateTime.now(),
            eventLoader: _getEventsForDay,
            calendarStyle: CalendarStyle(
              markerDecoration: BoxDecoration(color: primaryColor, shape: BoxShape.circle),
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: false, // hide the "2 weeks" / "Month" button
            ),
            onDaySelected: (selectedDay, focusedDay) {
              _showRoutineForDate(selectedDay);
            },
          ),
          if (_streak == 0) ...[
            SizedBox(height: 16),
            Text("Let's start powering up your panda!", style: TextStyles.mediumText),
            Image.asset('assets/images/sad_baby_panda.png', width: pandaWidth),
          ],
          if (_streak > 0 && _streak < 7) ...[
            SizedBox(height: 16),
            Text(
              _todayCompleted
                  ? (_streak == 1 ? '1 day completed! Way to go!' : '🔥 $_streak day streak!')
                  : 'Keep going! Extend your streak to ${_streak + 1} days!',
              style: TextStyles.mediumText,
            ),
            Image.asset('assets/images/baby_panda.png', width: pandaWidth),
          ],
          if (_streak >= 7) ...[
            SizedBox(height: 16),
            Text(
              _todayCompleted
                  ? "You're a beast! 🔥 $_streak day streak"
                  : 'Keep going! Extend your streak to ${_streak + 1} days!',
              style: TextStyles.mediumText,
            ),
            Image.asset('assets/images/strong_panda.png', width: pandaWidth),
          ],
        ],
      ),
    );
  }
}
