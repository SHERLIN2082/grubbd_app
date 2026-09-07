import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SessionLocation {
  const SessionLocation({
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  final String address;
  final double latitude;
  final double longitude;
}

class LocationSuggestion {
  const LocationSuggestion({required this.placeId, required this.description});

  final String placeId;
  final String description;
}

class CreatedSession {
  const CreatedSession({required this.id, required this.roomCode});

  final String id;
  final String roomCode;
}

class CreateSessionApi {
  CreateSessionApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  String get _baseUrl {
    const customUrl = String.fromEnvironment('API_BASE_URL');
    if (customUrl.isNotEmpty) return customUrl;

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000';
    }

    return 'http://localhost:3000';
  }

  Future<SessionLocation> reverseGeocode(
    double latitude,
    double longitude,
  ) async {
    final token = await _getToken();
    final uri = Uri.parse('$_baseUrl/places/reverse-geocode').replace(
      queryParameters: {
        'lat': latitude.toString(),
        'lng': longitude.toString(),
      },
    );
    final response = await _client.get(uri, headers: _authHeaders(token));
    _checkResponse(response);

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return SessionLocation(
      address: json['address'].toString(),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }

  Future<List<LocationSuggestion>> searchLocations(String query) async {
    final token = await _getToken();
    final uri = Uri.parse(
      '$_baseUrl/places/autocomplete',
    ).replace(queryParameters: {'query': query});
    final response = await _client.get(uri, headers: _authHeaders(token));
    _checkResponse(response);

    final list = jsonDecode(response.body) as List<dynamic>;
    final suggestions = <LocationSuggestion>[];

    for (final item in list) {
      final json = item as Map<String, dynamic>;
      final suggestion = LocationSuggestion(
        placeId: json['placeId'].toString(),
        description: json['description'].toString(),
      );
      suggestions.add(suggestion);
    }

    return suggestions;
  }

  Future<SessionLocation> getLocationDetails(String placeId) async {
    final token = await _getToken();
    final response = await _client.get(
      Uri.parse('$_baseUrl/places/$placeId'),
      headers: _authHeaders(token),
    );
    _checkResponse(response);

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return SessionLocation(
      address: json['address'].toString(),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }

  Future<CreatedSession> createSession({
    required SessionLocation location,
    required double radiusKm,
    required List<int> priceLevels,
    required String matchRule,
  }) async {
    final token = await _getToken();
    final response = await _client.post(
      Uri.parse('$_baseUrl/sessions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'location': {
          'address': location.address,
          'latitude': location.latitude,
          'longitude': location.longitude,
        },
        'radiusKm': radiusKm,
        'priceLevel': priceLevels,
        'matchRule': matchRule,
      }),
    );
    _checkResponse(response);

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return CreatedSession(
      id: json['id'].toString(),
      roomCode: json['roomCode'].toString(),
    );
  }

  Map<String, String> _authHeaders(String token) {
    return {'Authorization': 'Bearer $token'};
  }

  Future<String> _getToken() async {
    final preferences = await SharedPreferences.getInstance();
    final token = preferences.getString('accessToken');
    if (token == null) throw Exception('Please set up your profile first');
    return token;
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
