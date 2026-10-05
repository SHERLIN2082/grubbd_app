import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grubbd_app/features/sessions/price_range_selector.dart';

void main() {
  testWidgets('manual per-person budget validates and updates the amount', (
    tester,
  ) async {
    int? budget = 500;
    final formKey = GlobalKey<FormState>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Form(
            key: formKey,
            child: PriceRangeSelector(onChanged: (value) => budget = value),
          ),
        ),
      ),
    );
    expect(find.byKey(const Key('manual-price-field')), findsNothing);
    await tester.tap(find.text('Manual'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('price-slider')), findsNothing);
    await tester.enterText(find.byKey(const Key('manual-price-field')), '1250');
    await tester.pump();
    expect(budget, 1250);
    expect(find.text('Up to ₹1,250 per person'), findsNothing);
    expect(formKey.currentState!.validate(), isTrue);

    await tester.enterText(find.byKey(const Key('manual-price-field')), '0');
    await tester.pump();
    expect(formKey.currentState!.validate(), isFalse);
    expect(find.text('Enter an amount greater than zero'), findsOneWidget);
    await tester.tap(find.text('Slider'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<Slider>(find.byKey(const Key('price-slider'))).onChanged,
      isNotNull,
    );
    expect(find.byKey(const Key('manual-price-field')), findsNothing);
    expect(budget, 200);
    expect(formKey.currentState!.validate(), isTrue);
  });

  testWidgets('slider supports all presets and an unlimited upper budget', (
    tester,
  ) async {
    int? budget = 500;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Form(
            child: PriceRangeSelector(onChanged: (value) => budget = value),
          ),
        ),
      ),
    );
    final sliderFinder = find.byKey(const Key('price-slider'));
    for (final (index, expected) in <int?>[
      200,
      500,
      1000,
      2000,
      3000,
      5000,
      null,
    ].indexed) {
      tester.widget<Slider>(sliderFinder).onChanged!(index.toDouble());
      await tester.pump();
      expect(budget, expected);
      expect(find.byKey(const Key('manual-price-field')), findsNothing);
    }
    expect(tester.widget<Slider>(sliderFinder).label, '₹5,000+');
  });
}
