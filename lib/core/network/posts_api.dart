import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class FoodPost {
  const FoodPost({
    required this.id,
    required this.restaurantName,
    required this.story,
    required this.authorName,
    this.authorAvatar,
    this.imageUrl,
    this.rating,
    this.dishes = const [],
    this.vibes = const [],
    this.createdAt,
    this.likeCount = 0,
    this.commentCount = 0,
  });

  final String id;
  final String restaurantName;
  final String story;
  final String authorName;
  final String? authorAvatar;
  final String? imageUrl;
  final double? rating;
  final List<String> dishes;
  final List<String> vibes;
  final DateTime? createdAt;
  final int likeCount;
  final int commentCount;

  factory FoodPost.fromJson(Map<String, dynamic> json) {
    final author = json['author'] as Map<String, dynamic>? ?? {};
    return FoodPost(
      id: json['id'].toString(),
      restaurantName: json['restaurantName']?.toString() ?? 'Restaurant',
      story: json['story']?.toString() ?? '',
      authorName: author['displayName']?.toString() ?? 'Grubbd user',
      authorAvatar: author['avatar']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
      rating: (json['rating'] as num?)?.toDouble(),
      dishes: _strings(json['dishes']),
      vibes: _strings(json['vibes']),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      likeCount: (json['likeCount'] as num?)?.toInt() ?? 0,
      commentCount: (json['commentCount'] as num?)?.toInt() ?? 0,
    );
  }

  static List<String> _strings(dynamic value) {
    if (value is! List) return const [];
    return value.map((item) => item.toString()).toList();
  }
}

class PostsApi {
  PostsApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  String get _baseUrl {
    const customUrl = String.fromEnvironment('API_BASE_URL');
    if (customUrl.isNotEmpty) return customUrl;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000';
    }
    return 'http://localhost:3000';
  }

  Future<List<FoodPost>> list() async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/posts'),
      headers: await _headers(),
    );
    _check(response);
    return (jsonDecode(response.body) as List<dynamic>)
        .map((item) => FoodPost.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<FoodPost> create({
    required String restaurantName,
    required String story,
    String? imageUrl,
    double? rating,
    List<String> dishes = const [],
    List<String> vibes = const [],
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/posts'),
      headers: {...await _headers(), 'Content-Type': 'application/json'},
      body: jsonEncode({
        'restaurantName': restaurantName,
        'story': story,
        'imageUrl': imageUrl,
        'rating': rating,
        'dishes': dishes,
        'vibes': vibes,
      }),
    );
    _check(response);
    return FoodPost.fromJson(jsonDecode(response.body));
  }

  Future<FoodPost> getOne(String postId) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/posts/$postId'),
      headers: await _headers(),
    );
    _check(response);
    return FoodPost.fromJson(jsonDecode(response.body));
  }

  Future<FoodPost> update(String postId, {String? restaurantName, String? story, String? imageUrl, double? rating, List<String>? dishes, List<String>? vibes}) async {
    final response = await _client.patch(Uri.parse('$_baseUrl/posts/$postId'), headers: {...await _headers(), 'Content-Type': 'application/json'}, body: jsonEncode({
      if (restaurantName != null) 'restaurantName': restaurantName,
      if (story != null) 'story': story,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (rating != null) 'rating': rating,
      if (dishes != null) 'dishes': dishes,
      if (vibes != null) 'vibes': vibes,
    }));
    _check(response);
    return FoodPost.fromJson(jsonDecode(response.body));
  }

  Future<void> remove(String postId) async {
    final response = await _client.delete(Uri.parse('$_baseUrl/posts/$postId'), headers: await _headers());
    _check(response);
  }

  Future<String> uploadImageDataUrl(String dataUrl) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/media/image'),
      headers: {...await _headers(), 'Content-Type': 'application/json'},
      body: jsonEncode({'data': dataUrl}),
    );
    _check(response);
    return (jsonDecode(response.body) as Map<String, dynamic>)['url'].toString();
  }

  Future<Map<String, dynamic>> toggleLike(String postId) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/posts/$postId/like'),
      headers: await _headers(),
    );
    _check(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> comments(String postId) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/posts/$postId/comments'),
      headers: await _headers(),
    );
    _check(response);
    return (jsonDecode(response.body) as List<dynamic>)
        .cast<Map<String, dynamic>>();
  }

  Future<void> addComment(String postId, String text) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/posts/$postId/comments'),
      headers: {...await _headers(), 'Content-Type': 'application/json'},
      body: jsonEncode({'text': text}),
    );
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
    throw Exception('Could not load food posts');
  }
}
