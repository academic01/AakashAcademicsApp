import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/text_styles.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: 'Nunito',

      // Color Scheme
      colorScheme: ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        tertiary: AppColors.cuet,
        surface: AppColors.background,
        surfaceContainerHighest: AppColors.card,
        error: AppColors.error,
        onPrimary: AppColors.background,
        onSecondary: AppColors.primary,
        onSurface: AppColors.textDark,
        onError: AppColors.background,
      ),

      // Scaffold Background
      scaffoldBackgroundColor: AppColors.background,

      // AppBar Theme
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: AppColors.primary,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        titleTextStyle: AppTextStyles.headlineMedium.copyWith(
          color: AppColors.background,
        ),
        iconTheme: const IconThemeData(color: AppColors.background),
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.background,
        elevation: 4,
        extendedTextStyle: AppTextStyles.labelLarge.copyWith(
          color: AppColors.background,
        ),
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.background,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: AppTextStyles.buttonText,
          elevation: 2,
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.background,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: AppTextStyles.buttonText,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.primary, width: 2),
          ),
          textStyle: AppTextStyles.buttonText,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: AppTextStyles.labelLarge,
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.card,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        labelStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textMuted,
        ),
        hintStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textMuted,
        ),
        errorStyle: AppTextStyles.labelSmall.copyWith(color: AppColors.error),
        prefixIconColor: AppColors.textMuted,
        suffixIconColor: AppColors.textMuted,
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: AppColors.background,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border),
        ),
        surfaceTintColor: Colors.transparent,
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 16,
      ),

      // Bottom Sheet Theme
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.background,
        elevation: 8,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        modalElevation: 8,
        surfaceTintColor: Colors.transparent,
      ),

      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.background,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: AppTextStyles.headlineMedium.copyWith(
          color: AppColors.textDark,
        ),
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textDark,
        ),
      ),

      // Checkbox Theme
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return AppColors.card;
        }),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        side: const BorderSide(color: AppColors.border),
      ),

      // Radio Theme
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return AppColors.border;
        }),
      ),

      // Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return AppColors.textMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary.withOpacity(0.3);
          }
          return AppColors.border;
        }),
      ),

      // Slider Theme
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.primary,
        inactiveTrackColor: AppColors.border,
        thumbColor: AppColors.primary,
        overlayColor: AppColors.primary.withOpacity(0.2),
      ),

      // Progress Indicator Theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        circularTrackColor: AppColors.border,
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.card,
        labelStyle: AppTextStyles.labelMedium.copyWith(
          color: AppColors.textDark,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppColors.border),
        ),
        selectedColor: AppColors.primary,
        disabledColor: AppColors.card.withOpacity(0.5),
        deleteIconColor: AppColors.textMuted,
        elevation: 0,
      ),

      // Navigation Bar Theme
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.background,
        elevation: 8,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTextStyles.labelMedium.copyWith(color: AppColors.primary);
          }
          return AppTextStyles.labelMedium.copyWith(color: AppColors.textMuted);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primary);
          }
          return const IconThemeData(color: AppColors.textMuted);
        }),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.background,
        elevation: 8,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        selectedLabelStyle: AppTextStyles.labelSmall,
        unselectedLabelStyle: AppTextStyles.labelSmall,
        type: BottomNavigationBarType.fixed,
      ),

      // Tab Bar Theme
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textMuted,
        labelStyle: AppTextStyles.tabText.copyWith(fontWeight: FontWeight.w700),
        unselectedLabelStyle: AppTextStyles.tabText,
        dividerColor: AppColors.border,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(color: AppColors.primary, width: 3),
        ),
      ),

      // List Tile Theme
      listTileTheme: ListTileThemeData(
        textColor: AppColors.textDark,
        iconColor: AppColors.primary,
        tileColor: AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),

      // Snack Bar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textDark,
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.background,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 6,
        behavior: SnackBarBehavior.floating,
      ),

      // Text Theme
      textTheme: TextTheme(
        displayLarge: AppTextStyles.displayLarge.copyWith(
          color: AppColors.textDark,
        ),
        displayMedium: AppTextStyles.displayMedium.copyWith(
          color: AppColors.textDark,
        ),
        displaySmall: AppTextStyles.displaySmall.copyWith(
          color: AppColors.textDark,
        ),
        headlineLarge: AppTextStyles.headlineLarge.copyWith(
          color: AppColors.textDark,
        ),
        headlineMedium: AppTextStyles.headlineMedium.copyWith(
          color: AppColors.textDark,
        ),
        headlineSmall: AppTextStyles.headlineSmall.copyWith(
          color: AppColors.textDark,
        ),
        titleLarge: AppTextStyles.titleLarge.copyWith(
          color: AppColors.textDark,
        ),
        titleMedium: AppTextStyles.titleMedium.copyWith(
          color: AppColors.textDark,
        ),
        titleSmall: AppTextStyles.titleSmall.copyWith(
          color: AppColors.textDark,
        ),
        bodyLarge: AppTextStyles.bodyLarge.copyWith(color: AppColors.textDark),
        bodyMedium: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textDark,
        ),
        bodySmall: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
        labelLarge: AppTextStyles.labelLarge.copyWith(
          color: AppColors.textDark,
        ),
        labelMedium: AppTextStyles.labelMedium.copyWith(
          color: AppColors.textDark,
        ),
        labelSmall: AppTextStyles.labelSmall.copyWith(
          color: AppColors.textMuted,
        ),
      ),

      // Platform Specific
      platform: TargetPlatform.android,
    );
  }

  // Optional: Dark theme can be added here in future
  static ThemeData get darkTheme {
    return lightTheme;
  }
}
