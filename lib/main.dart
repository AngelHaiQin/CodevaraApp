import 'package:flutter/material.dart';
import 'screens/code_screen.dart';

void main() {
  runApp(MaterialApp(
    title: 'Codevara',
    theme: ThemeData(primarySwatch: Colors.blue),
    home: CodeScreen(),
    debugShowCheckedModeBanner: false,
  ));
}