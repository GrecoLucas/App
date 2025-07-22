import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/login_screen.dart';
import '../screens/home_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Se está carregando ou não foi inicializado, mostra tela de carregamento
        if (authProvider.isLoading || !authProvider.isInitialized) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        // Se está logado, mostra a tela principal
        if (authProvider.isLoggedIn) {
          return const HomeScreen();
        }
        
        // Se não está logado, mostra tela de login
        return const LoginScreen();
      },
    );
  }
}
