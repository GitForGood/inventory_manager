import 'dart:ui';
import 'package:flutter/material.dart';

/// Theme extension for custom card variants (filled and outlined)
class CardVariants extends ThemeExtension<CardVariants> {
  final CardTheme outlinedCard;
  final CardTheme filledCard;

  const CardVariants({
    required this.outlinedCard,
    required this.filledCard,
  });

  @override
  CardVariants copyWith({
    CardTheme? outlinedCard,
    CardTheme? filledCard,
  }) {
    return CardVariants(
      outlinedCard: outlinedCard ?? this.outlinedCard,
      filledCard: filledCard ?? this.filledCard,
    );
  }

  @override
  CardVariants lerp(ThemeExtension<CardVariants>? other, double t) {
    if (other is! CardVariants) return this;
    return CardVariants(
      outlinedCard: CardTheme(
        elevation: lerpDouble(outlinedCard.elevation, other.outlinedCard.elevation, t),
        margin: EdgeInsetsGeometry.lerp(outlinedCard.margin, other.outlinedCard.margin, t),
        shape: ShapeBorder.lerp(outlinedCard.shape, other.outlinedCard.shape, t),
        color: Color.lerp(outlinedCard.color, other.outlinedCard.color, t),
      ),
      filledCard: CardTheme(
        elevation: lerpDouble(filledCard.elevation, other.filledCard.elevation, t),
        margin: EdgeInsetsGeometry.lerp(filledCard.margin, other.filledCard.margin, t),
        shape: ShapeBorder.lerp(filledCard.shape, other.filledCard.shape, t),
        color: Color.lerp(filledCard.color, other.filledCard.color, t),
      ),
    );
  }

  static CardVariants? of(BuildContext context) {
    return Theme.of(context).extension<CardVariants>();
  }
}

class NixieTubeTheme {
  // Seed colors for Material 3 ColorScheme generation
  static const Color seedColor = Color.fromARGB(255, 255, 115, 0); 
  static const Color hcSeedColor = Color.fromARGB(255, 255, 140, 0); 

  // M3 Spacing Scale (mobile-optimized)
  static const double spaceXs = 4.0;
  static const double spaceSm = 8.0;
  static const double spaceMd = 16.0;
  static const double spaceLg = 24.0;
  static const double spaceXl = 32.0;
  static const double spaceXxl = 48.0;

  // M3 Component Sizing
  static const double buttonHeight = 40.0;
  static const double buttonHeightLarge = 48.0;
  static const double iconSizeSmall = 18.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeLarge = 32.0;
  static const double appBarHeight = 64.0;
  static const double bottomNavHeight = 80.0;
  static const double fabSize = 56.0;
  static const double fabSizeSmall = 40.0;

  // Border Radius (M3 uses more rounded corners)
  static const double radiusXs = 4.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 28.0;
  static const double radiusFull = 9999.0;

  // Elevation
  static const double elevationNone = 0.0;
  static const double elevationLow = 1.0;
  static const double elevationMedium = 3.0;
  static const double elevationHigh = 6.0;

  // High contrast border width
  static const double hcBorderWidth = 2.0;

