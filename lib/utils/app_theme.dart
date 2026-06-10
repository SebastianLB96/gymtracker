// ============================================================
// app_theme.dart - GymTracker
// Se define la paleta de colores y estilos visuales globales
// de la aplicación. Centraliza el diseño para que todos los
// botones, campos, tarjetas y textos de los ejercicios y
// registros de entrenamiento tengan coherencia visual.
// ============================================================

import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF185FA5);
  static const Color primaryLight = Color(0xFFE6F1FB);
  static const Color primaryBorder = Color(0xFFB5D4F4);
  static const Color primaryIcon = Color(0xFF378ADD);
  static const Color primaryDark = Color(0xFF0C447C);
  static const Color success = Color(0xFF3B6D11);
  static const Color successLight = Color(0xFFEAF3DE);
  static const Color fieldBg = Color(0xFFF8FBFF);
  static const Color surface = Color(0xFFF8F8F8);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF5F5E5A);
  static const Color textHint = Color(0xFFB4B2A9);
  static const Color border = Color(0xFFD3D1C7);

  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: surface,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: textPrimary,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: TextStyle(
            color: textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w500,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0x22000000), width: 0.5),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            textStyle: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w500),
            elevation: 0,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: fieldBg,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: primaryBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: primaryBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: primary, width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          hintStyle: const TextStyle(color: textHint, fontSize: 14),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: primary,
          unselectedItemColor: Color(0xFF888780),
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle:
              TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
          unselectedLabelStyle: TextStyle(fontSize: 11),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: const Color(0xFFF1EFE8),
          selectedColor: primaryLight,
          labelStyle: const TextStyle(fontSize: 13),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          side: BorderSide.none,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        ),
      );

  static Color grupoColor(String grupo) {
    switch (grupo) {
      case 'Push':
        return primary;
      case 'Pull':
        return success;
      case 'Pierna':
        return const Color(0xFF854F0B);
      default:
        return const Color(0xFF444441);
    }
  }

  static Color grupoBgColor(String grupo) {
    switch (grupo) {
      case 'Push':
        return primaryLight;
      case 'Pull':
        return successLight;
      case 'Pierna':
        return const Color(0xFFFAEEDA);
      default:
        return const Color(0xFFF1EFE8);
    }
  }
}
