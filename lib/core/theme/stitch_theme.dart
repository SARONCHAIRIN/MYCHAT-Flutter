import 'package:flutter/material.dart';

/// Kinetic Slate tokens from the supplied Stitch DESIGN.md.
class StitchTheme {
  static const primary = Color(0xff3525cd);
  static const primaryContainer = Color(0xff4f46e5);
  static const secondary = Color(0xff0058be);
  static const canvas = Color(0xfff8f9ff);
  static const ink = Color(0xff0b1c30);
  static const muted = Color(0xff464555);
  static const pale = Color(0xffeff4ff);

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(seedColor: primary, primary: primary, surface: canvas);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: canvas,
      appBarTheme: const AppBarTheme(backgroundColor: canvas, surfaceTintColor: Colors.transparent, foregroundColor: ink),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(backgroundColor: primaryContainer, minimumSize: const Size.fromHeight(52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))),
      navigationBarTheme: const NavigationBarThemeData(backgroundColor: Colors.white, indicatorColor: Color(0xffe2dfff), height: 72),
    );
  }
}
