import 'package:flutter/material.dart';

class AppTheme {
  // Cores principais
  static const Color primaryGreen = Color(0xFF4CAF50);
  static const Color lightGreen = Color(0xFFE8F5E8);
  static const Color darkGreen = Color(0xFF2E7D32);
  static const Color accentBlue = Color(0xFF2196F3);
  static const Color warningRed = Color(0xFFE53935);
  static const Color softGrey = Color(0xFFF5F5F5);
  static const Color textGrey = Color(0xFF757575);
  
  // Gradientes
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color.fromARGB(255, 48, 140, 206), Color.fromARGB(255, 102, 183, 187)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Colors.white, Color(0xFFFAFAFA)],
  );

  // Tema principal
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGreen,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        titleTextStyle: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        shadowColor: Colors.black12,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        elevation: 6,
        backgroundColor: Color.fromARGB(255, 76, 102, 175),
        foregroundColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: softGrey,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}

class AppConstants {
  // Espaçamentos responsivos
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 20.0; // Reduzido para mobile
  static const double paddingXLarge = 28.0; // Reduzido para mobile

  // Border radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 24.0;

  // Tamanhos de ícones responsivos
  static const double iconSmall = 18.0; // Reduzido
  static const double iconMedium = 22.0; // Reduzido
  static const double iconLarge = 28.0; // Reduzido
  static const double iconXLarge = 42.0; // Reduzido

  // Tamanhos de fonte responsivos
  static const double fontSmall = 12.0;
  static const double fontMedium = 14.0; // Reduzido
  static const double fontLarge = 16.0; // Reduzido
  static const double fontXLarge = 20.0; // Reduzido
  static const double fontXXLarge = 26.0; // Reduzido

  // Animações
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationMedium = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);

  // Métodos responsivos para ajuste baseado no tamanho da tela
  static double getResponsivePadding(BuildContext context, double basePadding) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 360) return basePadding * 0.8; // Telas muito pequenas
    if (screenWidth < 400) return basePadding * 0.9; // Telas pequenas
    return basePadding; // Telas normais e maiores
  }

  static double getResponsiveFontSize(BuildContext context, double baseFontSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 360) return baseFontSize * 0.9; // Telas muito pequenas
    return baseFontSize; // Telas normais e maiores
  }
}

class AppStyles {
  // Estilos de texto
  static const TextStyle headingLarge = TextStyle(
    fontSize: AppConstants.fontXXLarge,
    fontWeight: FontWeight.bold,
    color: Colors.black87,
  );

  static const TextStyle headingMedium = TextStyle(
    fontSize: AppConstants.fontXLarge,
    fontWeight: FontWeight.w600,
    color: Colors.black87,
  );

  static const TextStyle headingSmall = TextStyle(
    fontSize: AppConstants.fontLarge,
    fontWeight: FontWeight.w600,
    color: Colors.black87,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: AppConstants.fontLarge,
    fontWeight: FontWeight.w500,
    color: Colors.black87,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: AppConstants.fontMedium,
    color: Colors.black87,
  );

  static const TextStyle captionGrey = TextStyle(
    fontSize: AppConstants.fontSmall,
    color: AppTheme.textGrey,
  );

  static const TextStyle priceStyle = TextStyle(
    fontSize: AppConstants.fontLarge,
    fontWeight: FontWeight.bold,
    color: AppTheme.primaryGreen,
  );

  // Sombras
  static const BoxShadow softShadow = BoxShadow(
    color: Colors.black12,
    blurRadius: 8,
    offset: Offset(0, 2),
  );

  static const BoxShadow mediumShadow = BoxShadow(
    color: Colors.black26,
    blurRadius: 12,
    offset: Offset(0, 4),
  );
}
