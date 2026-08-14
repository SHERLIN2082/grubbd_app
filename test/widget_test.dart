import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grubbd_app/app.dart';
import 'package:grubbd_app/core/constants/app_assets.dart';
import 'package:grubbd_app/features/first_screen/first_screen.dart';
import 'package:grubbd_app/features/loader/loader_screen.dart';

void main() {
  testWidgets('navigates from the first screen to the loader', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const GrubbdApp());

    expect(find.byType(FirstScreen), findsOneWidget);
    expect(find.byType(LoaderScreen), findsNothing);

    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(milliseconds: 500));

    final backgroundFinder = find.byWidgetPredicate(
      (widget) =>
          widget is Image &&
          widget.image == const AssetImage(AppAssets.firstScreenBackground),
    );
    final image = tester.widget<Image>(backgroundFinder);

    expect(image.image, const AssetImage(AppAssets.firstScreenBackground));
    expect(image.fit, BoxFit.cover);
    expect(backgroundFinder, findsOneWidget);
    expect(find.byType(FirstScreen), findsOneWidget);
    expect(find.byType(LoaderScreen), findsOneWidget);
    expect(find.byKey(const Key('loader-logo')), findsOneWidget);
    expect(find.byKey(const Key('loader-tagline')), findsOneWidget);
    expect(find.byKey(const Key('tagline-circle-animation')), findsOneWidget);
  });
}
