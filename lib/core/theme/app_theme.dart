import 'package:flutter/material.dart';

class AppTheme {
  static final ThemeData light = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF0B6E4F),
      brightness: Brightness.light,
    ),
    visualDensity: VisualDensity.compact,
    scaffoldBackgroundColor: const Color(0xFFF5F7F6),
  );
}
