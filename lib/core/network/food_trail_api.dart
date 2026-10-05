import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class FoodTrailVisit {
  const FoodTrailVisit({required this.id, required this.restaurantName, this.address, this.latitude, this.longitude, this.visitedAt});
  final String id;
  final String restaurantName;
  final String? address;
  final double? latitude;
  final double? longitude;
  final DateTime? visitedAt;
  factory FoodTrailVisit.fromJson(Map<String, dynamic> json) => FoodTrailVisit(id: json['id'].toString(), restaurantName: json['restaurantName']?.toString() ?? 'Restaurant', address: json['address']?.toString(), latitude: (json['latitude'] as num?)?.toDouble(), longitude: (json['longitude'] as num?)?.toDouble(), visitedAt: DateTime.tryParse(json['visitedAt']?.toString() ?? ''));
}

class FoodTrailApi {
  FoodTrailApi({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;
  String get _baseUrl { const custom = String.fromEnvironment('API_BASE_URL'); if (custom.isNotEmpty) return custom; if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) return 'http://10.0.2.2:3000'; return 'http://localhost:3000'; }
  Future<List<FoodTrailVisit>> list() async { final response = await _client.get(Uri.parse('$_baseUrl/food-trail'), headers: await _headers()); _check(response); return (jsonDecode(response.body) as List<dynamic>).map((item) => FoodTrailVisit.fromJson(item)).toList(); }
  Future<FoodTrailVisit> add(String restaurantName, {String? address}) async { final response = await _client.post(Uri.parse('$_baseUrl/food-trail'), headers: {...await _headers(), 'Content-Type': 'application/json'}, body: jsonEncode({'restaurantName': restaurantName, 'address': address})); _check(response); return FoodTrailVisit.fromJson(jsonDecode(response.body)); }
  Future<Map<String, String>> _headers() async { final prefs = await SharedPreferences.getInstance(); final token = prefs.getString('accessToken'); if (token == null) throw Exception('Please set up your profile first'); return {'Authorization': 'Bearer $token'}; }
  void _check(http.Response response) { if (response.statusCode < 200 || response.statusCode >= 300) throw Exception('Could not load food trail'); }
}
