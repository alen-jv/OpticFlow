import 'package:flutter/material.dart';
import '../models/session_type.dart';

/// Central design system for the 20-20-20 app.
class AppTheme {
  AppTheme._();

  // ── Palette ────────────────────────────────────────────────────────────────
  static const Color focusBg        = Color(0xFF0D1117); // deep dark navy
  static const Color focusCard      = Color(0xFF161B22);
  static const Color focusRing      = Color(0xFF6366F1); // indigo
  static const Color focusRingTrack = Color(0xFF1E2436);
  static const Color focusAccent    = Color(0xFF818CF8); // soft indigo

  static const Color breakBg        = Color(0xFF052E1A); // deep emerald dark
  static const Color breakCard      = Color(0xFF0A3D25);
  static const Color breakRing      = Color(0xFF34D399); // emerald
  static const Color breakRingTrack = Color(0xFF093D26);
  static const Color breakAccent    = Color(0xFF6EE7B7); // light mint

  static const Color textPrimary   = Color(0xFFF0F6FC);
  static const Color textSecondary = Color(0xFF8B949E);
  static const Color textMuted     = Color(0xFF484F58);

  // ── Helpers ────────────────────────────────────────────────────────────────
  static Color bgColor(SessionType s) =>
      s == SessionType.focus ? focusBg : breakBg;

  static Color cardColor(SessionType s) =>
      s == SessionType.focus ? focusCard : breakCard;

  static Color ringColor(SessionType s) =>
      s == SessionType.focus ? focusRing : breakRing;

  static Color ringTrack(SessionType s) =>
      s == SessionType.focus ? focusRingTrack : breakRingTrack;

  static Color accentColor(SessionType s) =>
      s == SessionType.focus ? focusAccent : breakAccent;

  // ── Typography ─────────────────────────────────────────────────────────────
  static const String fontFamily = 'Inter';

  static TextStyle headline(SessionType s) => TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
    color: accentColor(s),
    decoration: TextDecoration.none,
  );

  static TextStyle timerText(SessionType s) => const TextStyle(
    fontFamily: fontFamily,
    fontSize: 56,
    fontWeight: FontWeight.w200,
    letterSpacing: -2,
    color: textPrimary,
    decoration: TextDecoration.none,
  );

  static const TextStyle labelText = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.2,
    color: textSecondary,
    decoration: TextDecoration.none,
  );

  static const TextStyle counterText = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: textMuted,
    decoration: TextDecoration.none,
  );

  // ── Material ThemeData ─────────────────────────────────────────────────────
  static ThemeData themeData = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: focusBg,
    colorScheme: const ColorScheme.dark(
      primary: focusRing,
      secondary: breakRing,
      surface: focusCard,
    ),
    fontFamily: fontFamily,
    useMaterial3: true,
  );
}
