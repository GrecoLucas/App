import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

enum Currency {
  eur('EUR', 'Euro (€)', '€'),
  usd('USD', 'Dólar (\$)', '\$'),
  brl('BRL', 'Real (R\$)', 'R\$'),
  none('NONE', 'Sem conversão', '');

  const Currency(this.code, this.displayName, this.symbol);
  
  final String code;
  final String displayName;
  final String symbol;
}

class AppSettingsService {
  static const String _primaryCurrencyKey = 'app_primary_currency';
  static const String _convertedCurrencyKey = 'app_converted_currency';
  static const String _exchangeRatesKey = 'app_exchange_rates';
  static const String _lastUpdateKey = 'app_rates_last_update';

  // Configurações padrão
  static const Currency _defaultPrimaryCurrency = Currency.eur;
  static const Currency _defaultConvertedCurrency = Currency.none;

  /// Salva a moeda principal selecionada
  static Future<void> savePrimaryCurrency(Currency currency) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_primaryCurrencyKey, currency.name);
    } catch (e) {
      print('Erro ao salvar moeda principal: $e');
    }
  }

  /// Salva a moeda convertida selecionada
  static Future<void> saveConvertedCurrency(Currency currency) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_convertedCurrencyKey, currency.name);
    } catch (e) {
      print('Erro ao salvar moeda convertida: $e');
    }
  }

  /// Carrega a moeda principal salva
  static Future<Currency> loadPrimaryCurrency() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currencyString = prefs.getString(_primaryCurrencyKey);
      
      if (currencyString == null) {
        return _defaultPrimaryCurrency;
      }

      for (final currency in Currency.values) {
        if (currency.name == currencyString) {
          return currency;
        }
      }
      
      return _defaultPrimaryCurrency;
    } catch (e) {
      print('Erro ao carregar moeda principal: $e');
      return _defaultPrimaryCurrency;
    }
  }

  /// Carrega a moeda convertida salva
  static Future<Currency> loadConvertedCurrency() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currencyString = prefs.getString(_convertedCurrencyKey);
      
      if (currencyString == null) {
        return _defaultConvertedCurrency;
      }

      for (final currency in Currency.values) {
        if (currency.name == currencyString) {
          return currency;
        }
      }
      
      return _defaultConvertedCurrency;
    } catch (e) {
      print('Erro ao carregar moeda convertida: $e');
      return _defaultConvertedCurrency;
    }
  }

  /// Busca taxas de câmbio em tempo real
  static Future<Map<String, double>?> fetchExchangeRates() async {
    try {
      // Usando API gratuita do ExchangeRate-API
      final response = await http.get(
        Uri.parse('https://api.exchangerate-api.com/v4/latest/EUR'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rates = Map<String, double>.from(data['rates']);
        
        // Salvar no cache local
        await _saveExchangeRates(rates);
        
        return rates;
      }
    } catch (e) {
      print('Erro ao buscar taxas de câmbio: $e');
    }
    
    // Se falhou, tentar carregar do cache
    return await _loadCachedExchangeRates();
  }

  /// Salva as taxas de câmbio no cache local
  static Future<void> _saveExchangeRates(Map<String, double> rates) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ratesJson = jsonEncode(rates);
      await prefs.setString(_exchangeRatesKey, ratesJson);
      await prefs.setInt(_lastUpdateKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      print('Erro ao salvar taxas de câmbio: $e');
    }
  }

  /// Carrega as taxas de câmbio do cache local
  static Future<Map<String, double>?> _loadCachedExchangeRates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ratesJson = prefs.getString(_exchangeRatesKey);
      
      if (ratesJson != null) {
        final lastUpdate = prefs.getInt(_lastUpdateKey) ?? 0;
        final now = DateTime.now().millisecondsSinceEpoch;
        
        // Cache válido por 1 hora
        if (now - lastUpdate < 3600000) {
          return Map<String, double>.from(jsonDecode(ratesJson));
        }
      }
    } catch (e) {
      print('Erro ao carregar taxas de câmbio do cache: $e');
    }
    
    // Retornar taxas padrão se não conseguir carregar
    return {
      'USD': 1.1,
      'BRL': 6.0,
      'EUR': 1.0,
    };
  }

  /// Converte um valor entre moedas
  static Future<double> convertCurrency(
    double amount,
    Currency from,
    Currency to,
  ) async {
    if (from == to) return amount;

    final rates = await fetchExchangeRates();
    if (rates == null) return amount;

    try {
      if (from == Currency.eur) {
        // De EUR para outra moeda
        return amount * (rates[to.code] ?? 1.0);
      } else if (to == Currency.eur) {
        // De outra moeda para EUR
        return amount / (rates[from.code] ?? 1.0);
      } else {
        // Entre duas moedas não-EUR
        final amountInEur = amount / (rates[from.code] ?? 1.0);
        return amountInEur * (rates[to.code] ?? 1.0);
      }
    } catch (e) {
      print('Erro na conversão de moeda: $e');
      return amount;
    }
  }

  /// Formata um valor monetário com a moeda especificada
  static String formatPrice(double price, Currency currency) {
    return '${currency.symbol} ${price.toStringAsFixed(2)}';
  }

  /// Formata com conversão (mostra valor principal e convertido)
  static Future<String> formatPriceWithConversion(
    double price,
    Currency primaryCurrency,
    Currency convertedCurrency,
  ) async {
    final primaryText = formatPrice(price, primaryCurrency);
    
    if (primaryCurrency == convertedCurrency || convertedCurrency == Currency.none) {
      return primaryText;
    }

    final convertedValue = await convertCurrency(price, primaryCurrency, convertedCurrency);
    final convertedText = formatPrice(convertedValue, convertedCurrency);
    
    return '$primaryText | $convertedText';
  }

  /// Retorna todas as configurações do app
  static Future<Map<String, dynamic>> getAllSettings() async {
    final primaryCurrency = await loadPrimaryCurrency();
    final convertedCurrency = await loadConvertedCurrency();
    
    return {
      'primaryCurrency': primaryCurrency,
      'convertedCurrency': convertedCurrency,
    };
  }
}
