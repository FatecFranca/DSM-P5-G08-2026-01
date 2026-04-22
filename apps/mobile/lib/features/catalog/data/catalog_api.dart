import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product_model.dart';

class CatalogApi {
  static Future<List<ProductItem>> fetchProducts() async {
    final res = await http.get(
      Uri.parse('https://dummyjson.com/products?limit=0'),
    );

    final data = jsonDecode(res.body);
    return (data['products'] as List)
        .map((e) => ProductItem.fromJson(e))
        .toList();
  }

  static Future<List<String>> fetchCategories() async {
    final res = await http.get(
      Uri.parse('https://dummyjson.com/products/categories'),
    );
    final data = jsonDecode(res.body);
    return List<String>.from(data);
  }
}
