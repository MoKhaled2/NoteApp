import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const _fontFamily = 'Inter';

  // Light Color Scheme
  static const _lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF212121),
    onPrimary: Colors.white,
    secondary: Color(0xFF757575),
    onSecondary: Colors.white,
    tertiary: Color(0xFF5E35B1),
    onTertiary: Colors.white,
    error: Color(0xFFD32F2F),
    onError: Colors.white,
    surface: Color(0xFFFAFAFA),
    onSurface: Color(0xFF212121),
    outline: Color(0xFFE0E0E0),
  );

  // Dark Color Scheme
  static const _darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Colors.white,
    onPrimary: Color(0xFF121212),
    secondary: Color(0xFFBDBDBD),
    onSecondary: Color(0xFF1E1E1E),
    tertiary: Color(0xFF7E57C2),
    onTertiary: Colors.white,
    error: Color(0xFFCF6679),
    onError: Colors.black,
    surface: Color(0xFF121212),
    onSurface: Color(0xFFEEEEEE),
    outline: Color(0xFF424242),
  );

  static ThemeData get lightTheme => _createTheme(_lightColorScheme);
  static ThemeData get darkTheme => _createTheme(_darkColorScheme);

  static ThemeData _createTheme(ColorScheme colorScheme) {
    final textTheme = GoogleFonts.interTextTheme(
      ThemeData(brightness: colorScheme.brightness).textTheme,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      textTheme: textTheme.copyWith(
        displayLarge: textTheme.displayLarge?.copyWith(fontWeight: FontWeight.bold),
        displayMedium: textTheme.displayMedium?.copyWith(fontWeight: FontWeight.bold),
        headlineMedium: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w600),
        titleLarge: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.bold,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.tertiary,
        foregroundColor: colorScheme.onTertiary,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        filled: true,
        fillColor: colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: colorScheme.brightness == Brightness.light
                  ? colorScheme.outline
                  : Colors.transparent,
            )),
        color: colorScheme.surface,
      ),
    );
  }
}
