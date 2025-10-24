import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service for interacting with the Open Food Facts API
/// Documentation: https://world.openfoodfacts.org/data
class OpenFoodFactsService {
  static const String _baseUrl = 'https://world.openfoodfacts.org/api/v2';

  /// Fetches product information by barcode
  /// Returns null if product not found or API error occurs
  static Future<OpenFoodFactsProduct?> getProductByBarcode(String barcode) async {
    try {
      final url = Uri.parse('$_baseUrl/product/$barcode');
      final response = await http.get(url);

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
  static Future<List<OpenFoodFactsProduct>> searchProducts(String query, {int pageSize = 10}) async {
    try {
      final url = Uri.parse('$_baseUrl/search').replace(queryParameters: {
        'search_terms': query,
        'page_size': pageSize.toString(),
        'json': '1',
      });

      final response = await http.get(url);

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
class OpenFoodFactsProduct {
  final String? code;
  final String? productName;
  final String? brands;
  final double? energyKcal100g;
  final double? carbohydrates100g;
  final double? fat100g;
  final double? proteins100g;
  final String? imageUrl;
  final List<String> ingredientTags;
  final double? productQuantityGrams;

  OpenFoodFactsProduct({
    this.code,
    this.productName,
    this.brands,
    this.energyKcal100g,
    this.carbohydrates100g,
    this.fat100g,
    this.proteins100g,
    this.imageUrl,
    this.ingredientTags = const [],
    this.productQuantityGrams,
  });

  factory OpenFoodFactsProduct.fromJson(Map<String, dynamic> json) {
    // Extract nutriments
    final nutriments = json['nutriments'] as Map<String, dynamic>?;

    // Extract ingredient tags and clean them up
    List<String> tags = [];
    if (json['ingredients_tags'] != null) {
      final rawTags = json['ingredients_tags'] as List<dynamic>;
      tags = rawTags
          .map((tag) => tag.toString())
          .map((tag) => _cleanIngredientTag(tag))
          .where((tag) => tag.isNotEmpty)
          .toList();
    }

    // Try to get product quantity in grams
    double? quantityGrams;
    if (json['product_quantity'] != null) {
      quantityGrams = _parseDouble(json['product_quantity']);
    } else if (json['quantity'] != null) {
      // Try to parse from quantity string (e.g., "500g", "1kg")
      quantityGrams = _parseQuantityString(json['quantity'].toString());
    }

    return OpenFoodFactsProduct(
      code: json['code']?.toString(),
      productName: json['product_name']?.toString() ?? json['product_name_en']?.toString(),
      brands: json['brands']?.toString(),
      energyKcal100g: nutriments != null ? _parseDouble(nutriments['energy-kcal_100g']) : null,
      carbohydrates100g: nutriments != null ? _parseDouble(nutriments['carbohydrates_100g']) : null,
      fat100g: nutriments != null ? _parseDouble(nutriments['fat_100g']) : null,
      proteins100g: nutriments != null ? _parseDouble(nutriments['proteins_100g']) : null,
      imageUrl: json['image_url']?.toString() ?? json['image_front_url']?.toString(),
      ingredientTags: tags,
      productQuantityGrams: quantityGrams,
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

  /// Clean up ingredient tags from Open Food Facts format
  /// e.g., "en:milk" -> "milk", "en:wheat-flour" -> "wheat flour"
  static String _cleanIngredientTag(String tag) {
    // Remove language prefix (e.g., "en:", "fr:")
    tag = tag.replaceFirst(RegExp(r'^[a-z]{2}:'), '');

    // Replace hyphens with spaces
    tag = tag.replaceAll('-', ' ');

    // Capitalize first letter of each word
    tag = tag.split(' ')
        .map((word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1))
        .join(' ');

    return tag.trim();
  }

  /// Check if the product has sufficient nutrition data
  bool get hasNutritionData {
    return energyKcal100g != null &&
        carbohydrates100g != null &&
        fat100g != null &&
        proteins100g != null;
  }

  /// Get a display name for the product
  String get displayName {
    if (productName != null && productName!.isNotEmpty) {
      if (brands != null && brands!.isNotEmpty) {
        return '$brands - $productName';
      }
      return productName!;
    }
    return 'Unknown Product';
  }

  @override
  String toString() {
    return 'OpenFoodFactsProduct(code: $code, name: $productName, brands: $brands, '
           'kcal: $energyKcal100g, carbs: $carbohydrates100g, fat: $fat100g, protein: $proteins100g)';
  }
}
