import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nytroz_pos/core/access/effective_permission_set.dart';
import 'package:nytroz_pos/core/access/permission_access_providers.dart';
import 'package:nytroz_pos/core/access/pos_access_codes.dart';
import 'package:nytroz_pos/features/cash_drawer/presentation/widgets/close_till_form_card.dart';

/// Full close-till form fields (non-blind): counted entry + expected + difference
/// + mismatch reason so validation/difference UI is present.
final _fullCloseTillFormPermissions = EffectivePermissionSet.fromIterable({
  PosPermissionCodes.tillClosingCountedCashEntry,
  PosPermissionCodes.tillClosingExpectedCash,
  PosPermissionCodes.tillClosingDifference,
  PosPermissionCodes.tillClosingMismatchReason,
  PosPermissionCodes.tillClosingNotes,
});

void main() {
  Future<void> pumpForm(
    WidgetTester tester, {
    required GlobalKey<FormState> formKey,
    required TextEditingController countedCashController,
    required TextEditingController notesController,
    required double expectedCash,
    EffectivePermissionSet? permissions,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          effectivePermissionSetProvider.overrideWithValue(
            permissions ?? _fullCloseTillFormPermissions,
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: CloseTillFormCard(
              formKey: formKey,
              countedCashController: countedCashController,
              notesController: notesController,
              expectedCash: expectedCash,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('close till form does not render manager PIN or approval text',
      (tester) async {
    final formKey = GlobalKey<FormState>();
    final countedCashController = TextEditingController();
    final notesController = TextEditingController();

    addTearDown(countedCashController.dispose);
    addTearDown(notesController.dispose);

    await pumpForm(
      tester,
      formKey: formKey,
      countedCashController: countedCashController,
      notesController: notesController,
      expectedCash: 100,
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

    await pumpForm(
      tester,
      formKey: formKey,
      countedCashController: countedCashController,
      notesController: notesController,
      expectedCash: 100,
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

    await pumpForm(
      tester,
      formKey: formKey,
      countedCashController: countedCashController,
      notesController: notesController,
      expectedCash: 100,
    );

    await tester.enterText(find.byType(TextFormField).first, '90.00');
    await tester.pump();

    expect(formKey.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('Mismatch reason is required'), findsOneWidget);
  });

  testWidgets(
      'blind count keeps expected cash and difference absent',
      (tester) async {
    final formKey = GlobalKey<FormState>();
    final countedCashController = TextEditingController();
    final notesController = TextEditingController();

    addTearDown(countedCashController.dispose);
    addTearDown(notesController.dispose);

    // Blind-count: counted entry + mismatch/notes allowed; expected/difference DENIED.
    await pumpForm(
      tester,
      formKey: formKey,
      countedCashController: countedCashController,
      notesController: notesController,
      expectedCash: 100,
      permissions: EffectivePermissionSet.fromIterable({
        PosPermissionCodes.tillClosingCountedCashEntry,
        PosPermissionCodes.tillClosingMismatchReason,
        PosPermissionCodes.tillClosingNotes,
      }),
    );

    expect(find.text('Counted Cash *'), findsOneWidget);
    expect(find.text('Expected Cash'), findsNothing);
    expect(find.textContaining('Difference', findRichText: true), findsNothing);
  });
}
