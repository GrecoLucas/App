import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConfig {
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  
  // Se você tiver problemas com RLS, pode usar a service key (cuidado com segurança!)
  // static String get supabaseServiceKey => dotenv.env['SUPABASE_SERVICE_KEY'] ?? '';
}
