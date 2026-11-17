import 'package:flutter/material.dart';

ThemeData lightMode = ThemeData(
  brightness: Brightness.light,
  scaffoldBackgroundColor: const Color(0xFFEEF4FF),

  colorScheme: const ColorScheme.light(
    background: Color(0xFFEEF4FF),
    surface: Color(0xFFFFFFFF),
    primary: Color(0xFF2563EB),
    secondary: Color(0xFFDBEAFE),
    tertiary: Color(0xFFFFFFFF),
    inversePrimary: Color(0xFF1E40AF),
  ),
);
