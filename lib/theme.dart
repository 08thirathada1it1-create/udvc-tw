import 'package:flutter/material.dart';

const Color kAccent = Color(0xFFD85A32);

ThemeData buildTheme(Brightness b) {
  final dark = b == Brightness.dark;
  final scheme = ColorScheme.fromSeed(seedColor: kAccent, brightness: b).copyWith(primary: kAccent);
  final bg = dark ? const Color(0xFF1A0C06) : const Color(0xFFFFF8F3);
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: bg,
    appBarTheme: AppBarTheme(
      backgroundColor: bg,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: const TextStyle(color: kAccent, fontSize: 20, fontWeight: FontWeight.w800),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: dark ? const Color(0xFF241209) : Colors.white,
      indicatorColor: kAccent.withOpacity(.25),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),
  );
}
