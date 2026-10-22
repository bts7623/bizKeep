import 'package:flutter/material.dart';

/// docs/design.md 토큰
abstract final class C {
  static const bg = Color(0xFFF6F7FA);
  static const bgTop = Color(0xFFEEF1F7);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFF6F7F9);
  static const ink = Color(0xFF111318);
  static const inkMuted = Color(0xFF6B7280);
  static const inkFaint = Color(0xFFB0B5BE);
  static const line = Color(0xFFEEF0F3);
  static const accent = Color(0xFF2F62E6);
  static const accentTint = Color(0xFFE8EFFF);
  static const call = Color(0xFF22A95B);
  static const callTint = Color(0xFFE6F6EE);
  static const callInk = Color(0xFF1B7A47);
  static const memoBg = Color(0xFFF0F4FF);
  static const memoBorder = Color(0xFFDCE5FF);
  static const memoInk = Color(0xFF1E2F5C);
  static const memoListInk = Color(0xFF5B6475);
  static const warnBg = Color(0xFFFFF6DC);
  static const warnInk = Color(0xFF8A5A00);
  static const danger = Color(0xFFC62828);
  static const dangerTint = Color(0xFFFDECEC);
  static const navy = Color(0xFF0E1A33);
}

abstract final class R {
  static const row = 20.0;
  static const thumb = 8.0;
  static const sheet = 28.0;
  static const box = 18.0;
}

final rowShadow = [
  BoxShadow(color: C.ink.withValues(alpha: 0.04), blurRadius: 2, offset: const Offset(0, 1)),
  BoxShadow(color: C.ink.withValues(alpha: 0.05), blurRadius: 18, offset: const Offset(0, 6)),
];

final dockShadow = [
  BoxShadow(color: C.ink.withValues(alpha: 0.12), blurRadius: 30, offset: const Offset(0, 10)),
];

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: C.bg,
    colorScheme: ColorScheme.fromSeed(seedColor: C.accent, surface: C.surface),
    splashFactory: InkSparkle.splashFactory,
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(bodyColor: C.ink, displayColor: C.ink).copyWith(
          headlineLarge: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800, letterSpacing: -1.0, height: 1.05, color: C.ink),
          headlineMedium: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: -0.5, height: 1.2, color: C.ink),
          titleMedium: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: -0.2, color: C.ink),
          bodyLarge: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, letterSpacing: -0.2, color: C.ink),
          bodyMedium: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, letterSpacing: -0.2, color: C.ink),
          bodySmall: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, letterSpacing: -0.1, color: C.inkMuted),
          labelSmall: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: -0.1, color: C.inkMuted),
        ),
    inputDecorationTheme: const InputDecorationTheme(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
    bottomSheetTheme: const BottomSheetThemeData(backgroundColor: C.surface, surfaceTintColor: Colors.transparent),
    dividerColor: C.line,
  );
}
