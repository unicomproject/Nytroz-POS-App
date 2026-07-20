import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/shared/widgets/pos_action_buttons.dart';

void main() {
  Widget host(Widget child) => MaterialApp(
        home: Scaffold(body: Center(child: child)),
      );

  testWidgets('uses canonical gradient and renders label and icons',
      (tester) async {
    await tester.pumpWidget(host(
      PosPrimaryActionButton(
        label: 'Continue',
        leadingIcon: Icons.add,
        trailingIcon: Icons.arrow_forward,
        onPressed: () {},
      ),
    ));

    final decoration = tester
        .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
        .first
        .decoration as BoxDecoration;
    expect(decoration.gradient, PosPrimaryActionTokens.gradient);
    expect(find.text('Continue'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
    expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
  });

  testWidgets('disabled state is neutral and non-clickable', (tester) async {
    await tester.pumpWidget(host(const PosPrimaryActionButton(
      label: 'Continue',
      onPressed: null,
    )));

    final decoration = tester
        .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
        .first
        .decoration as BoxDecoration;
    expect(decoration.gradient, isNull);
    expect(decoration.color, PosPrimaryActionTokens.disabledBackground);
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull);
  });

  testWidgets('loading blocks duplicate taps and preserves dimensions',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(host(PosPrimaryActionButton(
      label: 'Pay',
      isLoading: true,
      onPressed: () => taps++,
      fullWidth: true,
    )));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.byType(FilledButton));
    expect(taps, 0);
    expect(tester.getSize(find.byType(FilledButton)).height,
        greaterThanOrEqualTo(PosPrimaryActionTokens.height));
  });

  testWidgets('compact mode keeps a touchscreen-safe height', (tester) async {
    await tester.pumpWidget(host(PosPrimaryActionButton(
      label: 'Save',
      compact: true,
      semanticLabel: 'Save customer',
      onPressed: () {},
    )));

    expect(tester.getSize(find.byType(FilledButton)).height,
        greaterThanOrEqualTo(PosPrimaryActionTokens.compactHeight));
    expect(find.bySemanticsLabel('Save customer'), findsOneWidget);
  });
}
