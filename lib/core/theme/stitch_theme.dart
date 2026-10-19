import 'package:flutter/material.dart';

/// Telegram-inspired native Material 3 design. No HTML or WebView at runtime.
class StitchTheme {
  static const primary = Color(0xff2481cc);
  static const primaryContainer = Color(0xff2481cc);
  static const secondary = Color(0xff52a6e7);
  static const canvas = Color(0xfff4f7fa);
  static const ink = Color(0xff17212b);
  static const muted = Color(0xff788895);
  static const pale = Color(0xffe9f2fa);
  static const outgoing = Color(0xffdff4d4);
  static const incoming = Colors.white;

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(seedColor: primary, primary: primary, surface: canvas);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: canvas,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: ink,
        titleTextStyle: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: ink),
      ),
      cardTheme: CardThemeData(color: Colors.white, elevation: 0, margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: pale,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(
        backgroundColor: primary, minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)))),
      navigationBarTheme: const NavigationBarThemeData(backgroundColor: Colors.white,
        indicatorColor: Color(0xffdceefc), height: 70),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary, foregroundColor: Colors.white),
      chipTheme: ChipThemeData(backgroundColor: pale, selectedColor: const Color(0xffd8ecfb),
        side: BorderSide.none, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
      dividerTheme: const DividerThemeData(color: Color(0xffeaf0f5), thickness: 0.7),
    );
  }
  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(seedColor: primary, brightness: Brightness.dark);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xff101923),
      appBarTheme: const AppBarTheme(backgroundColor: Color(0xff17212b), foregroundColor: Colors.white, surfaceTintColor: Colors.transparent),
      cardTheme: CardThemeData(color: const Color(0xff202e3b), elevation: 0, margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
      navigationBarTheme: const NavigationBarThemeData(backgroundColor: Color(0xff17212b), indicatorColor: Color(0xff304c64)),
      inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: const Color(0xff243442),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none)),
    );
  }
}
