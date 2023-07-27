import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';

class ThemeApp {
  static ThemeData theme = ThemeData.from(
    colorScheme: const ColorScheme.dark(
      background: Color(0xFF222244),
    ),
    textTheme: GoogleFonts.robotoMonoTextTheme().copyWith(
      titleMedium: const TextStyle(color: Colors.white),
      displayMedium: const TextStyle(
        color: Colors.white,
        fontSize: 48,
      ),
      displaySmall: const TextStyle(
          color: Colors.white, fontSize: 30, fontFamily: "RobotoMono"),
    ),
  ).copyWith(
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.all(16),
      ),
    ),
    buttonTheme: const ButtonThemeData(
      buttonColor: Color(0xFF222244),
      textTheme: ButtonTextTheme.primary,
    ),
  );

  static const Color green = Color(0xFF80FFAE);
  static const Color red = Color(0xFFF1628C);
  static const Color yellow = Color(0xFFFAD000);
}
