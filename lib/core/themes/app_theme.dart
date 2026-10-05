import 'package:flutter/material.dart';

abstract class AppColors {
  static const primary = Color(0xFF14213D);

  /// Accent de marque. Ne pas l'utiliser comme couleur de texte sur fond
  /// clair : #FCA311 ne donne que 2:1 sur blanc. Utiliser [secondaryText].
  static const secondary = Color(0xFFFCA311);

  /// Variante de [secondary] lisible en texte ou icône sur fond clair
  /// (6,3:1 sur blanc).
  static const secondaryText = Color(0xFF8A5300);

  static const background = Color(0xFFF5F5F0);
  static const surface = Colors.white;

  /// Gris « secondaire ». L'ancien #9AA0A6 ne donnait que 2,4:1 sur le fond :
  /// tous les libellés secondaires échouaient WCAG AA. #5F6368 le tient.
  static const inactive = Color(0xFF5F6368);

  /// Rouge d'urgence. Le noir cassait toute la lecture « rouge = danger » de
  /// l'application (bouton SOS, pastilles, numéros d'urgence, erreurs).
  static const sos = Color(0xFFC62828);
}

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    primary: AppColors.primary,
    secondary: AppColors.secondary,
    surface: AppColors.surface,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      centerTitle: true,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
