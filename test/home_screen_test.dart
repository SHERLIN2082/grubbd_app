import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grubbd_app/core/network/home_api.dart';
import 'package:grubbd_app/features/home/home_screen.dart';

class FakeHomeApi extends HomeApi {
  FakeHomeApi(this.sessions);
  final List<RecentSession> sessions;

  @override
  Future<HomeData> loadHome() async =>
      HomeData(displayName: 'Alex', avatar: 'AL', recentSessions: sessions);
}

RecentSession session(String status) => RecentSession(
  id: status,
  roomCode: 'ABCDE',
  status: status,
  restaurantName: null,
  createdAt: null,
);

void main() {
  testWidgets('home offers rejoin only for lobby and active rooms', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          homeApi: FakeHomeApi([
            session('LOBBY'),
            session('ACTIVE'),
            session('COMPLETED'),
            session('HOST_LEFT'),
          ]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Rejoin Lobby'), findsOneWidget);
    expect(find.text('Rejoin Active Session'), findsOneWidget);
    expect(find.byKey(const ValueKey('rejoin-COMPLETED')), findsNothing);
    expect(find.byKey(const ValueKey('rejoin-HOST_LEFT')), findsNothing);
    expect(find.text('Recent Sessions'), findsNothing);
  });

  testWidgets('home hides the session section when no rooms are open', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(homeApi: FakeHomeApi([session('COMPLETED')])),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Recent Sessions'), findsNothing);
    expect(find.textContaining('Rejoin'), findsNothing);
    expect(find.text('Create Session'), findsOneWidget);
    expect(find.text('Join Session'), findsOneWidget);
  });
}
