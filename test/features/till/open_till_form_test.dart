import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/core/access/effective_permission_set.dart';
import 'package:nytroz_pos/core/access/permission_access_providers.dart';
import 'package:nytroz_pos/core/access/pos_access_codes.dart';
import 'package:nytroz_pos/features/till/presentation/widgets/open_till_form.dart';

/// Full Open Till UI grant for fixture tests (Chunk 14 fine-grained keys).
final _fullOpenTillPermissions = EffectivePermissionSet.fromIterable([
  PosPermissionCodes.tillSessionOpen,
  PosPermissionCodes.tillOpeningStartingCashView,
  PosPermissionCodes.tillOpeningStartingCashEntry,
  PosPermissionCodes.tillOpeningValidationMessage,
  PosPermissionCodes.tillOpeningNoteView,
  PosPermissionCodes.tillOpeningNoteEntry,
  PosPermissionCodes.tillOpeningQuickAmounts,
  PosPermissionCodes.tillOpeningQuickSlot1,
  PosPermissionCodes.tillOpeningQuickSlot2,
  PosPermissionCodes.tillOpeningQuickSlot3,
  PosPermissionCodes.tillOpeningNumpad,
  PosPermissionCodes.tillOpeningBackspace,
  PosPermissionCodes.tillOpeningClear,
  PosPermissionCodes.tillOpeningConfirmMessage,
  PosPermissionCodes.tillOpeningKey0,
  PosPermissionCodes.tillOpeningKey1,
  PosPermissionCodes.tillOpeningKey2,
  PosPermissionCodes.tillOpeningKey3,
  PosPermissionCodes.tillOpeningKey4,
  PosPermissionCodes.tillOpeningKey5,
  PosPermissionCodes.tillOpeningKey6,
  PosPermissionCodes.tillOpeningKey7,
  PosPermissionCodes.tillOpeningKey8,
  PosPermissionCodes.tillOpeningKey9,
  PosPermissionCodes.tillOpeningKey00,
  PosPermissionCodes.tillOpeningKeyDecimal,
]);

void main() {
  group('OpenTillForm', () {
    testWidgets('renders till summary and open action', (tester) async {
      final formKey = GlobalKey<FormState>();
      final openingFloatController = TextEditingController(text: '150.00');
      final openingNoteController = TextEditingController();

      await _pumpOpenTillForm(
        tester,
        formKey: formKey,
        openingFloatController: openingFloatController,
        openingNoteController: openingNoteController,
      );

      expect(find.text('Open Till'), findsWidgets);
      expect(find.text('Front Till'), findsWidgets);
      expect(find.text('Main Outlet'), findsOneWidget);
      expect(find.text('DEV-001'), findsOneWidget);
      expect(find.text('Amount is valid'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsNothing);
      expect(find.byType(FilledButton), findsOneWidget);
    });

    testWidgets('requires opening cash amount', (tester) async {
      final formKey = GlobalKey<FormState>();
      final openingFloatController = TextEditingController();
      final openingNoteController = TextEditingController();

      await _pumpOpenTillForm(
        tester,
        formKey: formKey,
        openingFloatController: openingFloatController,
        openingNoteController: openingNoteController,
      );

      expect(formKey.currentState!.validate(), isFalse);
      await tester.pump();
      expect(find.text('Opening cash is required.'), findsOneWidget);

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('shows API error message when provided', (tester) async {
      final formKey = GlobalKey<FormState>();
      final openingFloatController = TextEditingController(text: '150.00');
      final openingNoteController = TextEditingController();

      await _pumpOpenTillForm(
        tester,
        formKey: formKey,
        openingFloatController: openingFloatController,
        openingNoteController: openingNoteController,
        errorMessage: 'Till already has an open session.',
      );

      expect(
        find.text('Till already has an open session.'),
        findsOneWidget,
      );
    });

    testWidgets('quick amount and keypad update the opening amount',
        (tester) async {
      final formKey = GlobalKey<FormState>();
      final openingFloatController = TextEditingController(text: '0.00');
      final openingNoteController = TextEditingController();

      await _pumpOpenTillForm(
        tester,
        formKey: formKey,
        openingFloatController: openingFloatController,
        openingNoteController: openingNoteController,
      );

      await tester.tap(find.text('500'));
      await tester.pump();
      expect(openingFloatController.text, '500.00');

      await tester.tap(find.text('2'));
      await tester.pump();
      expect(openingFloatController.text, '5002.00');

      await tester.tap(find.text('C'));
      await tester.pump();
      expect(openingFloatController.text, '0.00');
    });

    testWidgets('disables submit while request is in progress', (tester) async {
      final formKey = GlobalKey<FormState>();
      final openingFloatController = TextEditingController(text: '150.00');
      final openingNoteController = TextEditingController();

      await _pumpOpenTillForm(
        tester,
        formKey: formKey,
        openingFloatController: openingFloatController,
        openingNoteController: openingNoteController,
        isSubmitting: true,
      );

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('fits fixed tablet height without summary overflow',
        (tester) async {
      final formKey = GlobalKey<FormState>();
      final openingFloatController = TextEditingController(text: '0.00');
      final openingNoteController = TextEditingController();

      tester.view.physicalSize = const Size(1280, 768);
      addTearDown(tester.view.resetPhysicalSize);

      await _pumpOpenTillForm(
        tester,
        formKey: formKey,
        openingFloatController: openingFloatController,
        openingNoteController: openingNoteController,
        openingBy: 'CASHIER001@GMAIL.COM',
        outletName: 'Development Main Store',
        tillName: 'Front Till 01',
        deviceName: 'POS-01',
        size: const Size(997, 640),
      );

      expect(find.text('Till Summary'), findsOneWidget);
      expect(find.text('CASHIER001@GMAIL.COM'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

Future<void> _pumpOpenTillForm(
  WidgetTester tester, {
  required GlobalKey<FormState> formKey,
  required TextEditingController openingFloatController,
  required TextEditingController openingNoteController,
  bool isSubmitting = false,
  String outletName = 'Main Outlet',
  String tillName = 'Front Till',
  String deviceName = 'DEV-001',
  String currencyCode = 'LKR',
  String openingBy = 'Cashier',
  String? errorMessage,
  Size size = const Size(997, 700),
}) async {
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        effectivePermissionSetProvider.overrideWithValue(
          _fullOpenTillPermissions,
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: SafeArea(
            child: Center(
              child: SizedBox(
                width: size.width,
                height: size.height,
                child: OpenTillForm(
                  formKey: formKey,
                  openingFloatController: openingFloatController,
                  openingNoteController: openingNoteController,
                  isSubmitting: isSubmitting,
                  outletName: outletName,
                  tillName: tillName,
                  deviceName: deviceName,
                  currencyCode: currencyCode,
                  openingBy: openingBy,
                  errorMessage: errorMessage,
                  onSubmit: () {},
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  if (!isSubmitting) {
    await tester.pumpAndSettle();
  }
}
