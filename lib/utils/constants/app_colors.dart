import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF02172E);
  static const Color secondary = Color(0xFF020E1B);
  static const Color accent = Color(0xFF6C5CE7); // Added from auth screens

  // Background Colors
  static const Color background = Color(0xFF02172E);
  static const Color darkBlueBackground = Color(0xFF020E1B);
  static const Color cardBackground = Color(0xFF02172E);
  static const Color accentBlue = Color(0xFF007AFF);
  static const Color containerBackground = Color(0xFF152642);
  static const Color dialogBackground =
      Color(0xFF152642); // Added from auth screens
  static const Color surfaceBackground =
      Color(0xFF1E293B); // Added from auth screens

  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8E9BAE);
  static const Color textMuted = Color(0xFF6B7280);

  // Accent Colors
  static const Color success = Color(0xFF34D399);
  static const Color warning = Color(0xFFFCD34D);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Button Colors
  static const Color buttonPrimary = Color(0xFF3B82F6);
  static const Color buttonSecondary = Color(0xFF1F2937);
  static const Color buttonDisabled =
      Color(0xFF475569); // Added from auth screens

  // Social Media Colors
  static const Color googleRed = Color(0xFFEA4335); // Added from auth screens
  static const Color facebookBlue =
      Color(0xFF1877F2); // Added from auth screens

  // Icon Colors
  static const Color iconPrimary = Color(0xFFFFFFFF);
  static const Color iconSecondary = Color(0xFF8E9BAE);

  // Border Colors
  static const Color borderColor = Color(0xFF1F2937);
  static const Color divider = Color(0xFF1F2937);
  static const Color dividerColor = Color(0xFF1F2937);

  // Additional background colors for different states
  static const Color warningBackground = Color(0x1AFCD34D);
  static const Color errorBackground = Color(0x1AEF4444);
  static const Color successBackground = Color(0x1A34D399);
  static const Color infoBackground = Color(0x1A3B82F6);

  // Gradient Background - Matching the design from images
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF02172E), // Top color
      Color(0xFF020E1B), // Middle color
      Color(0xFF020E1B), // Bottom color
    ],
    stops: [0.0, 0.5, 1.0],
  );

  // Card Gradient - For subtle card backgrounds
  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF152642),
      Color(0xFF1A2C4E),
    ],
  );

  // Progress Bar Gradients
  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFF34D399),
      Color(0xFF059669),
    ],
  );

  static const LinearGradient errorGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFFEF4444),
      Color(0xFFDC2626),
    ],
  );

  // Primary Button Gradient - Added from auth screens
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF3B82F6),
      Color(0xFF2563EB),
    ],
  );

  // Social Button Shadows - Added from auth screens
  static BoxShadow googleButtonShadow = BoxShadow(
    color: Colors.white.withOpacity(0.1),
    blurRadius: 10,
    offset: const Offset(0, 5),
  );

  static BoxShadow facebookButtonShadow = BoxShadow(
    color: facebookBlue.withOpacity(0.3),
    blurRadius: 10,
    offset: const Offset(0, 5),
  );

  // Login Form Shadows - Added from auth screens
  static BoxShadow inputShadow = BoxShadow(
    color: Colors.black.withOpacity(0.1),
    blurRadius: 10,
    offset: const Offset(0, 5),
  );

  // Card Shadows - Added from auth screens
  static BoxShadow cardShadow = BoxShadow(
    color: Colors.black.withOpacity(0.2),
    blurRadius: 15,
    offset: const Offset(0, 5),
  );
}
