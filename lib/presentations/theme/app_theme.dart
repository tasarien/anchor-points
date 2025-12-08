import 'package:flutter/material.dart';

class AppColors {
  //Lighter Palette
  static const Color darkTeal = Color.fromARGB(255, 34, 70, 71);
  static const Color beige = Color(0xFFD8BC97);
  static const Color sageGreen = Color(0xFF677C69);
  static const Color paleGreen = Color.fromARGB(255, 211, 217, 212);
  static const Color terracotta = Color(0xFFC84C39);
  static const Color veryDarkTeal = Color.fromARGB(255, 7, 16, 16);

  // Darker Palette
  static const Color darkTealLight = Color(0xFF2A4647);
  static const Color beigeLight = Color(0xFFE5D1B6);
  static const Color sageGreenLight = Color.fromARGB(255, 161, 173, 163);
  static const Color terracottaLight = Color(0xFFD96958);
  static const Color veryDarkTealLight = Color(0xFF0F2020);
}

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    primaryColor: AppColors.sageGreen,
    scaffoldBackgroundColor: AppColors.beige,
    colorScheme: ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.sageGreen,
      onPrimary: AppColors.veryDarkTeal,
      secondary: AppColors.sageGreenLight,
      onSecondary: Colors.white,
      error: Colors.redAccent,
      onError: Colors.white,
      surface: AppColors.beigeLight,
      onSurface: AppColors.veryDarkTeal,
      tertiary: AppColors.darkTeal,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.beige,
      foregroundColor: AppColors.veryDarkTeal,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: AppColors.veryDarkTeal,
        fontFamily: 'EBGaramond',
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),

    tabBarTheme: TabBarThemeData(
      labelColor: AppColors.terracotta,
      unselectedLabelColor: AppColors.darkTeal,
      indicatorColor: AppColors.terracotta,
      dividerColor: AppColors.sageGreen,
    ),
    dividerTheme: DividerThemeData(
      color: AppColors.sageGreen.withOpacity(0.5),
      thickness: 1,
    ),
    cardTheme: CardThemeData(
      color: AppColors.beigeLight,
      shadowColor: AppColors.sageGreen.withOpacity(0.2),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.terracotta,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.darkTeal,
        side: BorderSide(color: AppColors.darkTeal),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.terracotta),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.sageGreen,
      foregroundColor: Colors.white,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.sageGreenLight.withOpacity(0.15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.sageGreen),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.terracotta, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.sageGreen.withOpacity(0.5)),
      ),
      labelStyle: TextStyle(color: AppColors.darkTeal),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: AppColors.terracotta,
      inactiveTrackColor: AppColors.sageGreen.withOpacity(0.3),
      thumbColor: AppColors.terracotta,
      overlayColor: AppColors.terracotta.withOpacity(0.2),
    ),
    iconTheme: IconThemeData(color: AppColors.darkTeal),
    textTheme: TextTheme(
      displayLarge: TextStyle(
        color: AppColors.veryDarkTeal,
        fontFamily: 'EBGaramond',
      ),
      displayMedium: TextStyle(
        color: AppColors.veryDarkTeal,
        fontFamily: 'EBGaramond',
      ),
      displaySmall: TextStyle(
        color: AppColors.veryDarkTeal,
        fontFamily: 'EBGaramond',
      ),
      headlineLarge: TextStyle(
        color: AppColors.veryDarkTeal,
        fontFamily: 'EBGaramond',
      ),
      headlineMedium: TextStyle(
        color: AppColors.veryDarkTeal,
        fontFamily: 'EBGaramond',
      ),
      headlineSmall: TextStyle(
        color: AppColors.veryDarkTeal,
        fontFamily: 'EBGaramond',
      ),
      titleLarge: TextStyle(
        color: AppColors.veryDarkTeal,
        fontWeight: FontWeight.bold,
        fontFamily: 'EBGaramond',
      ),
      titleMedium: TextStyle(
        color: AppColors.darkTeal,
        fontFamily: 'EBGaramond',
      ),
      titleSmall: TextStyle(
        color: AppColors.darkTeal,
        fontFamily: 'EBGaramond',
      ),
      bodyLarge: TextStyle(color: AppColors.darkTeal, fontFamily: 'EBGaramond'),
      bodyMedium: TextStyle(
        color: AppColors.darkTeal,
        fontFamily: 'EBGaramond',
      ),
      bodySmall: TextStyle(
        color: AppColors.darkTeal.withOpacity(0.7),
        fontFamily: 'EBGaramond',
      ),
      labelLarge: TextStyle(
        color: AppColors.darkTealLight,
        fontFamily: 'EBGaramond',
      ),
      labelMedium: TextStyle(
        color: AppColors.darkTealLight,
        fontFamily: 'EBGaramond',
      ),
      labelSmall: TextStyle(
        color: AppColors.darkTealLight,
        fontFamily: 'EBGaramond',
      ),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    primaryColor: AppColors.sageGreenLight,
    scaffoldBackgroundColor: AppColors.veryDarkTeal,
    colorScheme: ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.darkTeal,
      onPrimary: AppColors.beige,
      secondary: AppColors.sageGreenLight,
      onSecondary: AppColors.beigeLight,
      error: AppColors.terracotta,
      onError: Colors.white,
      surface: AppColors.veryDarkTealLight,
      onSurface: AppColors.beige,
      tertiary: AppColors.sageGreen,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.veryDarkTeal,
      foregroundColor: AppColors.beige,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: AppColors.beigeLight,
        fontFamily: 'EBGaramond',
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: AppColors.beige,
      unselectedLabelColor: AppColors.sageGreenLight,
      indicatorColor: AppColors.sageGreenLight,
      dividerColor: AppColors.sageGreen,
    ),
    dividerTheme: DividerThemeData(color: AppColors.sageGreen, thickness: 1),
    cardTheme: CardThemeData(
      color: AppColors.veryDarkTealLight,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.terracotta,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.beige,
        side: BorderSide(color: AppColors.beige),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.sageGreenLight),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.terracotta,
      foregroundColor: Colors.white,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.veryDarkTeal,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.sageGreen),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.beige, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppColors.sageGreen.withOpacity(0.5)),
      ),
      labelStyle: TextStyle(color: AppColors.sageGreenLight),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: AppColors.terracotta,
      inactiveTrackColor: AppColors.beige.withOpacity(0.3),
      thumbColor: AppColors.terracotta,
      overlayColor: AppColors.terracotta.withOpacity(0.2),
    ),
    iconTheme: IconThemeData(color: AppColors.sageGreenLight),
    textTheme: TextTheme(
      displayLarge: TextStyle(color: AppColors.beige, fontFamily: 'EBGaramond'),
      displayMedium: TextStyle(
        color: AppColors.beigeLight,
        fontFamily: 'EBGaramond',
      ),
      displaySmall: TextStyle(color: AppColors.beige, fontFamily: 'EBGaramond'),
      headlineLarge: TextStyle(
        color: AppColors.beigeLight,
        fontFamily: 'EBGaramond',
      ),
      headlineMedium: TextStyle(
        color: AppColors.beigeLight,
        fontFamily: 'EBGaramond',
      ),
      headlineSmall: TextStyle(
        color: AppColors.beigeLight,
        fontFamily: 'EBGaramond',
      ),
      titleLarge: TextStyle(
        color: AppColors.beigeLight,
        fontWeight: FontWeight.bold,
        fontFamily: 'EBGaramond',
      ),
      titleMedium: TextStyle(
        color: AppColors.beigeLight,
        fontFamily: 'EBGaramond',
      ),
      titleSmall: TextStyle(
        color: AppColors.beigeLight,
        fontFamily: 'EBGaramond',
      ),
      bodyLarge: TextStyle(
        color: AppColors.beigeLight,
        fontFamily: 'EBGaramond',
      ),
      bodyMedium: TextStyle(
        color: AppColors.beigeLight,
        fontFamily: 'EBGaramond',
      ),
      bodySmall: TextStyle(
        color: AppColors.beige.withOpacity(0.8),
        fontFamily: 'EBGaramond',
      ),
      labelLarge: TextStyle(
        color: AppColors.beigeLight,
        fontFamily: 'EBGaramond',
      ),
      labelMedium: TextStyle(
        color: AppColors.beigeLight,
        fontFamily: 'EBGaramond',
      ),
      labelSmall: TextStyle(
        color: AppColors.beigeLight,
        fontFamily: 'EBGaramond',
      ),
    ),
  );
}
