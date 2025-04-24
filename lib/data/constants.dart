import 'package:flutter/material.dart';

import 'models/exercise_model.dart';

Color primaryColor = Color.fromARGB(255, 3, 78, 140);
Color secondaryColor = Colors.grey[200]!;
Color dullColor = Colors.grey[500]!;

class TextStyles {
  static TextStyle whiteText = TextStyle(color: Colors.white);
  static TextStyle boldText = TextStyle(fontSize: 24, fontWeight: FontWeight.bold);
  static TextStyle mediumText = TextStyle(fontSize: 18, fontWeight: FontWeight.w600);
  static TextStyle titleText = TextStyle(fontSize: 20, fontWeight: FontWeight.w500);
  static const TextStyle dialogTitle = TextStyle(fontSize: 18, fontWeight: FontWeight.w700);
}

final List<List<int>> routineOptions = [
  [1, 7], // # sets of # exercises
  [2, 4],
  [2, 5],
  [2, 6],
  [3, 3],
  [3, 4],
];

final List<Exercise> exercisePool = [
  Exercise(name: 'Crunches', amount: 25, increment: 5, videoLink: 'https://youtu.be/s0j8dENaT1g'),
  Exercise(
    name: 'Side Crunches',
    amount: 30,
    increment: 2,
    videoLink: 'https://youtu.be/shorts/PoCV2y67qiE',
  ), // 30 when 10
  Exercise(
    name: 'Alternating Crunches',
    amount: 16,
    increment: 2,
    videoLink: 'https://youtube.com/5Us8qjdBLV0',
  ), // 20 when 8, 14 when 7
  Exercise(
    name: 'Crunch Twists',
    amount: 16,
    increment: 2,
    videoLink: 'https://youtu.be/3lEKIInCo2o',
  ),
  Exercise(
    name: 'Reverse Crunches',
    amount: 15,
    increment: 5,
    videoLink: 'https://youtu.be/llXzSzEdNss',
  ),
  Exercise(
    name: 'Elevated Crunches',
    amount: 15,
    increment: 5,
    videoLink: 'https://youtu.be/ixH4kRjxqb4',
  ), // 25 when 8
  Exercise(
    name: 'Body Crunches',
    amount: 15,
    increment: 5,
    videoLink: 'https://youtu.be/ixwJ6A8qyuA',
  ),
  Exercise(name: 'Side Bends', amount: 20, increment: 2, videoLink: 'https://youtu.be/FRDPoaiD1DQ'),
  Exercise(name: 'V-Ups', amount: 10, increment: 2, videoLink: 'https://youtu.be/WAcaMktW7j0'),
  Exercise(
    name: 'Oblique V-Ups',
    amount: 12,
    increment: 4,
    videoLink: 'https://youtu.be/zXa8d5kYqAI',
  ), // mostly 12 but one 8
  Exercise(name: 'Corkscrews', amount: 12, increment: 2, videoLink: 'https://youtu.be/XjyC3bnrB7o'),
  Exercise(name: 'Twists', amount: 20, increment: 2, videoLink: 'https://youtu.be/cOAvMdawV90'),
  Exercise(
    name: 'Russian Twists',
    amount: 16,
    increment: 2,
    videoLink: 'https://youtu.be/gEFbg0AXowo',
  ), // 14 for 10, 20 for 8
  Exercise(
    name: 'Leg Lifts',
    amount: 9,
    increment: 3,
    videoLink: 'https://youtu.be/lktF6euie0o',
  ), // 12 for 8
  Exercise(
    name: 'Pulse Ups',
    amount: 10,
    increment: 2,
    videoLink: 'https://youtu.be/v30TIy18LEo',
  ), // 8 for 9, 10 for 7 and 8, 12 for 10
  Exercise(
    name: 'Pendulums',
    amount: 12,
    increment: 2,
    videoLink: 'https://youtu.be/u4JkRwCc13E',
  ), // 10 for 7
  Exercise(
    name: 'Scissors',
    amount: 40,
    increment: 2,
    videoLink: 'https://youtube.com/shorts/waIXZ0LA1YE',
  ), // 38 for 8, 40 for 10
  Exercise(
    name: 'Mountain Climbers',
    amount: 20,
    increment: 2,
    videoLink: 'https://youtu.be/4ByPbOSfYsg',
  ),
  Exercise(
    name: 'Push Throughs',
    amount: 20,
    increment: 5,
    videoLink: 'https://youtu.be/a6ytbdII7Ps',
  ),
  Exercise(name: 'Bicycles', amount: 20, increment: 2, videoLink: 'https://youtu.be/251erijgyA0'),
  Exercise(
    name: 'Planks Knee to Elbow',
    amount: 16,
    increment: 2,
    videoLink: 'https://youtube.com/shorts/vhnQR5lCF-U',
  ),
  Exercise(
    name: 'Plank',
    amount: 30,
    isTimed: true,
    increment: 15,
    videoLink: 'https://youtu.be/hvZbp_3O9rI',
  ),
  Exercise(
    name: 'Side Plank',
    amount: 30,
    isTimed: true,
    increment: 15,
    videoLink: 'https://youtu.be/6--6Q-dPYns',
  ),
  Exercise(
    name: 'Hollow Rock Hold',
    amount: 10,
    isTimed: true,
    increment: 5,
    videoLink: 'https://youtu.be/4xRpGgttca8',
  ),
  Exercise(name: 'Goalies', amount: 20, increment: 5, videoLink: 'https://youtu.be/gDrMWkoQ1rY'),
];
