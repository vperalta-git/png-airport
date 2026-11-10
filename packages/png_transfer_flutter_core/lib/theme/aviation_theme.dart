import 'package:flutter/material.dart';

class AviationColors {
  // Primary Aviation Palettes
  static const Color navy900 = Color(0xFF07101E);
  static const Color navy800 = Color(0xFF0B192C);
  static const Color navy700 = Color(0xFF152943);
  static const Color navy600 = Color(0xFF1E3A5F);

  // Tactical Gold & Accents
  static const Color gold500 = Color(0xFFB89726); // High-contrast tactical gold
  static const Color gold400 = Color(0xFF9E7E1C);
  static const Color gold600 = Color(0xFF8A6C12);

  // Surfaces & Borders (Executive Crisp Light Mode)
  static const Color surfaceDark =
      Color(0xFFF1F5F9); // Slate-100 secondary container fill
  static const Color cardDark = Color(0xFFFFFFFF); // Pure white card surface
  static const Color cardBorder =
      Color(0xFFE2E8F0); // Slate-200 subtle crisp border
  static const Color inputBackground = Color(0xFFF8FAFC); // Slate-50 input fill

  // Operational Statuses (Tailored for high contrast on light canvas)
  static const Color statusConfirmed = Color(0xFF1D4ED8); // Blue 700
  static const Color statusDispatched = Color(0xFF0369A1); // Sky 700
  static const Color statusEnRoute = Color(0xFFB45309); // Amber 700
  static const Color statusAtAirport = Color(0xFF6D28D9); // Purple 700
  static const Color statusVerified = Color(0xFF047857); // Emerald 700
  static const Color statusInTransit = Color(0xFF1D4ED8); // Blue 700
  static const Color statusCompleted = Color(0xFF059669); // Green 600
  static const Color statusIncident = Color(0xFFDC2626); // Red 600
  static const Color statusCancelled = Color(0xFF4B5563); // Gray 600

  // Text (High-contrast Slate typography for Light Mode)
  static const Color textPrimary =
      Color(0xFF0F172A); // Slate-900 (High contrast headlines & body)
  static const Color textSecondary =
      Color(0xFF475569); // Slate-600 (Subtitles & captions)
  static const Color textMuted =
      Color(0xFF64748B); // Slate-500 (Hints & subtle meta)
  static const Color textAccent = Color(0xFF9E7E1C); // Deep gold accent
  static const Color textDanger = Color(0xFFDC2626);
  static const Color textSuccess = Color(0xFF059669);

  // Semantic Aliases
  static const Color darkBackground =
      Color(0xFFF8FAFC); // Slate-50 Scaffold canvas
  static const Color primaryNavy = Color(0xFF0B192C); // Deep aviation navy
  static const Color goldTrim = Color(0xFFB89726);
  static const Color cardBackground = Color(0xFFFFFFFF); // Pure white
  static const Color surfaceBorder = cardBorder;
  static const Color alertRed = statusIncident;
  static const Color statusGreen = statusCompleted;
  static const Color statusBlue = statusConfirmed;
  static const Color statusOrange = statusEnRoute;

  static Color getStatusColor(String state) {
    switch (state.toLowerCase()) {
      case 'booking_requested':
        return statusEnRoute;
      case 'availability_confirmed':
      case 'confirmed':
        return statusConfirmed;
      case 'dispatched':
      case 'ready_for_dispatch':
        return statusDispatched;
      case 'driver_en_route':
        return statusEnRoute;
      case 'at_airport':
        return statusAtAirport;
      case 'passenger_located':
      case 'passenger_verified':
        return statusVerified;
      case 'passenger_onboard':
      case 'transfer_in_progress':
      case 'in_progress':
        return statusInTransit;
      case 'arrived_destination':
      case 'completed':
      case 'closed':
        return statusCompleted;
      case 'incident':
      case 'aborted':
        return statusIncident;
      case 'cancelled':
      default:
        return statusCancelled;
    }
  }
}

class AviationTheme {
  static const bundledFont =
      'packages/png_transfer_flutter_core/OfflineAeroRoboto';

  /// Default theme data alias
  static ThemeData get themeData => lightTheme;

  /// Executive Light Mode theme for all 4 PNG Airport apps
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: bundledFont,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AviationColors.darkBackground,
      primaryColor: AviationColors.primaryNavy,
      colorScheme: const ColorScheme.light(
        primary: AviationColors.primaryNavy,
        secondary: AviationColors.goldTrim,
        surface: AviationColors.cardBackground,
        error: AviationColors.statusIncident,
        onPrimary: Colors.white,
        onSecondary: AviationColors.primaryNavy,
        onSurface: AviationColors.textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: AviationColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AviationColors.textPrimary),
        titleTextStyle: TextStyle(
          fontFamily: bundledFont,
          color: AviationColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: AviationColors.cardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AviationColors.cardBorder, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AviationColors.inputBackground,
        labelStyle:
            const TextStyle(color: AviationColors.textSecondary, fontSize: 14),
        hintStyle:
            const TextStyle(color: AviationColors.textMuted, fontSize: 14),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AviationColors.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AviationColors.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: AviationColors.primaryNavy, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AviationColors.primaryNavy,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
              minimumSize: const Size(48, 52),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              textStyle: const TextStyle(
                  fontFamily: bundledFont,
                  fontSize: 15,
                  fontWeight: FontWeight.w600))),
      outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
              minimumSize: const Size(48, 50),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              side: const BorderSide(color: AviationColors.cardBorder),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)))),
      chipTheme: ChipThemeData(
          backgroundColor: Colors.white,
          selectedColor: AviationColors.primaryNavy,
          checkmarkColor: Colors.white,
          side: const BorderSide(color: AviationColors.cardBorder),
          labelStyle: WidgetStateTextStyle.resolveWith((states) => TextStyle(
              fontFamily: bundledFont,
              fontSize: 13,
              color: states.contains(WidgetState.selected)
                  ? Colors.white
                  : AviationColors.textPrimary)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
      navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: Color(0xFFEDE7CE),
          elevation: 0,
          labelTextStyle: WidgetStatePropertyAll(TextStyle(
              fontFamily: bundledFont,
              fontSize: 12,
              fontWeight: FontWeight.w600))),
      snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AviationColors.primaryNavy),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AviationColors.primaryNavy,
        unselectedItemColor: AviationColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      dividerTheme: const DividerThemeData(
        color: AviationColors.cardBorder,
        thickness: 1,
      ),
    );
  }

  /// Tactical Dark Mode theme
  static ThemeData get darkTheme {
    return ThemeData(
      fontFamily: bundledFont,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0B1320),
      primaryColor: const Color(0xFFD4AF37),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFD4AF37),
        secondary: Color(0xFFE5C158),
        surface: Color(0xFF131F33),
        error: Color(0xFFDC2626),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF07101E),
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF131F33),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF1E2F4D), width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF0F1A2B),
        labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
        hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF1E2F4D)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF1E2F4D)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFD4AF37), width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFD4AF37),
          foregroundColor: const Color(0xFF07101E),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF07101E),
        selectedItemColor: Color(0xFFD4AF37),
        unselectedItemColor: Color(0xFF64748B),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }
}
