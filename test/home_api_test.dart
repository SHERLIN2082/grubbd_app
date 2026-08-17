import 'package:flutter_test/flutter_test.dart';
import 'package:grubbd_app/core/network/home_api.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('loads the profile and recent sessions', () async {
    SharedPreferences.setMockInitialValues({'accessToken': 'test-token'});

    final client = MockClient((request) async {
      expect(request.headers['Authorization'], 'Bearer test-token');

      if (request.url.path == '/users/me') {
        return http.Response('{"displayName":"Alex","avatar":"AL"}', 200);
      }

      return http.Response(
        '[{"id":"1","roomCode":"A7B2C","status":"COMPLETED",'
        '"restaurantName":"Saffron Table",'
        '"createdAt":"2026-08-17T10:00:00.000Z"}]',
        200,
      );
    });

    final data = await HomeApi(client: client).loadHome();

    expect(data.displayName, 'Alex');
    expect(data.avatar, 'AL');
    expect(data.recentSessions.single.restaurantName, 'Saffron Table');
  });
}
