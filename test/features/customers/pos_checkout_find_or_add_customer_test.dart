import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/customers/presentation/providers/checkout_customer_provider.dart';
import 'package:nytroz_pos/features/customers/presentation/widgets/checkout_customer/checkout_customer_content.dart';
import 'package:nytroz_pos/features/sale/domain/entities/pos_customer.dart';

void main() {
  test('phone normalization matches backend punctuation contract', () {
    expect(normalizeCheckoutPhone(' +94 (77) 123-4567 '), '+94771234567');
  });

  test('empty and incomplete phone remain invalid', () {
    expect(const CheckoutCustomerState().isPhoneValid, isFalse);
    expect(
        const CheckoutCustomerState(dialCode: '+1', localPhone: '23')
            .isPhoneValid,
        isFalse);
  });

  testWidgets('phone entry renders full mobile-only keypad', (tester) async {
    await _pump(tester, const CheckoutCustomerState());
    expect(find.text('FIND OR ADD CUSTOMER'), findsOneWidget);
    expect(find.byKey(const ValueKey('checkout-customer-numeric-keypad')),
        findsOneWidget);
    expect(find.text('CLEAR'), findsOneWidget);
    expect(find.text('ADD NEW CUSTOMER'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('searching preserves phone and renders loading', (tester) async {
    await _pump(
        tester,
        const CheckoutCustomerState(
            stage: CheckoutCustomerStage.searching,
            dialCode: '+94',
            localPhone: '771234567'));
    expect(find.text('771234567'), findsOneWidget);
    expect(find.text('Looking for customer...'), findsOneWidget);
  });

  testWidgets('found customer requires explicit confirmation', (tester) async {
    await _pump(
        tester,
        const CheckoutCustomerState(
            stage: CheckoutCustomerStage.customerFound,
            dialCode: '+94',
            localPhone: '771234567',
            foundCustomer: PosCustomer(
                customerId: 'customer-id',
                fullName: 'Real Customer',
                phone: '+94771234567',
                status: 'ACTIVE',
                totalOrderCount: 2)));
    expect(find.text('Real Customer'), findsOneWidget);
    expect(find.textContaining('Previous orders: 2'), findsOneWidget);
    expect(find.byKey(const ValueKey('checkout-customer-confirm-found')),
        findsOneWidget);
  });

  testWidgets('not found exposes permission-gated create action',
      (tester) async {
    await _pump(
        tester,
        const CheckoutCustomerState(
            stage: CheckoutCustomerStage.customerNotFound),
        canCreate: false);
    expect(find.text('No customer found'), findsOneWidget);
    final button = tester.widget<FilledButton>(
        find.byKey(const ValueKey('checkout-customer-add-new')));
    expect(button.onPressed, isNull);
  });

  testWidgets('create state keeps phone read-only and name controls create',
      (tester) async {
    await _pump(
        tester,
        const CheckoutCustomerState(
            stage: CheckoutCustomerStage.addCustomer,
            dialCode: '+94',
            localPhone: '771234567'));
    expect(
        tester
            .widget<EditableText>(find.descendant(
              of: find.byKey(const ValueKey('checkout-customer-phone')),
              matching: find.byType(EditableText),
            ))
            .readOnly,
        isTrue);
    expect(
        tester
            .widget<FilledButton>(
                find.byKey(const ValueKey('checkout-customer-create')))
            .onPressed,
        isNull);
    expect(find.byKey(const ValueKey('checkout-customer-name-keyboard')),
        findsOneWidget);
  });

  testWidgets('create-ready enables Add Customer and Continue', (tester) async {
    await _pump(
        tester,
        const CheckoutCustomerState(
            stage: CheckoutCustomerStage.createReady,
            dialCode: '+94',
            localPhone: '771234567',
            customerName: 'New Customer'));
    expect(
        tester
            .widget<FilledButton>(
                find.byKey(const ValueKey('checkout-customer-create')))
            .onPressed,
        isNotNull);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('checkout-customer-right-panel')),
        matching: find.byKey(const ValueKey('checkout-customer-create')),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('checkout-customer-left-panel')),
        matching: find.byKey(const ValueKey('checkout-customer-create')),
      ),
      findsNothing,
    );
  });

  testWidgets('create mode uses one-third details and two-thirds keyboard',
      (tester) async {
    await _pump(
      tester,
      const CheckoutCustomerState(
        stage: CheckoutCustomerStage.addCustomer,
        dialCode: '+94',
        localPhone: '771234567',
      ),
    );

    final leftWidth = tester
        .getSize(find.byKey(const ValueKey('checkout-customer-left-panel')))
        .width;
    final rightWidth = tester
        .getSize(find.byKey(const ValueKey('checkout-customer-right-panel')))
        .width;

    expect(rightWidth / leftWidth, closeTo(2, 0.05));
    expect(tester.takeException(), isNull);
  });

  testWidgets('phone mode uses one-third details and two-thirds dial keypad',
      (tester) async {
    await _pump(tester, const CheckoutCustomerState());

    final leftWidth = tester
        .getSize(find.byKey(const ValueKey('checkout-customer-left-panel')))
        .width;
    final rightWidth = tester
        .getSize(find.byKey(const ValueKey('checkout-customer-right-panel')))
        .width;

    expect(rightWidth / leftWidth, closeTo(2, 0.05));
    expect(tester.takeException(), isNull);
  });

  testWidgets('dial keypad content is centered inside its two-thirds card',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: CheckoutCustomerContent(
          state: const CheckoutCustomerState(),
          canCreate: true,
          canAttach: true,
          onDigit: (_) {},
          onBackspace: () {},
          onClear: () {},
          onDialCodeChanged: (_) {},
          onRetrySearch: () {},
          onConfirmFound: () {},
          onBeginCreate: () {},
          onNameChanged: (_) {},
          onChangeNumber: () {},
          onCreate: () {},
        ),
      ),
    ));
    await tester.pump();

    final cardRect = tester.getRect(
      find.byKey(const ValueKey('checkout-customer-right-panel')),
    );
    final keypadRect = tester.getRect(
      find.byKey(const ValueKey('checkout-customer-numeric-keypad-content')),
    );

    expect(keypadRect.width, lessThanOrEqualTo(640));
    expect(keypadRect.center.dx, closeTo(cardRect.center.dx, 0.5));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'target layout renders header, search panel, bottom info card, and structured keypad',
      (tester) async {
    await _pump(
      tester,
      const CheckoutCustomerState(dialCode: '+94', localPhone: '07122'),
    );

    // Header checks
    expect(find.text('FIND OR ADD CUSTOMER'), findsOneWidget);
    expect(
      find.text(
          'Search by mobile number and attach the customer to this sale.'),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('checkout-customer-back')),
      findsOneWidget,
    );
    expect(find.text('Back to Cart'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('checkout-customer-skip')),
      findsOneWidget,
    );
    expect(find.text('SKIP'), findsOneWidget);

    // Left Panel checks
    expect(find.text('Search by Mobile Number'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('checkout-customer-dial-code')),
      findsOneWidget,
    );
    expect(find.text('+94'), findsWidgets);
    expect(find.text('07122'), findsOneWidget);
    expect(
      find.text(
          'Search starts automatically when a valid mobile number is entered.'),
      findsOneWidget,
    );
    expect(
      find.text('Only mobile number is required to find a customer.'),
      findsOneWidget,
    );

    // Right Panel checks
    expect(find.text('Enter Mobile Number'), findsOneWidget);
    expect(
      find.text('Use the keypad to enter mobile number'),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('checkout-customer-numeric-keypad')),
      findsOneWidget,
    );
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('ABC'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('DEF'), findsOneWidget);
    expect(find.text('CLEAR'), findsOneWidget);
    expect(find.byIcon(Icons.backspace_outlined), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
  });

  testWidgets('keypad interactions invoke onDigit, onBackspace, and onClear',
      (tester) async {
    final digits = <String>[];
    var backspaceCalled = false;
    var clearCalled = false;

    await tester.binding.setSurfaceSize(const Size(1000, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: CheckoutCustomerContent(
          state: const CheckoutCustomerState(dialCode: '+94'),
          canCreate: true,
          canAttach: true,
          onDigit: digits.add,
          onBackspace: () => backspaceCalled = true,
          onClear: () => clearCalled = true,
          onDialCodeChanged: (_) {},
          onRetrySearch: () {},
          onConfirmFound: () {},
          onBeginCreate: () {},
          onNameChanged: (_) {},
          onChangeNumber: () {},
          onCreate: () {},
        ),
      ),
    ));
    await tester.pump();

    await tester.tap(find.text('1'));
    await tester.tap(find.text('2'));
    await tester.tap(find.text('3'));
    await tester.pump();

    expect(digits, ['1', '2', '3']);

    await tester.tap(find.byIcon(Icons.backspace_outlined));
    await tester.pump();
    expect(backspaceCalled, isTrue);

    await tester.tap(find.text('CLEAR'));
    await tester.pump();
    expect(clearCalled, isTrue);
  });

  testWidgets('tablet-height keypad fits without RenderFlex overflow',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 560));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: CheckoutCustomerContent(
          state: const CheckoutCustomerState(),
          canCreate: true,
          canAttach: true,
          onDigit: (_) {},
          onBackspace: () {},
          onClear: () {},
          onDialCodeChanged: (_) {},
          onRetrySearch: () {},
          onConfirmFound: () {},
          onBeginCreate: () {},
          onNameChanged: (_) {},
          onChangeNumber: () {},
          onCreate: () {},
        ),
      ),
    ));
    await tester.pump();

    expect(find.text('CLEAR'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pump(WidgetTester tester, CheckoutCustomerState state,
    {bool canCreate = true, bool canAttach = true}) async {
  await tester.binding.setSurfaceSize(const Size(900, 800));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(MaterialApp(
      home: Scaffold(
          body: CheckoutCustomerContent(
    state: state,
    canCreate: canCreate,
    canAttach: canAttach,
    onDigit: (_) {},
    onBackspace: () {},
    onClear: () {},
    onDialCodeChanged: (_) {},
    onRetrySearch: () {},
    onConfirmFound: () {},
    onBeginCreate: () {},
    onNameChanged: (_) {},
    onChangeNumber: () {},
    onCreate: () {},
  ))));
  await tester.pump();
}
