import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'widgets/auth_wrapper.dart';
import 'utils/app_theme.dart';
import 'providers/app_settings_provider.dart';
import 'providers/auth_provider.dart';
import 'services/supabase_service.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Supabase
  await SupabaseService.initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AppSettingsProvider()..initialize()),
        ChangeNotifierProvider(create: (context) => AuthProvider()..initialize()),
      ],
      child: MaterialApp(
        title: 'SmartShop - Lista de Compras Inteligente',
        theme: AppTheme.lightTheme,
        home: const AuthWrapper(),
        debugShowCheckedModeBanner: false,
        routes: {
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/home': (context) => const HomeScreen(),
          '/profile': (context) => const ProfileScreen(),
        },
      ),
    );
  }
}
