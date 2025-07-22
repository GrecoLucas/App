import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class SupabaseService {
  static SupabaseClient? _client;
  
  static SupabaseClient get client {
    if (_client == null) {
      throw Exception('Supabase não foi inicializado. Chame SupabaseService.initialize() primeiro.');
    }
    return _client!;
  }
  
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
    );
    _client = Supabase.instance.client;
  }
  
  // Métodos de autenticação
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    return await client.auth.signUp(
      email: email,
      password: password,
    );
  }
  
  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }
  
  static Future<void> signOut() async {
    await client.auth.signOut();
  }
  
  static User? get currentUser => client.auth.currentUser;
  
  static bool get isLoggedIn => currentUser != null;
  
  // Métodos para operações de dados
  static PostgrestQueryBuilder from(String table) {
    return client.from(table);
  }
  
  // Exemplo de método para inserir dados
  static Future<void> insertData(String table, Map<String, dynamic> data) async {
    await client.from(table).insert(data);
  }
  
  // Exemplo de método para buscar dados
  static Future<List<Map<String, dynamic>>> fetchData(String table) async {
    final response = await client.from(table).select();
    return List<Map<String, dynamic>>.from(response);
  }
  
  // Exemplo de método para atualizar dados
  static Future<void> updateData(String table, Map<String, dynamic> data, String idColumn, dynamic id) async {
    await client.from(table).update(data).eq(idColumn, id);
  }
  
  // Exemplo de método para deletar dados
  static Future<void> deleteData(String table, String idColumn, dynamic id) async {
    await client.from(table).delete().eq(idColumn, id);
  }
}
