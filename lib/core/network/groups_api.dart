import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class FoodGroup {
  const FoodGroup({required this.id, required this.name, this.description, this.memberIds = const [], this.members = const []});
  final String id;
  final String name;
  final String? description;
  final List<String> memberIds;
  final List<Map<String, dynamic>> members;
  factory FoodGroup.fromJson(Map<String, dynamic> json) => FoodGroup(
    id: json['id'].toString(), name: json['name']?.toString() ?? 'Group',
    description: json['description']?.toString(),
    memberIds: (json['memberIds'] as List<dynamic>? ?? []).map((item) => item.toString()).toList(),
    members: (json['members'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>(),
  );
}

class GroupsApi {
  GroupsApi({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;
  String get _baseUrl {
    const custom = String.fromEnvironment('API_BASE_URL');
    if (custom.isNotEmpty) return custom;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) return 'http://10.0.2.2:3000';
    return 'http://localhost:3000';
  }
  Future<List<FoodGroup>> list() async {
    final response = await _client.get(Uri.parse('$_baseUrl/groups'), headers: await _headers());
    _check(response);
    return (jsonDecode(response.body) as List<dynamic>).map((item) => FoodGroup.fromJson(item)).toList();
  }
  Future<FoodGroup> create(String name, {String? description}) async {
    final response = await _client.post(Uri.parse('$_baseUrl/groups'), headers: {...await _headers(), 'Content-Type': 'application/json'}, body: jsonEncode({'name': name, 'description': description}));
    _check(response);
    return FoodGroup.fromJson(jsonDecode(response.body));
  }
  Future<FoodGroup> join(String groupId) async {
    final response = await _client.post(Uri.parse('$_baseUrl/groups/$groupId/join'), headers: await _headers());
    _check(response);
    return FoodGroup.fromJson(jsonDecode(response.body));
  }
  Future<FoodGroup> getOne(String groupId) async {
    final response = await _client.get(Uri.parse('$_baseUrl/groups/$groupId'), headers: await _headers());
    _check(response);
    return FoodGroup.fromJson(jsonDecode(response.body));
  }
  Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');
    if (token == null) throw Exception('Please set up your profile first');
    return {'Authorization': 'Bearer $token'};
  }
  void _check(http.Response response) { if (response.statusCode < 200 || response.statusCode >= 300) throw Exception('Could not load groups'); }
}
