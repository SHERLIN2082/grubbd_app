import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grubbd_app/core/network/collections_api.dart';
import 'package:grubbd_app/core/widgets/app_back_button.dart';
import 'package:grubbd_app/features/collections/collections_screen.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'accessToken': 'test-token'});
  });

  testWidgets('AppBackButton pops current route when canPop is true', (
    WidgetTester tester,
  ) async {
    bool popped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (ctx) => Scaffold(
                      appBar: AppBar(
                        leading: AppBackButton(
                          onPressed: () {
                            popped = true;
                            Navigator.of(ctx).pop();
                          },
                        ),
                      ),
                      body: const Text('Detail Screen'),
                    ),
                  ),
                );
              },
              child: const Text('Open'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Detail Screen'), findsOneWidget);
    expect(find.byType(AppBackButton), findsOneWidget);

    await tester.tap(find.byType(AppBackButton));
    await tester.pumpAndSettle();

    expect(popped, isTrue);
    expect(find.text('Detail Screen'), findsNothing);
    expect(find.text('Open'), findsOneWidget);
  });

  testWidgets('CollectionsScreen displays AppBackButton', (
    WidgetTester tester,
  ) async {
    final client = MockClient((request) async {
      return http.Response('[]', 200);
    });

    await tester.pumpWidget(
      MaterialApp(
        home: CollectionsScreen(
          api: CollectionsApi(client: client),
        ),
      ),
    );

    await tester.pump();

    expect(find.byType(AppBackButton), findsOneWidget);
    expect(find.text('Food Collections 🔖'), findsOneWidget);
  });
}
