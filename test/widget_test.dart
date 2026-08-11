import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grubbd_app/app.dart';
import 'package:grubbd_app/core/constants/app_assets.dart';
import 'package:grubbd_app/features/first_screen/first_screen.dart';

void main() {
  testWidgets('shows the picnic image on the root screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const GrubbdApp());

    final image = tester.widget<Image>(find.byType(Image));

    expect(
      image.image,
      const AssetImage(AppAssets.firstScreenBackground),
    );
    expect(image.fit, BoxFit.cover);
    expect(find.byType(FirstScreen), findsOneWidget);
  });
}
