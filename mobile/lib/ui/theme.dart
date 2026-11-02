import 'package:flutter/material.dart';

/// Colours shared with the registry portal.
abstract final class Palette {
  static const ink = Color(0xFF0F1B17);
  static const ink2 = Color(0xFF3E4C47);
  static const muted = Color(0xFF5A6862);
  static const ground = Color(0xFFF4F6F4);
  static const line = Color(0xFFDFE5E1);
  static const lineStrong = Color(0xFFCDD5D0);
  static const soft = Color(0xFFEEF1EF);
  static const green = Color(0xFF0B6E4F);
  static const greenInk = Color(0xFF0A5A41);
  static const greenTint = Color(0xFFE3F2EC);
  static const gold = Color(0xFFE0A526);
  static const red = Color(0xFFB42318);
  static const redText = Color(0xFFA4210F);
  static const redInk = Color(0xFF7A1A10);
  static const redTint = Color(0xFFFDECEA);
  static const redLine = Color(0xFFF0C4BE);
  static const amber = Color(0xFFB7791F);
  static const amberInk = Color(0xFF6B4104);
  static const amberTint = Color(0xFFFEF3DC);
  static const amberChip = Color(0xFFFCEBC4);
  static const amberLine = Color(0xFFF3D9A4);
  static const blue = Color(0xFF1D4ED8);
  static const blueTint = Color(0xFFEAF0FD);
}

const monoFont = 'IBMPlexMono';
const mono = TextStyle(fontFamily: monoFont, fontWeight: FontWeight.w500);

ThemeData cadastraTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: Palette.green).copyWith(
    primary: Palette.green,
    onPrimary: Colors.white,
    secondaryContainer: Palette.greenTint,
    onSecondaryContainer: Palette.greenInk,
    surface: Colors.white,
    onSurface: Palette.ink,
    onSurfaceVariant: Palette.ink2,
    outline: Palette.lineStrong,
    outlineVariant: Palette.line,
    error: Palette.red,
  );
  final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(14));
  const buttonText = TextStyle(fontFamily: 'IBMPlexSans', fontSize: 16, fontWeight: FontWeight.w600);
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: 'IBMPlexSans',
    scaffoldBackgroundColor: Palette.ground,
    appBarTheme: const AppBarTheme(
      backgroundColor: Palette.ground,
      surfaceTintColor: Colors.transparent,
      foregroundColor: Palette.ink,
      titleTextStyle: TextStyle(fontFamily: 'IBMPlexSans', fontSize: 20, fontWeight: FontWeight.w700, color: Palette.ink),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(minimumSize: const Size(48, 52), shape: shape, textStyle: buttonText),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: shape,
        foregroundColor: Palette.ink,
        side: const BorderSide(color: Palette.lineStrong),
        textStyle: buttonText.copyWith(fontSize: 15),
      ),
    ),
    textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(textStyle: buttonText.copyWith(fontSize: 15))),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: Palette.green,
      foregroundColor: Colors.white,
      extendedTextStyle: buttonText,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Palette.lineStrong)),
      enabledBorder:
          OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Palette.lineStrong)),
      focusedBorder:
          OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Palette.green, width: 2)),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        backgroundColor: Palette.soft,
        selectedBackgroundColor: Colors.white,
        selectedForegroundColor: Palette.ink,
        foregroundColor: Palette.ink2,
        side: const BorderSide(color: Palette.soft, width: 4),
        minimumSize: const Size(48, 48),
        textStyle: buttonText.copyWith(fontSize: 15),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: Palette.greenTint,
      surfaceTintColor: Colors.transparent,
      labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
            fontFamily: 'IBMPlexSans',
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected) ? FontWeight.w600 : FontWeight.w500,
            color: states.contains(WidgetState.selected) ? Palette.greenInk : Palette.ink2,
          )),
      iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(color: states.contains(WidgetState.selected) ? Palette.greenInk : Palette.ink2)),
    ),
    dialogTheme: DialogThemeData(backgroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating, backgroundColor: Palette.ink),
    dividerTheme: const DividerThemeData(color: Palette.line),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: Palette.green, linearTrackColor: Palette.greenTint),
  );
}
