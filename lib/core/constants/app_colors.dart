import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const pakistanGreen = Color(0xFF0A7D32);
  static const deepGreen = Color(0xFF0D5D26);
  static const emerald = Color(0xFF1C9A46);
  static const lightBackground = Color(0xFFF4F8F4);
  static const darkBackground = Color(0xFF0B1210);
  static const gold = Color(0xFFEBCB6A);
  static const ivory = Color(0xFFFFFFFF);
  static const ink = Color(0xFF122018);
  static const muted = Color(0xFF6D7D72);
  static const white = Colors.white;

  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [pakistanGreen, deepGreen, emerald],
  );

  static const goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFF2B7), gold, Color(0xFFC89B2B)],
  );
}
