import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/supabase_service.dart';

class AuthProvider extends ChangeNotifier {
  Map<String, dynamic>? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isInitialized = false;

  Map<String, dynamic>? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _currentUser != null;
  bool get isInitialized => _isInitialized;

  // Inicializar o provider e verificar sessão salva
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _setLoading(true);
      await _loadSavedSession();
      _isInitialized = true;
    } catch (e) {
      print('Erro ao inicializar sessão: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Carregar sessão salva do SharedPreferences
  Future<void> _loadSavedSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('current_user');
      
      if (userDataString != null && userDataString.isNotEmpty) {
        final userData = json.decode(userDataString);
        
        // Verificar se o usuário ainda existe no banco
        final userExists = await SupabaseService.client
            .from('Users')
            .select('*')
            .eq('id', userData['id'])
            .maybeSingle();
        
        if (userExists != null) {
          _currentUser = userExists;
          notifyListeners();
        } else {
          // Usuário não existe mais, limpar dados salvos
          await _clearSavedSession();
        }
      }
    } catch (e) {
      print('Erro ao carregar sessão salva: $e');
      await _clearSavedSession();
    }
  }

  // Salvar sessão no SharedPreferences
  Future<void> _saveSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_currentUser != null) {
        await prefs.setString('current_user', json.encode(_currentUser));
      }
    } catch (e) {
      print('Erro ao salvar sessão: $e');
    }
  }

  // Limpar sessão salva
  Future<void> _clearSavedSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('current_user');
    } catch (e) {
      print('Erro ao limpar sessão: $e');
    }
  }

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
        await _saveSession(); // Salvar sessão
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
      await _saveSession(); // Salvar sessão
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
    await _clearSavedSession(); // Limpar sessão salva
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