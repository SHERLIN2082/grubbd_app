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

  test('loads completed session history with joined members', () async {
    SharedPreferences.setMockInitialValues({'accessToken': 'test-token'});

    final client = MockClient((request) async {
      expect(request.url.path, '/sessions/history');
      return http.Response(
        '[{"id":"2","roomCode":"Q9X3K","status":"COMPLETED",'
        '"restaurantName":"Curry House","members":['
        '{"id":"1","displayName":"Alex","isHost":true},'
        '{"id":"2","displayName":"Sam","isHost":false}]}]',
        200,
      );
    });

    final history = await HomeApi(client: client).loadHistory();

    expect(history.single.status, 'COMPLETED');
    expect(history.single.members.map((member) => member['displayName']),
        containsAll(<String>['Alex', 'Sam']));
  });
}
