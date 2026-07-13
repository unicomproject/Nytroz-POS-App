import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nytroz_pos/features/cash_drawer/presentation/widgets/close_till_form_card.dart';

void main() {
  testWidgets('close till form does not render manager PIN or approval text',
      (tester) async {
    final formKey = GlobalKey<FormState>();
    final countedCashController = TextEditingController();
    final notesController = TextEditingController();

    addTearDown(countedCashController.dispose);
    addTearDown(notesController.dispose);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: CloseTillFormCard(
              formKey: formKey,
              countedCashController: countedCashController,
              notesController: notesController,
              expectedCash: 100,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Manager PIN'), findsNothing);
    expect(find.textContaining('manager', findRichText: true), findsNothing);
    expect(find.textContaining('approval', findRichText: true), findsNothing);
  });

  testWidgets('matching counted cash validates without mismatch reason',
      (tester) async {
    final formKey = GlobalKey<FormState>();
    final countedCashController = TextEditingController();
    final notesController = TextEditingController();

    addTearDown(countedCashController.dispose);
    addTearDown(notesController.dispose);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: CloseTillFormCard(
              formKey: formKey,
              countedCashController: countedCashController,
              notesController: notesController,
              expectedCash: 100,
            ),
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField).first, '100.00');
    await tester.pump();

    expect(formKey.currentState!.validate(), isTrue);
    expect(find.text('Mismatch reason is required'), findsNothing);
  });

  testWidgets('cash variance requires mismatch reason', (tester) async {
    final formKey = GlobalKey<FormState>();
    final countedCashController = TextEditingController();
    final notesController = TextEditingController();

    addTearDown(countedCashController.dispose);
    addTearDown(notesController.dispose);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: CloseTillFormCard(
              formKey: formKey,
              countedCashController: countedCashController,
              notesController: notesController,
              expectedCash: 100,
            ),
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField).first, '90.00');
    await tester.pump();

    expect(formKey.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('Mismatch reason is required'), findsOneWidget);
  });
}
