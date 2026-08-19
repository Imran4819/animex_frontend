import 'package:flutter/material.dart';

class AppColors {
  static const navy = Color(0xFF0D2A4D);
  static const navyDark = Color(0xFF071423);
  static const navySoft = Color(0xFF17395F);
  static const orange = Color(0xFFFF7A00);
  static const orangeSoft = Color(0xFFFFC28A);
  static const white = Color(0xFFFFFFFF);
  static const background = Color(0xFFF5F7FA);
  static const surface = Color(0xFFFFFFFF);
  static const text = Color(0xFF132238);
  static const textMuted = Color(0xFF6B7A90);
  static const border = Color(0xFFE2E8F0);
  static const green = Color(0xFF16A34A);
  static const greenSoft = Color(0xFFDFF7E8);
  static const amber = Color(0xFFF59E0B);
  static const amberSoft = Color(0xFFFFF1CF);
  static const red = Color(0xFFDC2626);
  static const redSoft = Color(0xFFFFE0E0);
  static const blueSoft = Color(0xFFE7F0FF);
  static const tealSoft = Color(0xFFE0FAF4);
  static const purpleSoft = Color(0xFFF0E9FF);
  static const shadow = Color(0x140D2A4D);
}

class AppGradients {
  static const brand = LinearGradient(
    colors: [AppColors.navy, AppColors.navySoft],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const accent = LinearGradient(
    colors: [AppColors.orange, Color(0xFFFF9F3E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const background = LinearGradient(
    colors: [Color(0xFFF8FAFC), AppColors.background],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
