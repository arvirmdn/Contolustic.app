import 'package:flutter/material.dart';

/// Identitas visual contolustic: arang gelap, aksen jingga bara, dan teal.
const kInk = Color(0xFF0B0D12);
const kSurface = Color(0xFF151923);
const kSurfaceHigh = Color(0xFF1D2330);
const kEmber = Color(0xFFFF7A3D);
const kTeal = Color(0xFF3DDBD9);

ThemeData buildTheme() {
  final scheme = ColorScheme.dark(
    primary: kEmber,
    onPrimary: Colors.black,
    secondary: kTeal,
    onSecondary: Colors.black,
    surface: kInk,
    onSurface: Colors.white,
    surfaceContainerLowest: kInk,
    surfaceContainerLow: kSurface,
    surfaceContainer: kSurface,
    surfaceContainerHigh: kSurfaceHigh,
    surfaceContainerHighest: const Color(0xFF262D3B),
    outlineVariant: const Color(0xFF353D4E),
    error: const Color(0xFFFF5C5C),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: kInk,
    appBarTheme: const AppBarTheme(
      backgroundColor: kInk,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        color: Colors.white,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: kSurfaceHigh,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: const BorderSide(color: kEmber, width: 1.5),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: kSurfaceHigh,
      contentTextStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}
