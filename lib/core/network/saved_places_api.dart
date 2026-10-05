import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SavedPlace {
  const SavedPlace({required this.id, required this.externalId, required this.restaurantName, this.address});
  final String id;
  final String externalId;
  final String restaurantName;
  final String? address;
  factory SavedPlace.fromJson(Map<String, dynamic> json) => SavedPlace(id: json['id'].toString(), externalId: json['externalId'].toString(), restaurantName: json['restaurantName']?.toString() ?? 'Restaurant', address: json['address']?.toString());
}

class SavedPlacesApi {
  SavedPlacesApi({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;
  String get _baseUrl { const custom = String.fromEnvironment('API_BASE_URL'); if (custom.isNotEmpty) return custom; if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) return 'http://10.0.2.2:3000'; return 'http://localhost:3000'; }
  Future<List<SavedPlace>> list() async { final response = await _client.get(Uri.parse('$_baseUrl/saved-places'), headers: await _headers()); _check(response); return (jsonDecode(response.body) as List<dynamic>).map((item) => SavedPlace.fromJson(item)).toList(); }
  Future<bool> toggle({required String externalId, required String restaurantName, String? address}) async { final response = await _client.post(Uri.parse('$_baseUrl/saved-places/toggle'), headers: {...await _headers(), 'Content-Type': 'application/json'}, body: jsonEncode({'externalId': externalId, 'restaurantName': restaurantName, 'address': address})); _check(response); return (jsonDecode(response.body) as Map<String, dynamic>)['saved'] == true; }
  Future<Map<String, String>> _headers() async { final prefs = await SharedPreferences.getInstance(); final token = prefs.getString('accessToken'); if (token == null) throw Exception('Please set up your profile first'); return {'Authorization': 'Bearer $token'}; }
  void _check(http.Response response) { if (response.statusCode < 200 || response.statusCode >= 300) throw Exception('Could not update saved places'); }
}
