// services/restaurant_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/restaurant.dart';

class RestaurantService {
  static String get baseUrl {
    return "https://api-node-0hjb.onrender.com";
  }

  Future<List<Restaurant>> fetchRestaurants() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/restuarant'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Restaurant.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load restaurants: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load restaurants: $e');
    }
  }
}
