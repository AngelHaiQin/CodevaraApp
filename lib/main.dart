import 'package:flutter/material.dart';
import 'screens/code_screen.dart';
import 'screens/quiz_screen.dart';
import 'screens/nhom_screen.dart';
import 'screens/cong_dong_screen.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(MaterialApp(
    title: 'Codevara',
    theme: ThemeData(primarySwatch: Colors.blue),
    home: HomeScreen(),
    debugShowCheckedModeBanner: false,
  ));
}