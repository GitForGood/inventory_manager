import 'package:flutter/material.dart';

class NixieTubeTheme {
  // Primary colors - warm orange-amber glow
  static const Color primaryColor = Color(0xFFFF6B35);
  static const Color primaryLight = Color(0xFFFF9E6B);
  static const Color primaryDark = Color(0xFFD94A1A);

  // Secondary colors - deep warm tones
  static const Color secondaryColor = Color(0xFFFFAA5C);
  static const Color secondaryLight = Color(0xFFFFCC8F);
  static const Color secondaryDark = Color(0xFFE58B2A);

  // Background colors - dark with vintage feel
  static const Color backgroundColor = Color(0xFF1A1A1A);
  static const Color surfaceColor = Color(0xFF2D2D2D);
  static const Color cardColor = Color(0xFF363636);

  // Accent colors
  static const Color accentGlow = Color(0xFFFFD700);
  static const Color errorColor = Color(0xFFCF6679);

  // Text colors
  static const Color textPrimary = Color(0xFFFFEEDD);
  static const Color textSecondary = Color(0xFFBBBBBB);

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

  // High Contrast Colors
  static const Color hcPrimaryColor = Color(0xFFFF8C00); // More vibrant orange
  static const Color hcPrimaryLight = Color(0xFFFFB84D);
  static const Color hcPrimaryDark = Color(0xFFCC6600);

  static const Color hcSecondaryColor = Color(
    0xFFFFCC00,
  ); // Brighter yellow-amber
  static const Color hcSecondaryLight = Color(0xFFFFE066);
  static const Color hcSecondaryDark = Color(0xFFCC9900);

  static const Color hcBackgroundDark = Color(
    0xFF000000,
  ); // Pure black for maximum contrast
  static const Color hcSurfaceDark = Color(0xFF1A1A1A);
  static const Color hcCardDark = Color(0xFF2A2A2A);

  static const Color hcBackgroundLight = Color(0xFFFFFFFF); // Pure white
  static const Color hcSurfaceLight = Color(0xFFF0F0F0);

  static const Color hcTextPrimary = Color(0xFFFFFFFF); // Pure white text
  static const Color hcTextSecondary = Color(0xFFCCCCCC);
  static const Color hcTextDark = Color(
    0xFF000000,
  ); // Pure black text for light theme

  static const Color hcAccentGlow = Color(0xFFFFFF00); // Bright yellow
  static const Color hcErrorColor = Color(0xFFFF3333); // Bright red
  static const Color hcSuccessColor = Color(0xFF00FF00); // Bright green

  // High contrast border width
  static const double hcBorderWidth = 2.0;

