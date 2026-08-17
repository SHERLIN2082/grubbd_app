import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class HomeData {
  const HomeData({
    required this.displayName,
    required this.avatar,
    required this.recentSessions,
  });

  final String displayName;
  final String avatar;
  final List<RecentSession> recentSessions;
}

class RecentSession {
  const RecentSession({
    required this.id,
    required this.roomCode,
    required this.status,
    required this.restaurantName,
    required this.createdAt,
  });

  final String id;
  final String roomCode;
  final String status;
  final String? restaurantName;
  final DateTime? createdAt;
}

class HomeApi {
  // A custom client can be passed from tests. The app uses a normal client.
  HomeApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  String get _baseUrl {
    const customUrl = String.fromEnvironment('API_BASE_URL');
    if (customUrl.isNotEmpty) return customUrl;

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000';
    }

    return 'http://localhost:3000';
  }

  Future<HomeData> loadHome() async {
    // Use the token created during profile setup.
    final token = await _getToken();
    final headers = {'Authorization': 'Bearer $token'};

    // First, get the user's name and avatar.
    final profileResponse = await _client.get(
      Uri.parse('$_baseUrl/users/me'),
      headers: headers,
    );
    _checkResponse(profileResponse);

    // Next, get the user's five most recent sessions.
    final sessionsResponse = await _client.get(
      Uri.parse('$_baseUrl/sessions/recent'),
      headers: headers,
    );
    _checkResponse(sessionsResponse);

    final profile = jsonDecode(profileResponse.body) as Map<String, dynamic>;
    final sessionList = jsonDecode(sessionsResponse.body) as List<dynamic>;

    final displayName = profile['displayName']?.toString();
    final avatar = profile['avatar']?.toString();

    if (displayName == null || displayName.isEmpty) {
      throw Exception('The profile name is missing');
    }

    if (avatar == null || avatar.isEmpty) {
      throw Exception('The profile avatar is missing');
    }

    // Convert each JSON session into a RecentSession object.
    final sessions = <RecentSession>[];
    final sessionIds = <String>{};
    for (final item in sessionList) {
      final json = item as Map<String, dynamic>;
      final id = json['id']?.toString() ?? '';

      // Do not add an ID that has already been added.
      if (id.isEmpty || !sessionIds.add(id)) continue;

      sessions.add(
        RecentSession(
          id: id,
          roomCode: json['roomCode']?.toString() ?? '',
          status: json['status']?.toString() ?? '',
          restaurantName: json['restaurantName']?.toString(),
          createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
        ),
      );
    }

    return HomeData(
      displayName: displayName,
      avatar: avatar,
      recentSessions: sessions,
    );
  }

  Future<String> joinSession(String roomCode) async {
    final token = await _getToken();
    final response = await _client.post(
      Uri.parse('$_baseUrl/sessions/join'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'roomCode': roomCode}),
    );
    _checkResponse(response);

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return json['roomCode']?.toString() ?? roomCode;
  }

  Future<String> _getToken() async {
    final preferences = await SharedPreferences.getInstance();
    final token = preferences.getString('accessToken');
    if (token == null) {
      throw Exception('Please set up your profile first');
    }
    return token;
  }

  void _checkResponse(http.Response response) {
    final requestSucceeded =
        response.statusCode >= 200 && response.statusCode < 300;
    if (requestSucceeded) return;

    var message = 'Something went wrong';
    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      message = json['message']?.toString() ?? message;
    } catch (_) {}

    throw Exception(message);
  }
}
