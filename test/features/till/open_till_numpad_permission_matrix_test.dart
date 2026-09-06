import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/core/access/effective_permission_set.dart';
import 'package:nytroz_pos/core/access/permission_access_providers.dart';
import 'package:nytroz_pos/core/access/pos_access_codes.dart';
import 'package:nytroz_pos/core/access/pos_cash_drawer_till_visibility.dart';
import 'package:nytroz_pos/features/till/presentation/widgets/open_till_form.dart';

EffectivePermissionSet _set(Iterable<String> codes) =>
    EffectivePermissionSet.fromIterable(codes);

Set<String> get _fullOpenTillKeys => {
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
    };

void main() {
  group('Open Till numpad — catalog / visibility helpers', () {
    test('BLOCKING A — session.open alone does not auto-grant keys', () {
      final p = _set([PosPermissionCodes.tillSessionOpen]);
      expect(PosCashDrawerTillVisibility.canOpenTill(p), isTrue);
      expect(PosCashDrawerTillVisibility.canShowOpenTillNumpad(p), isFalse);
      expect(PosCashDrawerTillVisibility.canShowStartingCashEntry(p), isFalse);
      for (final key in [
        '0',
        '1',
        '2',
        '3',
        '4',
        '5',
        '6',
        '7',
        '8',
        '9',
        '00',
        '.',
      ]) {
        expect(
          PosCashDrawerTillVisibility.canShowOpenTillNumpadKey(p, key),
          isFalse,
          reason: 'parent must not auto-grant key $key',
        );
        expect(
          PosCashDrawerTillVisibility.canAuthorizeOpenTillKeyInput(p, key),
          isFalse,
        );
      }
      expect(
        PosCashDrawerTillVisibility.filterOpenTillQuickAmounts(p),
        isEmpty,
      );
    });

    test('BLOCKING B — partial keypad: only granted keys authorize', () {
      final p = _set([
        PosPermissionCodes.tillSessionOpen,
        PosPermissionCodes.tillOpeningStartingCashEntry,
        PosPermissionCodes.tillOpeningNumpad,
        PosPermissionCodes.tillOpeningKey1,
        PosPermissionCodes.tillOpeningKey3,
        PosPermissionCodes.tillOpeningBackspace,
      ]);
      expect(
        PosCashDrawerTillVisibility.canAuthorizeOpenTillKeyInput(p, '1'),
        isTrue,
      );
      expect(
        PosCashDrawerTillVisibility.canAuthorizeOpenTillKeyInput(p, '2'),
        isFalse,
      );
      expect(
        PosCashDrawerTillVisibility.canAuthorizeOpenTillKeyInput(p, '3'),
        isTrue,
      );
      expect(
        PosCashDrawerTillVisibility.canAuthorizeOpenTillKeyInput(p, '.'),
        isFalse,
      );
      expect(
        PosCashDrawerTillVisibility.canAuthorizeOpenTillBackspace(p),
        isTrue,
      );
      expect(PosCashDrawerTillVisibility.canAuthorizeOpenTillClear(p), isFalse);
    });

    test('BLOCKING D — numpad container denied blocks key authorize', () {
      final p = _set([
        PosPermissionCodes.tillSessionOpen,
        PosPermissionCodes.tillOpeningStartingCashEntry,
        PosPermissionCodes.tillOpeningKey7,
      ]);
      expect(PosCashDrawerTillVisibility.canShowOpenTillNumpad(p), isFalse);
      expect(
        PosCashDrawerTillVisibility.canAuthorizeOpenTillKeyInput(p, '7'),
        isFalse,
      );
      expect(
        PosCashDrawerTillVisibility.canShowOpenTillNumpadKey(p, '7'),
        isTrue,
        reason: 'key membership is independent; container gates authorize',
      );
    });

    test('BLOCKING E — entry vs view are independent', () {
      final entryOnly = _set([
        PosPermissionCodes.tillOpeningStartingCashEntry,
      ]);
      final viewOnly = _set([
        PosPermissionCodes.tillOpeningStartingCashView,
      ]);
      expect(
        PosCashDrawerTillVisibility.canShowStartingCashEntry(entryOnly),
        isTrue,
      );
      expect(
        PosCashDrawerTillVisibility.canShowStartingCashView(entryOnly),
        isFalse,
      );
      expect(
        PosCashDrawerTillVisibility.canShowStartingCashView(viewOnly),
        isTrue,
      );
      expect(
        PosCashDrawerTillVisibility.canShowStartingCashEntry(viewOnly),
        isFalse,
      );
    });

    test('quick slots filter independently under container', () {
      final p = _set([
        PosPermissionCodes.tillOpeningQuickAmounts,
        PosPermissionCodes.tillOpeningQuickSlot1,
        PosPermissionCodes.tillOpeningQuickSlot3,
      ]);
      expect(
        PosCashDrawerTillVisibility.filterOpenTillQuickAmounts(p),
        [100, 1000],
      );
    });

    test('quick container denied yields empty even with slots', () {
      final p = _set([
        PosPermissionCodes.tillOpeningQuickSlot1,
        PosPermissionCodes.tillOpeningQuickSlot2,
      ]);
      expect(
        PosCashDrawerTillVisibility.filterOpenTillQuickAmounts(p),
        isEmpty,
      );
    });
  });

  group('Open Till form — UI / keyboard gates', () {
    Future<void> pumpForm(
      WidgetTester tester, {
      required Set<String> permissions,
      required TextEditingController floatController,
      Size surface = const Size(1200, 900),
    }) async {
      final formKey = GlobalKey<FormState>();
      final noteController = TextEditingController();
      await tester.binding.setSurfaceSize(surface);
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
        noteController.dispose();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            effectivePermissionSetProvider.overrideWithValue(
              EffectivePermissionSet.fromIterable(permissions),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: OpenTillForm(
                formKey: formKey,
                openingFloatController: floatController,
                openingNoteController: noteController,
                isSubmitting: false,
                outletName: 'Outlet',
                tillName: 'Till 1',
                deviceName: 'DEV-1',
                currencyCode: 'LKR',
                openingBy: 'Cashier',
                onSubmit: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('BLOCKING A UI — root-only: no protected keys render',
        (tester) async {
      final float = TextEditingController(text: '0.00');
      addTearDown(float.dispose);
      await pumpForm(
        tester,
        permissions: {PosPermissionCodes.tillSessionOpen},
        floatController: float,
      );

      for (final key in [
        '0',
        '1',
        '2',
        '3',
        '4',
        '5',
        '6',
        '7',
        '8',
        '9',
        '00',
        '.',
      ]) {
        expect(find.byKey(ValueKey('open-till-key-$key')), findsNothing);
      }
      expect(
        find.byKey(const ValueKey('open-till-key-backspace')),
        findsNothing,
      );
      expect(find.byKey(const ValueKey('open-till-key-clear')), findsNothing);
      expect(find.byKey(const ValueKey('open-till-quick-100')), findsNothing);
      expect(find.byKey(const Key('opening-cash-field')), findsNothing);
    });

    testWidgets('BLOCKING B UI — partial keys reflow without blank slots',
        (tester) async {
      final float = TextEditingController(text: '0.00');
      addTearDown(float.dispose);
      await pumpForm(
        tester,
        permissions: {
          PosPermissionCodes.tillSessionOpen,
          PosPermissionCodes.tillOpeningStartingCashEntry,
          PosPermissionCodes.tillOpeningStartingCashView,
          PosPermissionCodes.tillOpeningNumpad,
          PosPermissionCodes.tillOpeningKey1,
          PosPermissionCodes.tillOpeningKey3,
          PosPermissionCodes.tillOpeningBackspace,
        },
        floatController: float,
      );

      expect(find.byKey(const ValueKey('open-till-key-1')), findsOneWidget);
      expect(find.byKey(const ValueKey('open-till-key-2')), findsNothing);
      expect(find.byKey(const ValueKey('open-till-key-3')), findsOneWidget);
      expect(find.byKey(const ValueKey('open-till-key-.')), findsNothing);
      expect(
        find.byKey(const ValueKey('open-till-key-backspace')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('open-till-key-1')));
      await tester.pump();
      expect(float.text, '1.00');

      await tester.tap(find.byKey(const ValueKey('open-till-key-3')));
      await tester.pump();
      expect(float.text, '13.00');
    });

    testWidgets('BLOCKING C — revoke digit 7 removes key and keyboard path',
        (tester) async {
      final float = TextEditingController(text: '0.00');
      addTearDown(float.dispose);
      final formKey = GlobalKey<FormState>();
      final note = TextEditingController();
      addTearDown(note.dispose);

      final permissions = ValueNotifier<EffectivePermissionSet>(
        EffectivePermissionSet.fromIterable(_fullOpenTillKeys),
      );
      addTearDown(permissions.dispose);

      await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValueListenableBuilder<EffectivePermissionSet>(
              valueListenable: permissions,
              builder: (context, perms, _) {
                return ProviderScope(
                  overrides: [
                    effectivePermissionSetProvider.overrideWithValue(perms),
                  ],
                  child: OpenTillForm(
                    formKey: formKey,
                    openingFloatController: float,
                    openingNoteController: note,
                    isSubmitting: false,
                    outletName: 'Outlet',
                    tillName: 'Till 1',
                    deviceName: 'DEV-1',
                    currencyCode: 'LKR',
                    openingBy: 'Cashier',
                    onSubmit: () {},
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('open-till-key-7')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('open-till-key-7')));
      await tester.pump();
      expect(float.text, '7.00');

      permissions.value = EffectivePermissionSet.fromIterable(
        _fullOpenTillKeys.difference({PosPermissionCodes.tillOpeningKey7}),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('open-till-key-7')), findsNothing);

      final before = float.text;
      await tester.sendKeyEvent(LogicalKeyboardKey.digit7);
      await tester.pump();
      expect(float.text, before);
    });

    testWidgets('BLOCKING D UI — container denied: no digit keys',
        (tester) async {
      final float = TextEditingController(text: '0.00');
      addTearDown(float.dispose);
      await pumpForm(
        tester,
        permissions: {
          PosPermissionCodes.tillSessionOpen,
          PosPermissionCodes.tillOpeningStartingCashEntry,
          PosPermissionCodes.tillOpeningStartingCashView,
          PosPermissionCodes.tillOpeningKey1,
          PosPermissionCodes.tillOpeningKey2,
          PosPermissionCodes.tillOpeningBackspace,
          PosPermissionCodes.tillOpeningClear,
        },
        floatController: float,
      );

      expect(find.byKey(const ValueKey('open-till-key-1')), findsNothing);
      expect(find.byKey(const ValueKey('open-till-key-2')), findsNothing);
      expect(
        find.byKey(const ValueKey('open-till-key-backspace')),
        findsOneWidget,
      );
    });

    testWidgets('physical keyboard respects per-key authorize path',
        (tester) async {
      final float = TextEditingController(text: '0.00');
      addTearDown(float.dispose);
      await pumpForm(
        tester,
        permissions: {
          PosPermissionCodes.tillSessionOpen,
          PosPermissionCodes.tillOpeningStartingCashEntry,
          PosPermissionCodes.tillOpeningStartingCashView,
          PosPermissionCodes.tillOpeningNumpad,
          PosPermissionCodes.tillOpeningKey1,
          PosPermissionCodes.tillOpeningKey3,
          PosPermissionCodes.tillOpeningBackspace,
        },
        floatController: float,
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
      await tester.pump();
      expect(float.text, '1.00');

      await tester.sendKeyEvent(LogicalKeyboardKey.digit2);
      await tester.pump();
      expect(float.text, '1.00', reason: 'digit 2 denied');

      await tester.sendKeyEvent(LogicalKeyboardKey.digit3);
      await tester.pump();
      expect(float.text, '13.00');

      await tester.sendKeyEvent(LogicalKeyboardKey.period);
      await tester.pump();
      expect(float.text, '13.00', reason: 'decimal denied');

      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pump();
      expect(float.text, '1.00');
    });

    testWidgets('opening cash TextField is read-only (no direct typing bypass)',
        (tester) async {
      final float = TextEditingController(text: '0.00');
      addTearDown(float.dispose);
      await pumpForm(
        tester,
        permissions: _fullOpenTillKeys,
        floatController: float,
      );

      final field = tester.widget<TextField>(
        find.descendant(
          of: find.byKey(const Key('opening-cash-field')),
          matching: find.byType(TextField),
        ),
      );
      expect(field.readOnly, isTrue);
    });

    testWidgets('Phone/Tablet/Desktop surface parity for partial keys',
        (tester) async {
      for (final size in const [
        Size(390, 844),
        Size(834, 1112),
        Size(1280, 800),
      ]) {
        final float = TextEditingController(text: '0.00');
        await pumpForm(
          tester,
          permissions: {
            PosPermissionCodes.tillSessionOpen,
            PosPermissionCodes.tillOpeningStartingCashEntry,
            PosPermissionCodes.tillOpeningStartingCashView,
            PosPermissionCodes.tillOpeningNumpad,
            PosPermissionCodes.tillOpeningKey5,
          },
          floatController: float,
          surface: size,
        );
        expect(
          find.byKey(const ValueKey('open-till-key-5')),
          findsOneWidget,
          reason: 'size $size',
        );
        expect(find.byKey(const ValueKey('open-till-key-4')), findsNothing);
        float.dispose();
      }
    });
  });
}
