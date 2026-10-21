import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grubbd_app/core/network/profile_api.dart';
import 'package:grubbd_app/features/profile/update_profile_screen.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'accessToken': 'test-token',
      'deviceId': 'test-device',
    });
  });

  testWidgets('renders UpdateProfileDialog with initial name and saves successfully', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    String? savedDisplayName;
    String? savedAvatar;

    final mockClient = MockClient((request) async {
      if (request.url.path == '/auth/guest') {
        return http.Response(
          '{"accessToken":"test-token","user":{"id":"u1","isProfileCompleted":true}}',
          200,
        );
      }
      if (request.url.path == '/users/profile' && request.method == 'PATCH') {
        final body = request.body;
        if (body.contains('TacoMaster')) {
          savedDisplayName = 'TacoMaster';
        }
        if (body.contains('avatar-1.png')) {
          savedAvatar = 'assets/images/avatars/avatar-1.png';
        }
        return http.Response('{"success":true}', 200);
      }
      return http.Response('{}', 200);
    });

    final profileApi = ProfileApi(client: mockClient);
    bool onSavedCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UpdateProfileDialog(
            initialName: 'FoodieFan',
            initialAvatar: 'assets/images/avatars/avatar-1.png',
            profileApi: profileApi,
            onSaved: (val) {
              onSavedCalled = true;
            },
          ),
        ),
      ),
    );

    // Verify Title and Subtitle
    expect(find.text('Update Profile ✨'), findsOneWidget);
    expect(find.text('Customize your avatar & foodie name'), findsOneWidget);

    // Verify Name field contains 'FoodieFan'
    final nameFieldFinder = find.byKey(const Key('profile-name-field'));
    expect(nameFieldFinder, findsOneWidget);
    expect(find.text('FoodieFan'), findsOneWidget);

    // Enter a new name
    await tester.enterText(nameFieldFinder, 'TacoMaster');
    await tester.pump();
    expect(find.text('TacoMaster'), findsOneWidget);

    // Tap Save Profile button
    final saveButton = find.byKey(const Key('save-profile-button'));
    expect(saveButton, findsOneWidget);
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pump();
    await tester.pumpAndSettle();

    expect(savedDisplayName, 'TacoMaster');
    expect(savedAvatar, 'assets/images/avatars/avatar-1.png');
    expect(onSavedCalled, isTrue);
  });

  testWidgets('shows validation error when name is empty', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: UpdateProfileDialog(
            initialName: '',
            initialAvatar: 'assets/images/avatars/avatar-1.png',
          ),
        ),
      ),
    );

    final saveButton = find.byKey(const Key('save-profile-button'));
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pump();

    expect(find.text('Please enter your foodie nickname'), findsOneWidget);
  });
}

