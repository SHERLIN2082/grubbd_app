import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ProfileApi {
  ProfileApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<bool> hasSavedDeviceId() async {
    final preferences = await SharedPreferences.getInstance();
    final deviceId = preferences.getString('deviceId');
    return deviceId != null && deviceId.isNotEmpty;
  }

  Future<bool> loginAndCheckProfile() async {
    final preferences = await SharedPreferences.getInstance();
    final deviceId = await _getOrCreateDeviceId(preferences);

    final response = await _client.post(
      Uri.parse('$_baseUrl/auth/guest'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'deviceId': deviceId}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_readError(response.body));
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final token = json['accessToken'].toString();
    final user = json['user'] as Map<String, dynamic>;
    final isProfileCompleted = user['isProfileCompleted'] == true;

    await preferences.setString('accessToken', token);
    return isProfileCompleted;
  }

  String get _baseUrl {
    const customUrl = String.fromEnvironment('API_BASE_URL');
    if (customUrl.isNotEmpty) return customUrl;

    // Android emulators reach the computer through 10.0.2.2.
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000';
    }

    return 'http://localhost:3000';
  }

  Future<void> saveProfile({
    required String displayName,
    required String avatar,
  }) async {
    final token = await _getAccessToken();
    final response = await _client.patch(
      Uri.parse('$_baseUrl/users/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'displayName': displayName, 'avatar': avatar}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_readError(response.body));
    }
  }

  Future<String> _getAccessToken() async {
    final preferences = await SharedPreferences.getInstance();
    final savedToken = preferences.getString('accessToken');
    final savedDeviceId = preferences.getString('deviceId');

    if (savedToken != null && savedDeviceId != null) {
      return savedToken;
    }

    // This creates both the device ID and access token for a new profile.
    await loginAndCheckProfile();
    return preferences.getString('accessToken')!;
  }

  Future<String> _getOrCreateDeviceId(SharedPreferences preferences) async {
    var deviceId = preferences.getString('deviceId');

    if (deviceId == null) {
      deviceId = 'grubbd-${DateTime.now().microsecondsSinceEpoch}';
      await preferences.setString('deviceId', deviceId);
    }

    return deviceId;
  }

  String _readError(String body) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      return json['message']?.toString() ?? 'Something went wrong';
    } catch (_) {
      return 'Could not connect to the server';
    }
  }
}
