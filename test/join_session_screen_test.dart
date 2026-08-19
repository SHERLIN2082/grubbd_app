import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grubbd_app/features/sessions/join_session_screen.dart';

void main() {
  testWidgets('shows validation for a short room code', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: JoinSessionScreen()));

    await tester.enterText(find.byKey(const Key('room-code-field')), 'AB');
    await tester.tap(find.byKey(const Key('join-session-submit')));
    await tester.pump();

    expect(find.text('Enter a valid 5-character room code'), findsOneWidget);
  });
}
