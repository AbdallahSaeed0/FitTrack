import 'package:flutter/material.dart';

class AppColors {
  // ==================== BACKGROUNDS ====================

  // Light Mode Backgrounds
  static const Color backgroundLight = Color(0xFFF8FAFC);      // Very light slate
  static const Color cardLight = Color(0xFFFFFFFF);            // Pure white
  static const Color surfaceLight = Color(0xFFF1F5F9);         // Light slate

  // Dark Mode Backgrounds
  static const Color backgroundDark = Color(0xFF1E293B);       // Main dark bg (Slate 800)
  static const Color cardDark = Color(0xFF263445);             // Cards (slightly lighter)
  static const Color surfaceDark = Color(0xFF334155);          // Lighter surface (Slate 700)

  // AppBar & Navigation (Darkest)
  static const Color appBarDark = Color(0xFF0F172A);           // Slate 900 (darkest)
  static const Color bottomNavDark = Color(0xFF1E293B);        // Slate 800

  // ==================== ACCENT COLORS ====================

  // Primary Blue (Bright for contrast on dark bg)
  static const Color primary = Color(0xFF38BDF8);              // Sky 400 (bright blue)
  static const Color primaryLight = Color(0xFF7DD3FC);         // Sky 300 (lighter)
  static const Color primaryDark = Color(0xFF0EA5E9);          // Sky 500 (darker)
  static const Color primaryVeryDark = Color(0xFF0284C7);      // Sky 600 (very dark)

  // Secondary Green (Success, Progress)
  static const Color success = Color(0xFF34D399);              // Emerald 400 (bright green)
  static const Color successDark = Color(0xFF10B981);          // Emerald 500

  // Warning Amber
  static const Color warning = Color(0xFFFBBF24);              // Amber 400
  static const Color warningDark = Color(0xFFF59E0B);          // Amber 500

  // Error Red
  static const Color error = Color(0xFFF87171);                // Red 400
  static const Color errorDark = Color(0xFFEF4444);            // Red 500

  // ==================== TEXT COLORS ====================

  // Light Mode Text
  static const Color textPrimaryLight = Color(0xFF0F172A);     // Slate 900
  static const Color textSecondaryLight = Color(0xFF475569);   // Slate 600
  static const Color textTertiaryLight = Color(0xFF94A3B8);    // Slate 400

  // Dark Mode Text (HIGH CONTRAST for readability)
  static const Color textPrimaryDark = Color(0xFFF1F5F9);      // Almost white
  static const Color textSecondaryDark = Color(0xFFCBD5E1);    // Slate 300
  static const Color textTertiaryDark = Color(0xFF94A3B8);     // Slate 400

  // ==================== UI ELEMENTS ====================

  // Buttons (Light Mode)
  static const Color buttonPrimaryLight = Color(0xFF0EA5E9);   // Sky 500
  static const Color buttonSecondaryLight = Color(0xFF38BDF8); // Sky 400

  // Buttons (Dark Mode - BRIGHT for contrast)
  static const Color buttonPrimaryDark = Color(0xFF38BDF8);    // Sky 400 (bright)
  static const Color buttonSecondaryDark = Color(0xFF0EA5E9);  // Sky 500

  // Active/Selected States
  static const Color activeLight = Color(0xFF0EA5E9);          // Sky 500
  static const Color activeDark = Color(0xFF38BDF8);           // Sky 400 (bright)

  // Inactive/Disabled
  static const Color inactiveLight = Color(0xFF94A3B8);        // Slate 400
  static const Color inactiveDark = Color(0xFF64748B);         // Slate 500

  // Borders & Dividers
  static const Color borderLight = Color(0xFFE2E8F0);          // Slate 200
  static const Color borderDark = Color(0xFF475569);           // Slate 600

  // ==================== SEMANTIC COLORS ====================

  // Progress Bars (Dark Mode)
  static const Color progressBackground = Color(0xFF475569);   // Slate 600
  static const Color progressFill = Color(0xFF38BDF8);         // Sky 400 (bright)

  // Cards with colored backgrounds (Dark Mode)
  static const Color cardGreenDark = Color(0xFF047857);        // Emerald 700
  static const Color cardBlueDark = Color(0xFF0369A1);         // Sky 700
  static const Color cardAmberDark = Color(0xFFB45309);        // Amber 700

  // ==================== COMPAT ALIASES ====================
  // Used throughout the app via app_theme.dart legacy constants

  static const Color primaryNavy = appBarDark;
  static const Color darkNavy = appBarDark;
  static const Color navyDark = appBarDark;
  static const Color primaryBlue = primary;
  static const Color darkBlue = appBarDark;
  static const Color accentTeal = success;
  static const Color growthGreen = success;
  static const Color warningAmber = warning;
  static const Color energyOrange = primary;
  static const Color backgroundSecondary = surfaceLight;
  static const Color backgroundPrimary = cardLight;
  static const Color backgroundTertiary = surfaceDark;
  static const Color lightGray = surfaceLight;
  static const Color mediumGray = Color(0xFF94A3B8);
  static const Color darkGray = Color(0xFF475569);
  static const Color white = Color(0xFFFFFFFF);
  static const Color textPrimary = textPrimaryLight;
  static const Color textSecondary = textSecondaryLight;
  static const Color textMuted = textTertiaryLight;
  static const Color lightSteel = primaryLight;
  static const Color steelBlue = primaryDark;
}
