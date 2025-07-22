import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

class AuthProvider extends ChangeNotifier {
  Map<String, dynamic>? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  Map<String, dynamic>? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _currentUser != null;

  // Login apenas com nome de usuário
  Future<bool> signInWithUsername(String username) async {
    try {
      _setLoading(true);
      _clearError();
      
      if (username.trim().isEmpty) {
        throw Exception('Por favor, insira um nome de usuário');
      }

      // Buscar usuário na tabela Users pelo nome de usuário
      final response = await SupabaseService.client
          .from('Users')
          .select('*')
          .eq('Username', username.trim())
          .maybeSingle();

      if (response != null) {
        _currentUser = response;
        notifyListeners();
        return true;
      } else {
        throw Exception('Usuário não encontrado');
      }
    } on PostgrestException catch (error) {
      if (error.code == '42501') {
        _setError('Erro de permissão: Configure as políticas RLS no Supabase');
      } else if (error.code == '42601') {
        _setError('Erro de acesso ao banco: Verifique as configurações do Supabase');
      } else {
        _setError('Erro no banco de dados: ${error.message}');
      }
      return false;
    } catch (error) {
      _setError('Erro: ${error.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Registrar novo usuário apenas com nome de usuário
  Future<bool> signUpWithUsername(String username) async {
    try {
      _setLoading(true);
      _clearError();
      
      if (username.trim().isEmpty) {
        throw Exception('Por favor, insira um nome de usuário');
      }

      // Verificar se o usuário já existe
      final existingUser = await SupabaseService.client
          .from('Users')
          .select('Username')
          .eq('Username', username.trim())
          .maybeSingle();

      if (existingUser != null) {
        throw Exception('Este nome de usuário já existe');
      }

      // Criar novo usuário
      final newUser = {
        'Username': username.trim(),
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await SupabaseService.client
          .from('Users')
          .insert(newUser)
          .select()
          .single();

      _currentUser = response;
      notifyListeners();
      return true;
    } on PostgrestException catch (error) {
      if (error.code == '42501') {
        _setError('Erro de permissão: Configure as políticas RLS no Supabase');
      } else if (error.code == '42601') {
        _setError('Erro de acesso ao banco: Verifique as configurações do Supabase');
      } else {
        _setError('Erro no banco de dados: ${error.message}');
      }
      return false;
    } catch (error) {
      _setError('Erro: ${error.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Logout
  Future<void> signOut() async {
    _currentUser = null;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _clearError();
  }
}