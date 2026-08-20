import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LobbyDetails {
  const LobbyDetails({
    required this.id,
    required this.roomCode,
    required this.status,
    required this.isHost,
    required this.locationName,
    required this.radiusKm,
    required this.priceLevels,
    required this.matchRule,
  });

  final String id;
  final String roomCode;
  final String status;
  final bool isHost;
  final String locationName;
  final double radiusKm;
  final List<int> priceLevels;
  final String matchRule;
}

class LobbyParticipant {
  const LobbyParticipant({
    required this.id,
    required this.displayName,
    required this.avatar,
    required this.isHost,
  });

  final String id;
  final String displayName;
  final String avatar;
  final bool isHost;
}

class LobbyApi {
  LobbyApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  String get _baseUrl {
    const customUrl = String.fromEnvironment('API_BASE_URL');
    if (customUrl.isNotEmpty) return customUrl;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000';
    }
    return 'http://localhost:3000';
  }

  Future<LobbyDetails> getSession(String sessionId) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/sessions/$sessionId'),
      headers: await _headers(),
    );
    _checkResponse(response);
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final prices = (json['priceLevel'] as List<dynamic>? ?? const [])
        .map((value) => (value as num).toInt())
        .toList();
    return LobbyDetails(
      id: json['id'].toString(),
      roomCode: json['roomCode'].toString(),
      status: json['status'].toString(),
      isHost: json['isHost'] == true,
      locationName: json['locationName']?.toString() ?? 'Selected location',
      radiusKm: (json['radiusKm'] as num?)?.toDouble() ?? 0,
      priceLevels: prices,
      matchRule: json['matchRule']?.toString() ?? 'ALL',
    );
  }

  Future<List<LobbyParticipant>> getParticipants(String sessionId) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/sessions/$sessionId/participants'),
      headers: await _headers(),
    );
    _checkResponse(response);
    final list = jsonDecode(response.body) as List<dynamic>;
    return list.map((item) {
      final json = item as Map<String, dynamic>;
      return LobbyParticipant(
        id: json['id'].toString(),
        displayName: json['displayName']?.toString() ?? 'Guest',
        avatar: json['avatar']?.toString() ?? '',
        isHost: json['isHost'] == true,
      );
    }).toList();
  }

  Future<void> startSession(String sessionId) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/sessions/$sessionId/start'),
      headers: await _headers(),
    );
    _checkResponse(response);
  }

  Future<Map<String, String>> _headers() async {
    final preferences = await SharedPreferences.getInstance();
    final token = preferences.getString('accessToken');
    if (token == null) throw Exception('Please set up your profile first');
    return {'Authorization': 'Bearer $token'};
  }

  void _checkResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    var message = 'Something went wrong';
    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      message = json['message']?.toString() ?? message;
    } catch (_) {}
    throw Exception(message);
  }
}
