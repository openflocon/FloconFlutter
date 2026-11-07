import 'package:flutter/material.dart';

/// Same tokens as the Flocon Desktop dark theme, so the sample looks like the app it is debugged with.
class SampleTheme {
  static const bg = Color(0xFF111111);
  static const surface = Color(0xFF151515);
  static const surfaceHigh = Color(0xFF1F1F1F);
  static const surfaceHighest = Color(0xFF282828);
  static const line = Color(0xFF2A2A2A);
  static const ink = Color(0xFFECECEC);
  static const inkMuted = Color(0xFFA3A3A3);
  static const inkFaint = Color(0xFF828282);
  static const accent = Color(0xFFF5B440);
  static const onAccent = Color(0xFF1C1405);
  static const success = Color(0xFF4FD08A);
  static const warning = Color(0xFFF7A531);
  static const error = Color(0xFFFF6D6D);

  static ThemeData get data {
    final base = ThemeData(brightness: Brightness.dark, useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: bg,
      colorScheme: const ColorScheme.dark(
        primary: accent,
        onPrimary: onAccent,
        surface: surface,
        onSurface: ink,
        error: error,
        outline: line,
      ),
      textTheme: base.textTheme.apply(bodyColor: ink, displayColor: ink),
      appBarTheme: const AppBarTheme(
        backgroundColor: bg,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
      ),
      dividerTheme: const DividerThemeData(color: line, thickness: 1, space: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceHigh,
        contentPadding: const EdgeInsets.all(14),
        hintStyle: const TextStyle(color: inkFaint),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: line)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: line)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: accent)),
      ),
      snackBarTheme: const SnackBarThemeData(backgroundColor: surfaceHighest, contentTextStyle: TextStyle(color: ink)),
    );
  }
}

/// The color of each family of plugins, used for its icon and its tile.
enum SampleCategory {
  network(Color(0xFF5EAAF7)),
  database(Color(0xFF3FCFB5)),
  analytics(Color(0xFFB494FF)),
  featureFlags(Color(0xFFF5B440)),
  table(Color(0xFFA9D65E)),
  deeplink(Color(0xFFF483C2)),
  timeline(Color(0xFF6FD6F0)),
  crash(Color(0xFFFF6D6D)),
  neutral(Color(0xFFA8ADB6));

  const SampleCategory(this.color);
  final Color color;

  /// Translucent background behind the icon.
  Color get soft => color.withValues(alpha: 0.13);
}
