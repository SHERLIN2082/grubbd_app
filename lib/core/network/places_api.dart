import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:grubbd_app/core/network/swipe_deck_api.dart';

class PlacesApi {
  PlacesApi({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;
  Future<List<Map<String, String>>> autocomplete(String query) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');
    if (token == null) throw Exception('Please set up your profile first');
    final uri = Uri.parse(
      '$_baseUrl/places/autocomplete',
    ).replace(queryParameters: {'query': query});
    final response = await _client.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Search failed');
    }
    final items = jsonDecode(response.body) as List<dynamic>;
    return items.map((item) {
      final json = item as Map<String, dynamic>;
      return {
        'placeId': json['placeId'].toString(),
        'description': json['description'].toString(),
      };
    }).toList();
  }

  Future<List<SwipeRestaurant>> searchRestaurants(String query) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');
    if (token == null) throw Exception('Please set up your profile first');
    final uri = Uri.parse(
      '$_baseUrl/places/search',
    ).replace(queryParameters: {'query': query});
    final response = await _client.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Search failed');
    }
    final items = jsonDecode(response.body) as List<dynamic>;
    return items.map((item) {
      final json = item as Map<String, dynamic>;
      final geometry = json['geometry'] as Map<String, dynamic>?;
      final location = geometry?['location'] as Map<String, dynamic>?;
      return SwipeRestaurant(
        id: json['place_id'].toString(),
        name: json['name']?.toString() ?? 'Restaurant',
        rating: (json['rating'] as num?)?.toDouble(),
        priceLevel: (json['price_level'] as num?)?.toInt(),
        address: json['vicinity']?.toString(),
        photoReference: null,
        googleMapsUrl: null,
        latitude: (json['latitude'] as num?)?.toDouble() ?? (location?['lat'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble() ?? (location?['lng'] as num?)?.toDouble(),
      );
    }).toList();
  }

  String get _baseUrl {
    const custom = String.fromEnvironment('API_BASE_URL');
    if (custom.isNotEmpty) return custom;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000';
    }
    return 'http://localhost:3000';
  }

  Future<List<SwipeRestaurant>> nearby({
    required double latitude,
    required double longitude,
    String? foodPreference,
    String? category,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');
    if (token == null) throw Exception('Please set up your profile first');
    final query = {'lat': '$latitude', 'lng': '$longitude', 'radiusKm': '5'};
    if (foodPreference != null && foodPreference != 'Any food') {
      query['foodPreference'] = foodPreference;
    }
    if (category != null) query['category'] = category;
    final uri = Uri.parse(
      '$_baseUrl/places/nearby',
    ).replace(queryParameters: query);
    final response = await _client.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Could not load nearby restaurants');
    }
    final items = jsonDecode(response.body) as List<dynamic>;
    return items.map((item) {
      final json = item as Map<String, dynamic>;
      final photos = json['photos'] as List<dynamic>?;
      final firstPhoto = photos != null && photos.isNotEmpty
          ? photos.first as Map<String, dynamic>
          : null;
      final geometry = json['geometry'] as Map<String, dynamic>?;
      final location = geometry?['location'] as Map<String, dynamic>?;
      return SwipeRestaurant(
        id: json['place_id'].toString(),
        name: json['name']?.toString() ?? 'Restaurant',
        rating: (json['rating'] as num?)?.toDouble(),
        priceLevel: (json['price_level'] as num?)?.toInt(),
        address: json['vicinity']?.toString(),
        photoReference: firstPhoto?['photo_reference']?.toString(),
        googleMapsUrl: null,
        latitude: (json['latitude'] as num?)?.toDouble() ?? (location?['lat'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble() ?? (location?['lng'] as num?)?.toDouble(),
      );
    }).toList();
  }
}
