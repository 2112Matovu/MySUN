import 'package:flutter/material.dart';

/// Brand palette for MySun. "Sun" — warm amber primary over a calm slate ground.
abstract final class AppColors {
  static const Color brandSun = Color(0xFFF39A0E);
  static const Color brandSunDeep = Color(0xFFCC7A00);
  static const Color brandDusk = Color(0xFF2E3A59);
  static const Color brandSky = Color(0xFF2F80ED);

  // Category accents (used for chips, icons, event/announcement tags).
  static const Color academic = Color(0xFF2F80ED);
  static const Color social = Color(0xFFEB5757);
  static const Color sports = Color(0xFF27AE60);
  static const Color administration = Color(0xFF9B51E0);
  static const Color clubs = Color(0xFFF2994A);
  static const Color workshops = Color(0xFF00A3A3);
  static const Color transport = Color(0xFF56618B);

  static const Color success = Color(0xFF1E9E5A);
  static const Color warning = Color(0xFFE2A400);
  static const Color danger = Color(0xFFD64545);
}
