// services/restaurant_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/restaurant.dart';

class RestaurantService {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:5000';
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:5000';
    } else if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      return 'http://127.0.0.1:5000';
    } else {
      return 'http://192.168.1.7:5000';
    }
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
