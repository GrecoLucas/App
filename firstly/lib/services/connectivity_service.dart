import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class ConnectivityService {
  static final Connectivity _connectivity = Connectivity();
  static StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  static bool _isOnline = true;
  static final List<VoidCallback> _listeners = [];

  /// Status atual da conectividade
  static bool get isOnline => _isOnline;

  /// Inicializa o serviço de conectividade
  static Future<void> initialize() async {
    // Verifica o status inicial da conectividade
    final result = await _connectivity.checkConnectivity();
    _isOnline = _isConnected(result);
    
    // Escuta mudanças na conectividade
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((result) {
      final wasOnline = _isOnline;
      _isOnline = _isConnected(result);
      
      // Se houve mudança no status, notifica os listeners
      if (wasOnline != _isOnline) {
        _notifyListeners();
      }
    });
  }

  /// Adiciona um listener para mudanças de conectividade
  static void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  /// Remove um listener
  static void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  /// Notifica todos os listeners
  static void _notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }

  /// Verifica se há conexão com a internet
  static bool _isConnected(List<ConnectivityResult> result) {
    return result.any((connectivity) => 
      connectivity == ConnectivityResult.wifi || 
      connectivity == ConnectivityResult.mobile || 
      connectivity == ConnectivityResult.ethernet
    );
  }

  /// Dispõe os recursos
  static void dispose() {
    _connectivitySubscription?.cancel();
    _listeners.clear();
  }

  /// Retorna um ícone baseado no status da conectividade
  static IconData getConnectivityIcon() {
    return _isOnline ? Icons.wifi : Icons.wifi_off;
  }

  /// Retorna uma cor baseada no status da conectividade
  static Color getConnectivityColor() {
    return _isOnline ? Colors.green : Colors.red;
  }

  /// Retorna o texto do status da conectividade
  static String getConnectivityText() {
    return _isOnline ? 'Online' : 'Offline';
  }
}
