import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../services/supabase_service.dart';
import '../models/user.dart';

class AuthProvider extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isInitialized = false;
  bool _passwordWasSet = false; // Flag para indicar se uma senha foi definida

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _currentUser != null;
  bool get isInitialized => _isInitialized;
  bool get passwordWasSet => _passwordWasSet;

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
          _currentUser = User.fromJson(userExists);
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
        await prefs.setString('current_user', json.encode(_currentUser!.toJson()));
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

  // Login com nome de usuário e senha
  Future<bool> signInWithUsername(String username, {String? password}) async {
    try {
      _setLoading(true);
      _clearError();
      
      if (username.trim().isEmpty) {
        throw Exception('Por favor, insira um nome de usuário');
      }

      if (password == null || password.isEmpty) {
        throw Exception('Por favor, insira uma senha');
      }

      if (password.length < 4) {
        throw Exception('A senha deve ter pelo menos 4 dígitos');
      }

      // Primeiro, verificar se o usuário existe
      final existingUser = await SupabaseService.client
          .from('Users')
          .select('*')
          .eq('Username', username.trim())
          .maybeSingle();

      if (existingUser == null) {
        throw Exception('Usuário não encontrado');
      }

      print('Usuário encontrado: ${existingUser['Username']}');
      print('Password hash atual: ${existingUser['password_hash']}');
      print('Password hash é null: ${existingUser['password_hash'] == null}');
      print('Password hash é string vazia: ${existingUser['password_hash'] == ""}');

      // Se o usuário existe mas não tem senha (password_hash é NULL ou vazio), definir nova senha
      if (existingUser['password_hash'] == null || existingUser['password_hash'] == '' || existingUser['password_hash'].toString().trim().isEmpty) {
        final passwordHash = _hashPassword(password);
        
        print('Usuário sem senha detectado. Definindo nova senha...');
        
        // Atualizar o usuário com a nova senha
        final updatedUser = await SupabaseService.client
            .from('Users')
            .update({
              'password_hash': passwordHash,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', existingUser['id'])
            .select()
            .single();

        _currentUser = User.fromJson(updatedUser);
        _passwordWasSet = true; // Marcar que uma senha foi definida
        await _saveSession();
        notifyListeners();
        
        print('Nova senha definida com sucesso para o usuário: ${username.trim()}');
        return true;
      }

      // Se o usuário já tem senha, verificar se a senha fornecida está correta
      print('Verificando senha existente...');
      final passwordHash = _hashPassword(password);
      print('Hash da senha fornecida: $passwordHash');
      print('Hash armazenado no banco: ${existingUser['password_hash']}');
      
      if (existingUser['password_hash'] == passwordHash) {
        print('Senha correta! Fazendo login...');
        _currentUser = User.fromJson(existingUser);
        _passwordWasSet = false; // Reset da flag para login normal
        await _saveSession();
        notifyListeners();
        return true;
      } else {
        print('Senha incorreta!');
        throw Exception('Senha incorreta');
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

  // Registrar novo usuário com nome de usuário e senha
  Future<bool> signUpWithUsername(String username, {String? password}) async {
    try {
      _setLoading(true);
      _clearError();
      
      if (username.trim().isEmpty) {
        throw Exception('Por favor, insira um nome de usuário');
      }

      if (password == null || password.isEmpty) {
        throw Exception('Por favor, insira uma senha');
      }

      if (password.length < 4) {
        throw Exception('A senha deve ter pelo menos 4 dígitos');
      }

      print('Iniciando cadastro do usuário: ${username.trim()}');

      // Verificar se o usuário já existe
      final existingUser = await SupabaseService.client
          .from('Users')
          .select('Username')
          .eq('Username', username.trim())
          .maybeSingle();

      if (existingUser != null) {
        throw Exception('Este nome de usuário já existe');
      }

      // Hash da senha
      final passwordHash = _hashPassword(password);

      // Criar novo usuário
      print('Criando usuário no banco de dados...');
      final newUser = {
        'Username': username.trim(),
        'password_hash': passwordHash,
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await SupabaseService.client
          .from('Users')
          .insert(newUser)
          .select()
          .single();

      _currentUser = User.fromJson(response);
      _passwordWasSet = false; // Reset da flag para novos registros
      print('Usuário criado com ID: ${_currentUser!.id}');

      await _saveSession(); // Salvar sessão
      notifyListeners();
      print('Cadastro concluído com sucesso!');
      return true;
    } on PostgrestException catch (error) {
      print('Erro PostgreSQL: ${error.message} (código: ${error.code})');
      if (error.code == '42501') {
        _setError('Erro de permissão: Configure as políticas RLS no Supabase');
      } else if (error.code == '42601') {
        _setError('Erro de acesso ao banco: Verifique as configurações do Supabase');
      } else {
        _setError('Erro no banco de dados: ${error.message}');
      }
      return false;
    } catch (error) {
      print('Erro geral: $error');
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

  void clearPasswordWasSetFlag() {
    _passwordWasSet = false;
  }

  // Alterar senha do usuário atual
  Future<bool> changePassword(String currentPassword, String newPassword) async {
    try {
      _setLoading(true);
      _clearError();

      if (_currentUser == null) {
        throw Exception('Usuário não está logado');
      }

      // Validar nova senha
      if (newPassword.length < 4) {
        throw Exception('A nova senha deve ter pelo menos 4 dígitos');
      }

      // Buscar dados atuais do usuário
      final userData = await SupabaseService.client
          .from('Users')
          .select('password_hash')
          .eq('id', _currentUser!.id)
          .single();

      // Verificar senha atual
      final currentPasswordHash = _hashPassword(currentPassword);
      if (userData['password_hash'] != currentPasswordHash) {
        throw Exception('Senha atual incorreta');
      }

      // Gerar hash da nova senha
      final newPasswordHash = _hashPassword(newPassword);

      // Atualizar senha no banco
      await SupabaseService.client
          .from('Users')
          .update({
            'password_hash': newPasswordHash,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', _currentUser!.id);

      return true;
    } catch (error) {
      print('Erro ao alterar senha: $error');
      _setError(error.toString().replaceFirst('Exception: ', ''));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Método auxiliar para hash de senha simples
  String _hashPassword(String password) {
    var bytes = utf8.encode(password); // data being hashed
    var digest = sha256.convert(bytes);
    return digest.toString();
  }
}