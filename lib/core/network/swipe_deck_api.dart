import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SwipeRestaurant {
  const SwipeRestaurant({
    required this.id,
    required this.name,
    required this.rating,
    required this.priceLevel,
    required this.address,
    required this.photoReference,
    required this.googleMapsUrl,
  });

  final String id;
  final String name;
  final double? rating;
  final int? priceLevel;
  final String? address;
  final String? photoReference;
  final String? googleMapsUrl;
}

class SwipeResult {
  const SwipeResult({required this.matched, this.matchId, this.matchName});

  final bool matched;
  final String? matchId;
  final String? matchName;
}

class MatchVoter {
  const MatchVoter({required this.name, required this.avatar});

  final String name;
  final String avatar;
}

class MatchDetails {
  const MatchDetails({
    required this.id,
    required this.isHost,
    required this.restaurant,
    required this.voters,
  });

  final String id;
  final bool isHost;
  final SwipeRestaurant restaurant;
  final List<MatchVoter> voters;
}

class SessionResult {
  const SessionResult({
    required this.restaurant,
    required this.yesCount,
    required this.totalParticipants,
    required this.distanceKm,
  });

  final SwipeRestaurant restaurant;
  final int yesCount;
  final int totalParticipants;
  final double? distanceKm;
}

class SessionResultsSummary {
  const SessionResultsSummary({
    required this.results,
    required this.hasExactMatches,
  });

  final List<SessionResult> results;
  final bool hasExactMatches;
}

class SwipeDeckApi {
  SwipeDeckApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  String get _baseUrl {
    const customUrl = String.fromEnvironment('API_BASE_URL');
    if (customUrl.isNotEmpty) return customUrl;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000';
    }
    return 'http://localhost:3000';
  }

  Future<List<SwipeRestaurant>> getRestaurants(String sessionId) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/sessions/$sessionId/restaurants'),
      headers: await _headers(),
    );
    _checkResponse(response);
    final list = jsonDecode(response.body) as List<dynamic>;

    // Turn every JSON object from the API into a restaurant object.
    final restaurants = list.map((item) {
      final json = item as Map<String, dynamic>;
      return _readRestaurant(json);
    }).toList();

    final seenIds = <String>{};
    final seenNames = <String>{};
    return restaurants.where((restaurant) {
      final nameKey = _normalize(restaurant.name);
      return seenIds.add(restaurant.id) && seenNames.add(nameKey);
    }).toList();
  }

  Future<SwipeRestaurant> getRestaurant(
    String sessionId,
    String restaurantId,
  ) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/sessions/$sessionId/restaurants/$restaurantId'),
      headers: await _headers(),
    );
    _checkResponse(response);
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return _readRestaurant(json);
  }

  // This helper keeps the JSON-reading code in one simple place.
  SwipeRestaurant _readRestaurant(Map<String, dynamic> json) {
    return SwipeRestaurant(
      id: json['id'].toString(),
      name: json['name']?.toString() ?? 'Restaurant',
      rating: (json['rating'] as num?)?.toDouble(),
      priceLevel: (json['priceLevel'] as num?)?.toInt(),
      address: json['address']?.toString(),
      photoReference: json['photoReference']?.toString(),
      googleMapsUrl: json['googleMapsUrl']?.toString(),
    );
  }

  String _normalize(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  Future<Uint8List> getPhoto(String photoReference) async {
    final uri = Uri.parse(
      '$_baseUrl/places/photo',
    ).replace(queryParameters: {'reference': photoReference});
    final response = await _client.get(uri, headers: await _headers());
    _checkResponse(response);
    return response.bodyBytes;
  }

  Future<SwipeResult> submitSwipe({
    required String sessionId,
    required String restaurantId,
    required bool liked,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/sessions/$sessionId/swipes'),
      headers: {...await _headers(), 'Content-Type': 'application/json'},
      body: jsonEncode({
        'restaurantId': restaurantId,
        'vote': liked ? 'YES' : 'NO',
      }),
    );
    _checkResponse(response);
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final match = json['match'] as Map<String, dynamic>?;
    return SwipeResult(
      matched: json['matched'] == true,
      matchId: match?['id']?.toString(),
      matchName: match?['name']?.toString(),
    );
  }

  Future<String?> getLatestMatchId(String sessionId) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/sessions/$sessionId/matches/latest'),
      headers: await _headers(),
    );
    _checkResponse(response);
    if (response.body == 'null') return null;
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return json['id']?.toString();
  }

  Future<MatchDetails> getMatch(String sessionId, String matchId) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/sessions/$sessionId/matches/$matchId'),
      headers: await _headers(),
    );
    _checkResponse(response);
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final voterList = json['yesVoters'] as List<dynamic>? ?? [];
    final voters = voterList.map((item) {
      final voter = item as Map<String, dynamic>;
      return MatchVoter(
        name: voter['name']?.toString() ?? 'Guest',
        avatar: voter['avatar']?.toString() ?? '',
      );
    }).toList();
    return MatchDetails(
      id: json['id'].toString(),
      isHost: json['isHost'] == true,
      restaurant: _readRestaurant(json['restaurant'] as Map<String, dynamic>),
      voters: voters,
    );
  }

  Future<SessionResultsSummary> getResults(String sessionId) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/sessions/$sessionId/results'),
      headers: await _headers(),
    );
    _checkResponse(response);

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final matches = json['matches'] as List<dynamic>? ?? [];
    final bestOverlap = json['bestOverlap'] as List<dynamic>? ?? [];
    final hasExactMatches = matches.isNotEmpty;
    final resultList = hasExactMatches ? matches : bestOverlap;
    final results = <SessionResult>[];

    for (final item in resultList) {
      final resultJson = item as Map<String, dynamic>;
      final restaurantJson = <String, dynamic>{
        'id': resultJson['restaurantId'],
        'name': resultJson['restaurantName'],
        'rating': resultJson['rating'],
        'priceLevel': null,
        'address': resultJson['address'],
        'photoReference': resultJson['photoReference'],
        'googleMapsUrl': resultJson['googleMapsUrl'],
      };

      results.add(
        SessionResult(
          restaurant: _readRestaurant(restaurantJson),
          yesCount: (resultJson['yesCount'] as num?)?.toInt() ?? 0,
          totalParticipants:
              (resultJson['totalParticipants'] as num?)?.toInt() ?? 0,
          distanceKm: (resultJson['distanceKm'] as num?)?.toDouble(),
        ),
      );
    }

    return SessionResultsSummary(
      results: results,
      hasExactMatches: hasExactMatches,
    );
  }

  Future<void> chooseFinalRestaurant(
    String sessionId,
    String restaurantId,
  ) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/sessions/$sessionId/final-pick'),
      headers: {...await _headers(), 'Content-Type': 'application/json'},
      body: jsonEncode({'restaurantId': restaurantId}),
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
