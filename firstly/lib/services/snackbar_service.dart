import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

/// Serviço centralizado para exibição de SnackBars
/// 
/// Garante design consistente (flutuante) e remove SnackBar atual 
/// antes de mostrar uma nova (evita enfileiramento).
class SnackBarService {
  /// Exibe uma SnackBar com design flutuante padronizado
  /// 
  /// [context] - BuildContext do widget
  /// [message] - Mensagem a ser exibida
  /// [backgroundColor] - Cor de fundo (padrão: primaryGreen)
  /// [duration] - Duração em segundos (padrão: 2)
  static void show(
    BuildContext context, {
    required String message,
    Color? backgroundColor,
    int durationSeconds = 2,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    
    // Remove a SnackBar atual instantaneamente (evita enfileiramento)
    messenger.removeCurrentSnackBar();
    
    // Exibe a nova SnackBar com design flutuante
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor ?? AppTheme.primaryGreen,
        duration: Duration(seconds: durationSeconds),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Exibe uma SnackBar de sucesso (verde)
  static void success(BuildContext context, String message) {
    show(context, message: message, backgroundColor: AppTheme.primaryGreen);
  }

  /// Exibe uma SnackBar de aviso (laranja)
  static void warning(BuildContext context, String message) {
    show(context, message: message, backgroundColor: Colors.orange);
  }

  /// Exibe uma SnackBar de erro (vermelho)
  static void error(BuildContext context, String message) {
    show(context, message: message, backgroundColor: AppTheme.warningRed);
  }

  /// Exibe uma SnackBar informativa (azul)
  static void info(BuildContext context, String message) {
    show(context, message: message, backgroundColor: AppTheme.accentBlue);
  }
}