  /// High contrast dark theme with increased contrast and bold styling
  static ThemeData get highContrastDarkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: hcSeedColor,
      brightness: Brightness.dark,
      // Force darker surface for maximum contrast
      surface: const Color(0xFF000000),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      extensions: [
        CardVariants(
          outlinedCard: CardTheme(
            elevation: elevationNone,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusMd),
              side: BorderSide(color: colorScheme.outline, width: hcBorderWidth),
            ),
            margin: const EdgeInsets.all(spaceMd),
          ),
          filledCard: CardTheme(
            elevation: elevationMedium,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusMd),
              side: BorderSide(color: colorScheme.primary, width: hcBorderWidth),
            ),
            margin: const EdgeInsets.all(spaceMd),
          ),
        ),
      ],

      // AppBar theme
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.primary,
        elevation: elevationNone,
        centerTitle: false,
        toolbarHeight: appBarHeight,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
        ),
        iconTheme: IconThemeData(
          color: colorScheme.primary,
          size: iconSizeMedium,
        ),
      ),
      // Card theme
      cardTheme: CardThemeData(
        elevation: elevationMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: BorderSide(color: colorScheme.primary, width: hcBorderWidth),
        ),
        margin: const EdgeInsets.all(spaceMd),
      ),

      // Button themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(64, buttonHeightLarge),
          padding: const EdgeInsets.symmetric(
            horizontal: spaceLg,
            vertical: spaceMd,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLg),
            side: BorderSide(color: colorScheme.onSurface, width: hcBorderWidth),
          ),
          elevation: elevationMedium,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, buttonHeightLarge),
          padding: const EdgeInsets.symmetric(
            horizontal: spaceLg,
            vertical: spaceMd,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLg),
            side: BorderSide(color: colorScheme.onSurface, width: hcBorderWidth),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(64, buttonHeightLarge),
          padding: const EdgeInsets.symmetric(
            horizontal: spaceMd,
            vertical: spaceMd,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLg),
            side: BorderSide(color: colorScheme.primary, width: hcBorderWidth),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            decoration: TextDecoration.underline,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: colorScheme.primary, width: hcBorderWidth),
          minimumSize: const Size(64, buttonHeightLarge),
          padding: const EdgeInsets.symmetric(
            horizontal: spaceLg,
            vertical: spaceMd,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLg),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),

      // FAB theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXl),
          side: BorderSide(color: colorScheme.onSurface, width: hcBorderWidth),
        ),
        elevation: elevationHigh,
        sizeConstraints: const BoxConstraints.tightFor(
          width: fabSize,
          height: fabSize,
        ),
      ),

      // Input decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spaceMd,
          vertical: spaceMd,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: BorderSide(
            color: colorScheme.onSurface,
            width: hcBorderWidth,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: BorderSide(
            color: colorScheme.onSurface,
            width: hcBorderWidth,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: hcBorderWidth + 1,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: BorderSide(
            color: colorScheme.error,
            width: hcBorderWidth,
          ),
        ),
        labelStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),

      // List tile theme
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spaceMd,
          vertical: spaceMd,
        ),
        minVerticalPadding: spaceMd,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: colorScheme.primary, width: 1),
        ),
      ),

      // Dialog theme
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: BorderSide(color: colorScheme.primary, width: hcBorderWidth),
        ),
        elevation: elevationHigh,
      ),

      // Divider theme
      dividerTheme: DividerThemeData(
        color: colorScheme.onSurface,
        space: spaceMd,
        thickness: hcBorderWidth,
      ),

      // Text theme with heavier weights
      textTheme: TextTheme(
        displayLarge: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 57,
          fontWeight: FontWeight.w700,
        ),
        displayMedium: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 45,
          fontWeight: FontWeight.w700,
        ),
        displaySmall: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 36,
          fontWeight: FontWeight.w700,
        ),
        headlineLarge: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 32,
          fontWeight: FontWeight.w700,
        ),
        headlineMedium: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 28,
          fontWeight: FontWeight.w700,
        ),
        headlineSmall: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 24,
          fontWeight: FontWeight.w700,
        ),
        titleLarge: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
        titleSmall: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        bodyMedium: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        bodySmall: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        labelLarge: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        labelMedium: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        labelSmall: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),

      // Icon theme
      iconTheme: IconThemeData(
        color: colorScheme.primary,
        size: iconSizeMedium,
      ),
    );
  }

  /// Standard dark theme with warm orange-amber glow
  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
      surface: Color.fromARGB(255, 14, 14, 14)
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      extensions: [
        CardVariants(
          outlinedCard: CardTheme(
            elevation: elevationNone,
            color: colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusMd),
              side: BorderSide(color: colorScheme.outlineVariant, width: 1),
            ),
            margin: const EdgeInsets.all(spaceMd),
          ),
          filledCard: CardTheme(
            elevation: elevationLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusMd),
            ),
            margin: const EdgeInsets.all(spaceMd),
          ),
        ),
      ],

      // AppBar theme
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.primary,
        elevation: elevationNone,
        centerTitle: false,
        toolbarHeight: appBarHeight,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurface,
        ),
      ),

      // Card theme
      cardTheme: CardThemeData(
        elevation: elevationLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
        margin: const EdgeInsets.all(spaceMd),
      ),

      // Button themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(64, buttonHeight),
          padding: const EdgeInsets.symmetric(
            horizontal: spaceLg,
            vertical: spaceSm,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLg),
          ),
          elevation: elevationLow,
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, buttonHeight),
          padding: const EdgeInsets.symmetric(
            horizontal: spaceLg,
            vertical: spaceSm,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLg),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(64, buttonHeight),
          padding: const EdgeInsets.symmetric(
            horizontal: spaceMd,
            vertical: spaceSm,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLg),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, buttonHeight),
          padding: const EdgeInsets.symmetric(
            horizontal: spaceLg,
            vertical: spaceSm,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLg),
          ),
        ),
      ),

      // FAB theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXl),
        ),
        elevation: elevationMedium,
        sizeConstraints: const BoxConstraints.tightFor(
          width: fabSize,
          height: fabSize,
        ),
      ),

      // Input decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spaceMd,
          vertical: spaceMd,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
      ),

      // List tile theme
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(
          horizontal: spaceMd,
          vertical: spaceSm,
        ),
        minVerticalPadding: spaceSm,
      ),

      // Dialog theme
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
        elevation: elevationHigh,
      ),

      // Divider theme
      dividerTheme: DividerThemeData(
        color: colorScheme.onSurface.withValues(alpha: 0.2),
        space: spaceMd,
        thickness: 1,
      ),

      // Text theme
      textTheme: TextTheme(
        displayLarge: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 57,
          fontWeight: FontWeight.w400,
        ),
        displayMedium: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 45,
          fontWeight: FontWeight.w400,
        ),
        displaySmall: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 36,
          fontWeight: FontWeight.w400,
        ),
        headlineLarge: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 32,
          fontWeight: FontWeight.w400,
        ),
        headlineMedium: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 28,
          fontWeight: FontWeight.w400,
        ),
        headlineSmall: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 24,
          fontWeight: FontWeight.w400,
        ),
        titleLarge: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 22,
          fontWeight: FontWeight.w500,
        ),
        titleMedium: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        titleSmall: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
        bodyMedium: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        bodySmall: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        labelLarge: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        labelMedium: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        labelSmall: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // Helper method for consistent padding
  static EdgeInsets get screenPadding => const EdgeInsets.all(spaceMd);
  static EdgeInsets get cardPadding => const EdgeInsets.all(spaceMd);
  static EdgeInsets get buttonPadding =>
      const EdgeInsets.symmetric(horizontal: spaceLg, vertical: spaceSm);
}
