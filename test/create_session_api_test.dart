import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:grubbd_app/core/network/create_session_api.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('creates a session with the selected settings', () async {
    SharedPreferences.setMockInitialValues({'accessToken': 'test-token'});

    final client = MockClient((request) async {
      expect(request.url.path, '/sessions');
      expect(request.headers['Authorization'], 'Bearer test-token');

      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['radiusKm'], 3.0);
      expect(body['priceLevel'], [1, 2]);
      expect(body['matchRule'], 'ALL');

      return http.Response('{"id":"10","roomCode":"A7B2C"}', 201);
    });

    final session = await CreateSessionApi(client: client).createSession(
      location: const SessionLocation(
        address: 'Selected address',
        latitude: 13.08,
        longitude: 80.27,
      ),
      radiusKm: 3,
      priceLevels: [1, 2],
      matchRule: 'ALL',
    );

    expect(session.id, '10');
    expect(session.roomCode, 'A7B2C');
  });
}