  static ThemeData get highContrastDarkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: hcPrimaryColor,
        primaryContainer: hcPrimaryDark,
        secondary: hcSecondaryColor,
        secondaryContainer: hcSecondaryDark,
        surface: hcSurfaceDark,
        background: hcBackgroundDark,
        error: hcErrorColor,
        onPrimary: hcTextDark,
        onSecondary: hcTextDark,
        onSurface: hcTextPrimary,
        onBackground: hcTextPrimary,
        outline: hcTextPrimary,
      ),
      scaffoldBackgroundColor: hcBackgroundDark,
      cardColor: hcCardDark,

      // AppBar theme
      appBarTheme: AppBarTheme(
        backgroundColor: hcBackgroundDark,
        foregroundColor: hcPrimaryColor,
        elevation: elevationNone,
        centerTitle: false,
        toolbarHeight: appBarHeight,
        titleTextStyle: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: hcTextPrimary,
        ),
        iconTheme: const IconThemeData(
          color: hcPrimaryColor,
          size: iconSizeMedium,
        ),
      ),

      // Card theme
      cardTheme: CardThemeData(
        color: hcCardDark,
        elevation: elevationMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: const BorderSide(color: hcPrimaryColor, width: hcBorderWidth),
        ),
        margin: const EdgeInsets.all(spaceMd),
      ),

      // Button themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: hcPrimaryColor,
          foregroundColor: hcTextDark,
          minimumSize: const Size(64, buttonHeightLarge),
          padding: const EdgeInsets.symmetric(
            horizontal: spaceLg,
            vertical: spaceMd,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLg),
            side: const BorderSide(color: hcTextPrimary, width: hcBorderWidth),
          ),
          elevation: elevationMedium,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: hcPrimaryColor,
          foregroundColor: hcTextDark,
          minimumSize: const Size(64, buttonHeightLarge),
          padding: const EdgeInsets.symmetric(
            horizontal: spaceLg,
            vertical: spaceMd,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLg),
            side: const BorderSide(color: hcTextPrimary, width: hcBorderWidth),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: hcPrimaryColor,
          minimumSize: const Size(64, buttonHeightLarge),
          padding: const EdgeInsets.symmetric(
            horizontal: spaceMd,
            vertical: spaceMd,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLg),
            side: const BorderSide(color: hcPrimaryColor, width: hcBorderWidth),
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
          foregroundColor: hcPrimaryColor,
          side: const BorderSide(color: hcPrimaryColor, width: hcBorderWidth),
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
        backgroundColor: hcPrimaryColor,
        foregroundColor: hcTextDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXl),
          side: const BorderSide(color: hcTextPrimary, width: hcBorderWidth),
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
        fillColor: hcSurfaceDark,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spaceMd,
          vertical: spaceMd,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(
            color: hcTextPrimary,
            width: hcBorderWidth,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(
            color: hcTextPrimary,
            width: hcBorderWidth,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(
            color: hcPrimaryColor,
            width: hcBorderWidth + 1,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(
            color: hcErrorColor,
            width: hcBorderWidth,
          ),
        ),
        labelStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: hcTextPrimary,
        ),
      ),

      // List tile theme
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spaceMd,
          vertical: spaceMd,
        ),
        minVerticalPadding: spaceMd,
        tileColor: hcSurfaceDark,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: hcPrimaryColor, width: 1),
        ),
      ),

      // Bottom navigation bar
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: hcBackgroundDark,
        selectedItemColor: hcPrimaryColor,
        unselectedItemColor: hcTextSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: elevationHigh,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),

      // Dialog theme
      dialogTheme: DialogThemeData(
        backgroundColor: hcSurfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: const BorderSide(color: hcPrimaryColor, width: hcBorderWidth),
        ),
        elevation: elevationHigh,
      ),

      // Divider theme
      dividerTheme: const DividerThemeData(
        color: hcTextPrimary,
        space: spaceMd,
        thickness: hcBorderWidth,
      ),

      // Text theme with heavier weights
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: hcTextPrimary,
          fontSize: 57,
          fontWeight: FontWeight.w700,
        ),
        displayMedium: TextStyle(
          color: hcTextPrimary,
          fontSize: 45,
          fontWeight: FontWeight.w700,
        ),
        displaySmall: TextStyle(
          color: hcTextPrimary,
          fontSize: 36,
          fontWeight: FontWeight.w700,
        ),
        headlineLarge: TextStyle(
          color: hcTextPrimary,
          fontSize: 32,
          fontWeight: FontWeight.w700,
        ),
        headlineMedium: TextStyle(
          color: hcTextPrimary,
          fontSize: 28,
          fontWeight: FontWeight.w700,
        ),
        headlineSmall: TextStyle(
          color: hcTextPrimary,
          fontSize: 24,
          fontWeight: FontWeight.w700,
        ),
        titleLarge: TextStyle(
          color: hcTextPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: TextStyle(
          color: hcTextPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
        titleSmall: TextStyle(
          color: hcTextPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: TextStyle(
          color: hcTextPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        bodyMedium: TextStyle(
          color: hcTextPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        bodySmall: TextStyle(
          color: hcTextSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        labelLarge: TextStyle(
          color: hcTextPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        labelMedium: TextStyle(
          color: hcTextPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        labelSmall: TextStyle(
          color: hcTextSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),

      // Icon theme
      iconTheme: const IconThemeData(
        color: hcPrimaryColor,
        size: iconSizeMedium,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: primaryColor,
        primaryContainer: primaryDark,
        secondary: secondaryColor,
        secondaryContainer: secondaryDark,
        surface: surfaceColor,
        background: backgroundColor,
        error: errorColor,
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onSurface: textPrimary,
        onBackground: textPrimary,
      ),
      scaffoldBackgroundColor: backgroundColor,
      cardColor: cardColor,

      // AppBar theme
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundColor,
        foregroundColor: primaryColor,
        elevation: elevationNone,
        centerTitle: false,
        toolbarHeight: appBarHeight,
        titleTextStyle: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
      ),

      // Card theme
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: elevationLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
        margin: const EdgeInsets.all(spaceMd),
      ),

      // Button themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.black,
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
          foregroundColor: primaryColor,
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
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor),
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
        backgroundColor: primaryColor,
        foregroundColor: Colors.black,
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
        fillColor: surfaceColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spaceMd,
          vertical: spaceMd,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: textSecondary, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: textSecondary, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
      ),

      // List tile theme
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spaceMd,
          vertical: spaceSm,
        ),
        minVerticalPadding: spaceSm,
        tileColor: surfaceColor,
      ),

      // Bottom navigation bar
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: backgroundColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: elevationMedium,
      ),

      // Dialog theme
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
        elevation: elevationHigh,
      ),

      // Divider theme
      dividerTheme: DividerThemeData(
        color: textSecondary.withOpacity(0.2),
        space: spaceMd,
        thickness: 1,
      ),

      // Text theme
      textTheme: TextTheme(
        displayLarge: TextStyle(
          color: textPrimary,
          fontSize: 57,
          fontWeight: FontWeight.w400,
        ),
        displayMedium: TextStyle(
          color: textPrimary,
          fontSize: 45,
          fontWeight: FontWeight.w400,
        ),
        displaySmall: TextStyle(
          color: textPrimary,
          fontSize: 36,
          fontWeight: FontWeight.w400,
        ),
        headlineLarge: TextStyle(
          color: textPrimary,
          fontSize: 32,
          fontWeight: FontWeight.w400,
        ),
        headlineMedium: TextStyle(
          color: textPrimary,
          fontSize: 28,
          fontWeight: FontWeight.w400,
        ),
        headlineSmall: TextStyle(
          color: textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.w400,
        ),
        titleLarge: TextStyle(
          color: textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w500,
        ),
        titleMedium: TextStyle(
          color: textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        titleSmall: TextStyle(
          color: textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(
          color: textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
        bodyMedium: TextStyle(
          color: textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        bodySmall: TextStyle(
          color: textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        labelLarge: TextStyle(
          color: textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        labelMedium: TextStyle(
          color: textPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        labelSmall: TextStyle(
          color: textSecondary,
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
