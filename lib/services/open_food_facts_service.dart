import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service for interacting with the Open Food Facts API
/// Documentation: https://world.openfoodfacts.org/data
class OpenFoodFactsService {
  static const String _baseUrl = 'https://world.openfoodfacts.org/api/v2';

  /// Fetches product information by barcode
  /// Returns null if product not found or API error occurs
  /// Timeout: 10 seconds
  static Future<OpenFoodFactsProduct?> getProductByBarcode(String barcode) async {
    try {
      final url = Uri.parse('$_baseUrl/product/$barcode');
      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Request timed out after 10 seconds');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Check if product was found
        if (data['status'] == 1 && data['product'] != null) {
          return OpenFoodFactsProduct.fromJson(data['product']);
        }
      }

      return null;
    } catch (e) {
      // Return null on any error
      return null;
    }
  }

  /// Searches for products by name
  /// Returns list of matching products
  /// Timeout: 10 seconds
  static Future<List<OpenFoodFactsProduct>> searchProducts(String query, {int pageSize = 10}) async {
    try {
      final url = Uri.parse('$_baseUrl/search').replace(queryParameters: {
        'search_terms': query,
        'page_size': pageSize.toString(),
        'json': '1',
      });

      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Request timed out after 10 seconds');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['products'] != null) {
          final List<dynamic> products = data['products'];
          return products
              .map((json) => OpenFoodFactsProduct.fromJson(json))
              .toList();
        }
      }

      return [];
    } catch (e) {
      return [];
    }
  }
}

/// Model for Open Food Facts product data
/// Only imports essential data: name, weight, and kcal per 100g
class OpenFoodFactsProduct {
  final String? productName;
  final double? productQuantityGrams;
  final double? energyKcal100g;

  OpenFoodFactsProduct({
    this.productName,
    this.productQuantityGrams,
    this.energyKcal100g,
  });

  factory OpenFoodFactsProduct.fromJson(Map<String, dynamic> json) {
    // Extract nutriments
    final nutriments = json['nutriments'] as Map<String, dynamic>?;

    // Try to get product quantity in grams
    double? quantityGrams;
    if (json['product_quantity'] != null) {
      quantityGrams = _parseDouble(json['product_quantity']);
    } else if (json['quantity'] != null) {
      // Try to parse from quantity string (e.g., "500g", "1kg")
      quantityGrams = _parseQuantityString(json['quantity'].toString());
    }

    return OpenFoodFactsProduct(
      productName: json['product_name']?.toString() ?? json['product_name_en']?.toString(),
      productQuantityGrams: quantityGrams,
      energyKcal100g: nutriments != null ? _parseDouble(nutriments['energy-kcal_100g']) : null,
    );
  }

  /// Helper to parse double from dynamic value
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  /// Helper to parse quantity strings like "500g", "1kg", "250ml"
  static double? _parseQuantityString(String quantity) {
    // Remove spaces and convert to lowercase
    quantity = quantity.trim().toLowerCase();

    // Try to extract number and unit
    final regex = RegExp(r'(\d+\.?\d*)\s*(g|kg|ml|l)?');
    final match = regex.firstMatch(quantity);

    if (match != null) {
      final number = double.tryParse(match.group(1) ?? '');
      final unit = match.group(2);

      if (number != null) {
        // Convert to grams
        switch (unit) {
          case 'kg':
            return number * 1000;
          case 'g':
            return number;
          case 'ml':
          case 'l':
            // Assume 1ml = 1g for simplicity (not accurate for all products)
            return unit == 'l' ? number * 1000 : number;
          default:
            return number;
        }
      }
    }

    return null;
  }

  /// Check if the product has nutrition data
  bool get hasNutritionData {
    return energyKcal100g != null;
  }

  /// Get a display name for the product
  String get displayName {
    return productName ?? 'Unknown Product';
  }

  @override
  String toString() {
    return 'OpenFoodFactsProduct(name: $productName, weight: $productQuantityGrams g, kcal: $energyKcal100g)';
  }
}
