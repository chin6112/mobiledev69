import 'package:flutter/material.dart';

class AppTheme {
  static const _seed = Color(0xFF176B87);

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) => ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
    ),
    useMaterial3: true,
    cardTheme: const CardThemeData(elevation: 0, margin: EdgeInsets.zero),
  );
}
