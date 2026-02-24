import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF1B4B27);
  static const Color background = Color(0xFFF5F7F5);
  static const Color textDark = Color(0xFF1D1D1D);
  static const Color textLight = Color(0xFF757575);

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    primaryColor: primary,
    scaffoldBackgroundColor: background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      // FIX: Replaced deprecated 'background' with 'surface'
      surface: background, 
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.black),
      titleTextStyle: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
    ),
  );
}