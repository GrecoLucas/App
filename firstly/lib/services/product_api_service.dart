import 'dart:convert';
import 'package:http/http.dart' as http;

class ProductInfo {
  final String name;
  final String? brand;
  final String? category;


  ProductInfo({
    required this.name,
    this.brand,
    this.category,

  });

  factory ProductInfo.fromOpenFoodFacts(Map<String, dynamic> json) {
    final product = json['product'] as Map<String, dynamic>?;
    if (product == null) throw Exception('Produto não encontrado');

    String name = product['product_name'] ?? 
                 product['product_name_pt'] ?? 
                 product['product_name_en'] ?? 
                 'Produto desconhecido';

    return ProductInfo(
      name: name,
      brand: product['brands'],
      category: product['categories'],
    );
  }

  factory ProductInfo.fromUpcDatabase(Map<String, dynamic> json) {
    final items = json['items'] as List?;
    if (items == null || items.isEmpty) {
      throw Exception('Produto não encontrado');
    }

    final item = items.first as Map<String, dynamic>;
    return ProductInfo(
      name: item['title'] ?? 'Produto desconhecido',
      brand: item['brand'],
      category: item['category'],
    );
  }
}

class ProductApiService {
  static const String _openFoodFactsBaseUrl = 'https://world.openfoodfacts.org/api/v0/product';
  static const String _upcDatabaseBaseUrl = 'https://api.upcitemdb.com/prod/trial/lookup';

  /// Busca informações do produto pelo código de barras
  /// Tenta primeiro na Open Food Facts, depois na UPC Database
  static Future<ProductInfo?> getProductInfo(String barcode) async {
    try {
      // Primeiro tenta Open Food Facts (melhor para produtos alimentares)
      final openFoodResult = await _getFromOpenFoodFacts(barcode);
      if (openFoodResult != null) {
        print('Produto encontrado na Open Food Facts: ${openFoodResult.name}');
        return openFoodResult;
      }
    } catch (e) {
      print('Erro ao buscar na Open Food Facts: $e');
    }

    try {
      // Se não encontrou, tenta UPC Database
      final upcResult = await _getFromUpcDatabase(barcode);
      if (upcResult != null) {
        print('Produto encontrado na UPC Database: ${upcResult.name}');
        return upcResult;
      }
    } catch (e) {
      print('Erro ao buscar na UPC Database: $e');
    }

    print('Produto não encontrado em nenhuma API: $barcode');
    return null;
  }

  static Future<ProductInfo?> _getFromOpenFoodFacts(String barcode) async {
    try {
      final url = '$_openFoodFactsBaseUrl/$barcode.json';
      print('Buscando na Open Food Facts: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'SmartShop-App/1.0 (https://example.com)',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        
        // Verifica se o produto foi encontrado
        if (json['status'] == 1) {
          return ProductInfo.fromOpenFoodFacts(json);
        }
      }
      
      return null;
    } catch (e) {
      print('Erro na Open Food Facts: $e');
      return null;
    }
  }

  static Future<ProductInfo?> _getFromUpcDatabase(String barcode) async {
    try {
      final url = '$_upcDatabaseBaseUrl?upc=$barcode';
      print('Buscando na UPC Database: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'SmartShop-App/1.0',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        
        // Verifica se encontrou produtos
        if (json['code'] == 'OK' && json['total'] > 0) {
          return ProductInfo.fromUpcDatabase(json);
        }
      }
      
      return null;
    } catch (e) {
      print('Erro na UPC Database: $e');
      return null;
    }
  }
}
