import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grubbd_app/core/network/create_session_api.dart';
import 'package:grubbd_app/features/sessions/map_confirmation_screen.dart';

void main() {
  testWidgets('shows the map confirmation screen', (tester) async {
    const location = SessionLocation(
      address: 'Selected location',
      latitude: 13.08,
      longitude: 80.27,
    );

    await tester.pumpWidget(
      const MaterialApp(home: MapConfirmationScreen(location: location)),
    );

    expect(find.text('Selected location'), findsOneWidget);
    expect(find.byKey(const Key('map-location-marker')), findsOneWidget);
    expect(find.byKey(const Key('confirm-location-button')), findsOneWidget);
  });
}
