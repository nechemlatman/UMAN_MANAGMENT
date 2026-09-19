import 'package:flutter/material.dart';

abstract final class AppSpace {
  static const xs = 4.0, s = 8.0, m = 12.0, l = 16.0, xl = 24.0, xxl = 32.0;
  static const formWidth = 640.0, contentWidth = 960.0, touch = 48.0;
}

abstract final class AppTheme {
  static const primary = Color(0xFF244A73), secondary = Color(0xFF526579);
  static const background = Color(0xFFF5F7FA), surface = Color(0xFFFFFFFF);
  static const text = Color(0xFF17212B), secondaryText = Color(0xFF52606D);
  static const border = Color(0xFFCBD2D9), success = Color(0xFF23633B);
  static const warning = Color(0xFF805500), error = Color(0xFFB3261E);
  static ThemeData theme(Brightness brightness) {
    var scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
    );
    if (brightness == Brightness.light) {
      scheme = scheme.copyWith(
        primary: primary,
        onPrimary: surface,
        secondary: secondary,
        surface: surface,
        onSurface: text,
        onSurfaceVariant: secondaryText,
        outlineVariant: border,
        error: error,
      );
    }
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: brightness == Brightness.light
          ? background
          : scheme.surface,
      visualDensity: VisualDensity.standard,
      textTheme: const TextTheme(
        headlineSmall: TextStyle(
          fontSize: 24,
          height: 32 / 24,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          height: 28 / 20,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          fontSize: 18,
          height: 26 / 18,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(fontSize: 16, height: 24 / 16),
        bodyMedium: TextStyle(fontSize: 14, height: 20 / 14),
        bodySmall: TextStyle(fontSize: 12, height: 18 / 12),
        labelLarge: TextStyle(fontSize: 14, height: 20 / 14),
      ),
      dialogTheme: DialogThemeData(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.all(AppSpace.l),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(AppSpace.touch, AppSpace.touch),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(AppSpace.touch, AppSpace.touch),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
    );
  }
}

abstract final class BidiTextFormatter {
  static String isolate(String text) => '\u2068$text\u2069';
}
