import 'package:flutter/material.dart';
import '../services/app_settings_service.dart';

class AppSettingsProvider extends ChangeNotifier {
  Currency _primaryCurrency = Currency.eur;
  Currency _convertedCurrency = Currency.none;
  Map<String, double> _exchangeRates = {};
  bool _isLoadingRates = false;
  bool _isInitialized = false;
  
  AppSettingsProvider() {
    initialize();
  }
  
  Currency get primaryCurrency => _primaryCurrency;
  Currency get convertedCurrency => _convertedCurrency;
  Map<String, double> get exchangeRates => _exchangeRates;
  bool get isLoadingRates => _isLoadingRates;
  bool get isInitialized => _isInitialized;
  
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _primaryCurrency = await AppSettingsService.loadPrimaryCurrency();
      _convertedCurrency = await AppSettingsService.loadConvertedCurrency();
      _isInitialized = true;
      notifyListeners();
      
      // Carrega as taxas de câmbio em segundo plano
      _loadExchangeRates();
    } catch (e) {
      print('Erro ao carregar configurações: $e');
    }
  }
  
  Future<void> _loadExchangeRates() async {
    try {
      _isLoadingRates = true;
      notifyListeners();
      
      final rates = await AppSettingsService.fetchExchangeRates();
      if (rates != null) {
        _exchangeRates = rates;
      }
      
      _isLoadingRates = false;
      notifyListeners();
    } catch (e) {
      print('Erro ao carregar taxas de câmbio: $e');
      _isLoadingRates = false;
      notifyListeners();
    }
  }
  
  Future<void> setPrimaryCurrency(Currency currency) async {
    if (_primaryCurrency == currency) return;
    
    try {
      await AppSettingsService.savePrimaryCurrency(currency);
      _primaryCurrency = currency;
      notifyListeners();
      
      // Recarrega as taxas se necessário
      if (_exchangeRates.isEmpty) {
        _loadExchangeRates();
      }
    } catch (e) {
      print('Erro ao atualizar moeda : $e');
    }
  }
  
  Future<void> setConvertedCurrency(Currency currency) async {
    if (_convertedCurrency == currency) return;
    
    try {
      await AppSettingsService.saveConvertedCurrency(currency);
      _convertedCurrency = currency;
      notifyListeners();
      
      // Recarrega as taxas se necessário
      if (_exchangeRates.isEmpty) {
        _loadExchangeRates();
      }
    } catch (e) {
      print('Erro ao atualizar moeda convertida: $e');
    }
  }
  
  Future<void> refreshExchangeRates() async {
    await _loadExchangeRates();
  }
  
  Future<String> formatPriceWithConversion(double price) async {
    return await AppSettingsService.formatPriceWithConversion(
      price, 
      _primaryCurrency,
      _convertedCurrency,
    );
  }

  // Síncrono: Formata usando as taxas em cache
  String formatPriceSync(double price) {
    return AppSettingsService.formatPrice(price, _primaryCurrency);
  }

  // Síncrono: Formata com conversão usando taxas em cache
  String formatPriceWithConversionSync(double price) {
    final primaryText = AppSettingsService.formatPrice(price, _primaryCurrency);
    
    if (_primaryCurrency == _convertedCurrency || _convertedCurrency == Currency.none) {
      return primaryText;
    }

    // Lógica de conversão síncrona
    double convertedValue = price;
    if (_exchangeRates.isNotEmpty) {
      if (_primaryCurrency == Currency.eur) {
         convertedValue = price * (_exchangeRates[_convertedCurrency.code] ?? 1.0);
      } else if (_convertedCurrency == Currency.eur) {
         convertedValue = price / (_exchangeRates[_primaryCurrency.code] ?? 1.0);
      } else {
         final amountInEur = price / (_exchangeRates[_primaryCurrency.code] ?? 1.0);
         convertedValue = amountInEur * (_exchangeRates[_convertedCurrency.code] ?? 1.0);
      }
    }

    final convertedText = AppSettingsService.formatPrice(convertedValue, _convertedCurrency);
    return '$primaryText | $convertedText';
  }
}
