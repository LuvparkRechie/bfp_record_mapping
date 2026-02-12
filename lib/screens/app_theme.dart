import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primaryRed = Color(0xFFD32F2F); // BFP Red
  static const Color darkRed = Color(0xFFB71C1C); // Dark Red
  static const Color lightRed = Color(0xFFEF5350); // Light Red
  static const Color accentRed = Color(0xFFFF5252); // Accent Red

  // Secondary Colors
  static const Color primaryBlue = Color(0xFF1976D2); // BFP Blue
  static const Color darkBlue = Color(0xFF0D47A1); // Dark Blue
  static const Color lightBlue = Color(0xFF42A5F5); // Light Blue

  // Neutral Colors
  static const Color black = Color(0xFF212121);
  static const Color darkGrey = Color(0xFF424242);
  static const Color grey = Color(0xFF757575);
  static const Color lightGrey = Color(0xFFBDBDBD);
  static const Color offWhite = Color(0xFFFAFAFA);
  static const Color white = Color(0xFFFFFFFF);

  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  // Gradient
  static const LinearGradient redGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [darkRed, primaryRed, accentRed],
  );

  static const LinearGradient blueGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [darkBlue, primaryBlue, lightBlue],
  );

  static const LinearGradient fireGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF6B35), Color(0xFFFFA62E), Color(0xFFFFD166)],
  );
}
