import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class FoodCollection {
  const FoodCollection({required this.id, required this.name, this.description, this.placeIds = const []});
  final String id;
  final String name;
  final String? description;
  final List<String> placeIds;

  factory FoodCollection.fromJson(Map<String, dynamic> json) => FoodCollection(
    id: json['id'].toString(),
    name: json['name']?.toString() ?? 'Collection',
    description: json['description']?.toString(),
    placeIds: (json['placeIds'] as List<dynamic>? ?? []).map((item) => item.toString()).toList(),
  );
}

class CollectionsApi {
  CollectionsApi({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;
  String get _baseUrl {
    const custom = String.fromEnvironment('API_BASE_URL');
    if (custom.isNotEmpty) return custom;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) return 'http://10.0.2.2:3000';
    return 'http://localhost:3000';
  }

  Future<List<FoodCollection>> list() async {
    final response = await _client.get(Uri.parse('$_baseUrl/collections'), headers: await _headers());
    _check(response);
    return (jsonDecode(response.body) as List<dynamic>)
        .map((item) => FoodCollection.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<FoodCollection> create(String name, {String? description}) async {
    final response = await _client.post(Uri.parse('$_baseUrl/collections'), headers: {...await _headers(), 'Content-Type': 'application/json'}, body: jsonEncode({'name': name, 'description': description, 'placeIds': []}));
    _check(response);
    return FoodCollection.fromJson(jsonDecode(response.body));
  }

  Future<FoodCollection> update(String id, {String? name, String? description, List<String>? placeIds}) async {
    final response = await _client.patch(Uri.parse('$_baseUrl/collections/$id'), headers: {...await _headers(), 'Content-Type': 'application/json'}, body: jsonEncode({
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (placeIds != null) 'placeIds': placeIds,
    }));
    _check(response);
    return FoodCollection.fromJson(jsonDecode(response.body));
  }

  Future<void> remove(String id) async {
    final response = await _client.delete(Uri.parse('$_baseUrl/collections/$id'), headers: await _headers());
    _check(response);
  }

  Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');
    if (token == null) throw Exception('Please set up your profile first');
    return {'Authorization': 'Bearer $token'};
  }
  void _check(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw Exception('Could not load collections');
  }
}
