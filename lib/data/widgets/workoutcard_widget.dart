import 'package:flutter/material.dart';

import '../constants.dart';
import '../models/exercise_model.dart';
import 'countdown_widget.dart';

Widget buildWorkoutCard({
  required BuildContext context,
  required WorkoutRoutine routine,
  required bool isCompleted,
  required VoidCallback onToggleComplete,
  required void Function(String url) onLaunchUrl,
}) {
  return Card(
    margin: EdgeInsets.symmetric(vertical: 0, horizontal: 12),
    color: primaryColor,
    child: Padding(
      padding: EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children:
                routine.exercises.map((e) {
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
                    onTap: () => onLaunchUrl(e.videoLink),
                  );
                }).toList(),
          ),
          Positioned(
            right: 12,
            top: 6,
            child: GestureDetector(
              onTap: onToggleComplete,
              child: CircleAvatar(
                radius: 16,
                backgroundColor: isCompleted ? Colors.green.shade600 : dullColor,
                child: Icon(Icons.check, color: secondaryColor),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
