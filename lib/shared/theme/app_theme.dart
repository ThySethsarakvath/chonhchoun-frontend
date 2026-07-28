import 'package:flutter/material.dart';

import '../colors/app_colors.dart';
import 'app_tokens.dart';

abstract final class AppTheme {
  static ThemeData get light {
    const colorScheme = ColorScheme.light(
      primary: AppColors.blue,
      onPrimary: Colors.white,
      primaryContainer: AppColors.softBlue,
      onPrimaryContainer: AppColors.blueDark,
      secondary: AppColors.blueLight,
      onSecondary: Colors.white,
      surface: AppColors.surfaceContainer,
      onSurface: AppColors.text,
      error: AppColors.danger,
      onError: Colors.white,
      outline: AppColors.line,
      outlineVariant: Color(0xFFECF0F4),
      shadow: Color(0x24152F47),
    );

    const textTheme = TextTheme(
      displaySmall: TextStyle(
        fontSize: 32,
        height: 1.15,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
        color: AppColors.text,
      ),
      headlineSmall: TextStyle(
        fontSize: 24,
        height: 1.2,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.35,
        color: AppColors.text,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        height: 1.25,
        fontWeight: FontWeight.w700,
        color: AppColors.text,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        height: 1.3,
        fontWeight: FontWeight.w700,
        color: AppColors.text,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        height: 1.5,
        fontWeight: FontWeight.w400,
        color: AppColors.text,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        height: 1.45,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        height: 1.4,
        fontWeight: FontWeight.w400,
        color: AppColors.muted,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        height: 1.2,
        fontWeight: FontWeight.w700,
        color: AppColors.text,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        height: 1.2,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.surface,
      textTheme: textTheme,
      visualDensity: VisualDensity.standard,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.text,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontSize: 20,
          height: 1.25,
          fontWeight: FontWeight.w700,
          color: AppColors.text,
        ),
      ),
      cardTheme: const CardThemeData(
        color: AppColors.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.lg)),
          side: BorderSide(color: Color(0xFFECF0F4)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceContainer,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 15,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: AppColors.muted),
        labelStyle: textTheme.bodyMedium,
        border: _inputBorder(AppColors.line),
        enabledBorder: _inputBorder(AppColors.line),
        focusedBorder: _inputBorder(AppColors.blue, width: 1.5),
        errorBorder: _inputBorder(AppColors.danger),
        focusedErrorBorder: _inputBorder(AppColors.danger, width: 1.5),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(48, 50),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          elevation: 0,
          backgroundColor: AppColors.blue,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.line,
          disabledForegroundColor: AppColors.muted,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 50),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          foregroundColor: AppColors.blue,
          side: const BorderSide(color: AppColors.line),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 44),
          foregroundColor: AppColors.blue,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.line,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.text,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.xl)),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
      ),
    );
  }

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
