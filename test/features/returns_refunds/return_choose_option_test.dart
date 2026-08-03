import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/core/access/pos_access_codes.dart';
import 'package:nytroz_pos/core/access/pos_permission_access.dart';
import 'package:nytroz_pos/features/returns_refunds/domain/entities/return_flow_steps.dart';
import 'package:nytroz_pos/features/returns_refunds/domain/entities/return_resolution_type.dart';
import 'package:nytroz_pos/features/returns_refunds/presentation/navigation/returns_route_guard.dart';
import 'package:nytroz_pos/features/returns_refunds/presentation/providers/return_flow_provider.dart';
import 'package:nytroz_pos/features/returns_refunds/presentation/widgets/choose_option/return_resolution_options.dart';
import 'package:nytroz_pos/features/returns_refunds/presentation/widgets/return_stepper.dart';
import 'package:nytroz_pos/features/returns_refunds/presentation/widgets/returns_exchange_action_footer.dart';

void main() {
  group('ReturnFlowState resolution', () {
    test('selectedResolution starts null', () {
      const state = ReturnFlowState();
      expect(state.selectedResolution, isNull);
    });

    test('can continue when resolution selected with required context', () {
      const state = ReturnFlowState(
        selectedResolution: ReturnResolutionType.refund,
        selectedReturnLines: [
          ReturnSelectedReturnLine(
            saleLineId: 'line-1',
            name: 'Item',
            unitPrice: 10,
            returnQty: 1,
            lineTotal: 10,
          ),
        ],
      );

      expect(state.selectedResolution, ReturnResolutionType.refund);
      expect(state.selectedReturnLines.length, 1);
    });
  });

  group('Choose option widgets', () {
    testWidgets('stepper shows step 7 active and steps 1-6 completed',
        (tester) async {
      await _pumpAtSize(
        tester,
        const ReturnStepper(currentStep: ReturnFlowSteps.chooseOption),
        const Size(1280, 800),
      );

      expect(find.text('Choose Option'), findsOneWidget);
      expect(find.text('Inspect Items'), findsOneWidget);
      expect(find.text('Refund / Exchange'), findsOneWidget);
      expect(find.byIcon(Icons.check_rounded), findsWidgets);
    });

    testWidgets('resolution options render refund and exchange cards',
        (tester) async {
      ReturnResolutionType? selected;

      await _pumpAtSize(
        tester,
        ReturnResolutionOptions(
          selectedResolution: selected,
          onResolutionSelected: (value) => selected = value,
        ),
        const Size(1280, 800),
      );

      expect(find.text('Refund'), findsOneWidget);
      expect(find.text('Exchange'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('selecting refund highlights card and enables continue',
        (tester) async {
      ReturnResolutionType? selected;

      await _pumpAtSize(
        tester,
        StatefulBuilder(
          builder: (context, setState) {
            return Column(
              children: [
                ReturnResolutionOptions(
                  selectedResolution: selected,
                  onResolutionSelected: (value) {
                    setState(() => selected = value);
                  },
                ),
                const SizedBox(height: 16),
                ReturnsExchangeActionFooter(
                  canContinue: selected != null,
                  onBack: () {},
                  onContinue: () {},
                ),
              ],
            );
          },
        ),
        const Size(1280, 800),
      );

      final continueButton = find.widgetWithText(FilledButton, 'Continue');
      expect(tester.widget<FilledButton>(continueButton).onPressed, isNull);

      await tester.tap(find.text('Refund'));
      await tester.pump();

      expect(selected, ReturnResolutionType.refund);
      expect(tester.widget<FilledButton>(continueButton).onPressed, isNotNull);
    });

    testWidgets('mobile layout stacks option cards vertically', (tester) async {
      await _pumpAtSize(
        tester,
        ReturnResolutionOptions(
          selectedResolution: ReturnResolutionType.exchange,
          onResolutionSelected: (_) {},
        ),
        const Size(390, 844),
      );

      expect(find.text('Exchange'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('refund card disabled without refunds.create', (tester) async {
      await _pumpAtSize(
        tester,
        ReturnResolutionOptions(
          selectedResolution: null,
          refundEnabled: false,
          exchangeEnabled: true,
          onResolutionSelected: (_) {},
        ),
        const Size(1280, 800),
      );

      final refundCard = find.ancestor(
        of: find.text('Refund'),
        matching: find.byType(InkWell),
      );
      expect(tester.widget<InkWell>(refundCard).onTap, isNull);
    });
  });

  group('Choose option branch context', () {
    test('refund branch requires persisted backend resolution', () {
      const withoutPersisted = ReturnFlowState(
        selectedResolution: ReturnResolutionType.refund,
      );
      const withPersisted = ReturnFlowState(
        selectedResolution: ReturnResolutionType.refund,
        resolutionPersisted: true,
      );

      expect(
          ReturnsRouteGuard.hasRefundBranchContext(withoutPersisted), isFalse);
      expect(ReturnsRouteGuard.hasRefundBranchContext(withPersisted), isTrue);
    });

    test('strict branch permissions require exact codes', () {
      expect(
        PosPermissionAccess.canSelectRefundResolution({
          PosPermissionCodes.viewReturns,
          PosPermissionCodes.createReturn,
          PosPermissionCodes.createRefund,
        }),
        isTrue,
      );
      expect(
        PosPermissionAccess.canSelectExchangeResolution({
          PosPermissionCodes.viewReturns,
          PosPermissionCodes.createReturn,
          PosPermissionCodes.createExchange,
        }),
        isTrue,
      );
    });
  });
}

Future<void> _pumpAtSize(
  WidgetTester tester,
  Widget child,
  Size size,
) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      ),
    ),
  );
}
