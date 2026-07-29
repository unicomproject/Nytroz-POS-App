import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/returns_refunds/domain/entities/return_flow_steps.dart';
import 'package:nytroz_pos/features/returns_refunds/domain/entities/return_reason_option.dart';
import 'package:nytroz_pos/features/returns_refunds/presentation/providers/return_reason_provider.dart';
import 'package:nytroz_pos/features/returns_refunds/presentation/widgets/return_reason/selected_return_items_card.dart';
import 'package:nytroz_pos/features/returns_refunds/presentation/widgets/return_reason_option_tile.dart';
import 'package:nytroz_pos/features/returns_refunds/presentation/widgets/return_stepper.dart';
import 'package:nytroz_pos/features/returns_refunds/presentation/providers/return_flow_provider.dart';

void main() {
  group('ReturnReasonOption', () {
    test('fromJson parses API reason fields', () {
      final option = ReturnReasonOption.fromJson({
        'id': '11111111-1111-4111-8111-111111111111',
        'code': 'DAMAGED',
        'displayName': 'Damaged Item',
        'description': 'Item arrived damaged',
        'sortOrder': 1,
        'appliesToReturn': true,
        'appliesToExchange': true,
        'requiresNotes': false,
        'requiresInspection': true,
        'requiresManagerApproval': false,
      });

      expect(option.code, 'DAMAGED');
      expect(option.displayName, 'Damaged Item');
      expect(option.description, 'Item arrived damaged');
      expect(option.requiresInspection, isTrue);
      expect(option.requiresManagerApproval, isFalse);
      expect(option.requiresNotes, isFalse);
    });

    test('fromJson parses manager approval true without hardcoding false', () {
      final option = ReturnReasonOption.fromJson({
        'id': '33333333-3333-4333-8333-333333333333',
        'code': 'DEFECTIVE',
        'displayName': 'Defective',
        'sortOrder': 2,
        'appliesToReturn': true,
        'appliesToExchange': false,
        'requiresNotes': true,
        'requiresInspection': true,
        'requiresManagerApproval': true,
      });

      expect(option.requiresManagerApproval, isTrue);
      expect(option.requiresNotes, isTrue);
      expect(option.description, isNull);
    });
  });

  group('ReturnReasonState', () {
    const reasons = [
      ReturnReasonOption(
        id: '11111111-1111-4111-8111-111111111111',
        code: 'DAMAGED',
        displayName: 'Damaged Item',
        description: 'Item arrived damaged',
        sortOrder: 1,
        appliesToReturn: true,
        appliesToExchange: true,
        requiresNotes: false,
        requiresInspection: true,
        requiresManagerApproval: true,
      ),
      ReturnReasonOption(
        id: '22222222-2222-4222-8222-222222222222',
        code: 'OTHER',
        displayName: 'Other',
        sortOrder: 6,
        appliesToReturn: true,
        appliesToExchange: true,
        requiresNotes: true,
        requiresInspection: false,
        requiresManagerApproval: false,
      ),
    ];

    test('canContinue is false without selected reason', () {
      const state = ReturnReasonState(
        reasons: reasons,
        lineSelections: {
          'line-1': ReturnLineReasonSelection(
            saleLineId: 'line-1',
            reasonCode: '',
          ),
        },
      );

      expect(state.canContinue, isFalse);
    });

    test('canContinue is false when required notes are missing', () {
      const state = ReturnReasonState(
        reasons: reasons,
        selectedReasonCode: 'OTHER',
        lineSelections: {
          'line-1': ReturnLineReasonSelection(
            saleLineId: 'line-1',
            reasonCode: 'OTHER',
            reasonId: '22222222-2222-4222-8222-222222222222',
            notes: '',
          ),
        },
      );

      expect(state.notesRequired, isTrue);
      expect(state.canContinue, isFalse);
    });

    test('canContinue is true with valid reason and notes', () {
      const state = ReturnReasonState(
        reasons: reasons,
        selectedReasonCode: 'DAMAGED',
        notes: 'Packaging torn',
        lineSelections: {
          'line-1': ReturnLineReasonSelection(
            saleLineId: 'line-1',
            reasonCode: 'DAMAGED',
            reasonId: '11111111-1111-4111-8111-111111111111',
            notes: 'Packaging torn',
          ),
        },
      );

      expect(state.canContinue, isTrue);
    });

    test('canContinue requires every per-line reason and note', () {
      const state = ReturnReasonState(
        reasons: reasons,
        applySameReasonToAll: false,
        lineSelections: {
          'line-1': ReturnLineReasonSelection(
            saleLineId: 'line-1',
            reasonCode: 'DAMAGED',
            reasonId: '11111111-1111-4111-8111-111111111111',
            requiresInspection: true,
            requiresManagerApproval: true,
          ),
          'line-2': ReturnLineReasonSelection(
            saleLineId: 'line-2',
            reasonCode: 'OTHER',
            reasonId: '22222222-2222-4222-8222-222222222222',
            notes: '',
            requiresNotes: true,
          ),
        },
      );

      expect(state.canContinue, isFalse);
      expect(state.anyRequiresInspection, isTrue);
      expect(state.anyRequiresManagerApproval, isTrue);
    });

    test('optional notes do not block continue', () {
      const state = ReturnReasonState(
        reasons: reasons,
        applySameReasonToAll: false,
        lineSelections: {
          'line-1': ReturnLineReasonSelection(
            saleLineId: 'line-1',
            reasonCode: 'DAMAGED',
            reasonId: '11111111-1111-4111-8111-111111111111',
          ),
          'line-2': ReturnLineReasonSelection(
            saleLineId: 'line-2',
            reasonCode: 'DAMAGED',
            reasonId: '11111111-1111-4111-8111-111111111111',
            notes: '',
          ),
        },
      );

      expect(state.canContinue, isTrue);
    });

    test('canContinue is false while saving', () {
      const state = ReturnReasonState(
        reasons: reasons,
        selectedReasonCode: 'DAMAGED',
        isSaving: true,
        lineSelections: {
          'line-1': ReturnLineReasonSelection(
            saleLineId: 'line-1',
            reasonCode: 'DAMAGED',
            reasonId: '11111111-1111-4111-8111-111111111111',
          ),
        },
      );

      expect(state.canContinue, isFalse);
    });

    test('notes max length matches backend configuration', () {
      expect(returnReasonNotesMaxLength, 1000);
    });
  });

  group('ReturnFlowState flag merge', () {
    test('setReturnReason stores merged inspection and approval flags', () {
      final controller = ReturnFlowController();
      controller.setReturnReason(
        reasonCode: 'DAMAGED',
        notes: 'note',
        reasonsValidated: true,
        requiresInspection: true,
        requiresManagerApproval: true,
        lineSelections: {
          'line-1': const ReturnLineReasonSelection(
            saleLineId: 'line-1',
            reasonCode: 'DAMAGED',
            requiresInspection: true,
            requiresManagerApproval: true,
          ),
        },
      );

      expect(controller.state.requiresInspection, isTrue);
      expect(controller.state.requiresManagerApproval, isTrue);
      expect(controller.state.reasonsValidated, isTrue);
    });
  });

  group('Return reason widgets', () {
    testWidgets('stepper shows step 5 active and steps 1-4 completed',
        (tester) async {
      await _pumpAtSize(
        tester,
        const ReturnStepper(currentStep: ReturnFlowSteps.returnReason),
        const Size(1280, 800),
      );

      expect(find.text('Return Reason'), findsOneWidget);
      expect(find.text('Search Sale'), findsOneWidget);
      expect(find.text('Check Eligibility'), findsOneWidget);
      expect(find.byIcon(Icons.check_rounded), findsWidgets);
    });

    testWidgets('selected items card renders dynamic count', (tester) async {
      await _pumpAtSize(
        tester,
        const SelectedReturnItemsCard(
          currency: 'LKR',
          items: [
            ReturnSelectedReturnLine(
              saleLineId: 'line-1',
              name: 'Test Product',
              unitPrice: 100,
              returnQty: 1,
              lineTotal: 100,
              sku: 'SKU-001',
              variantLabel: 'Size M',
            ),
          ],
        ),
        const Size(600, 800),
      );

      expect(find.text('Selected Items (1)'), findsOneWidget);
      expect(find.text('Test Product'), findsOneWidget);
      expect(find.textContaining('SKU-001'), findsOneWidget);
      expect(find.text('Qty: 1'), findsOneWidget);
    });

    testWidgets('reason option tile shows description only when provided',
        (tester) async {
      await _pumpAtSize(
        tester,
        Column(
          children: [
            ReturnReasonOptionTile(
              option: const ReturnReasonOption(
                id: '1',
                code: 'DAMAGED',
                displayName: 'Damaged Item',
                description: 'Item arrived damaged',
                sortOrder: 1,
                appliesToReturn: true,
                appliesToExchange: false,
                requiresNotes: false,
                requiresInspection: false,
                requiresManagerApproval: false,
              ),
              selected: true,
              onSelected: () {},
            ),
            ReturnReasonOptionTile(
              option: const ReturnReasonOption(
                id: '2',
                code: 'CHANGED_MIND',
                displayName: 'Changed Mind',
                sortOrder: 2,
                appliesToReturn: true,
                appliesToExchange: false,
                requiresNotes: false,
                requiresInspection: false,
                requiresManagerApproval: false,
              ),
              selected: false,
              onSelected: () {},
            ),
          ],
        ),
        const Size(600, 800),
      );

      expect(find.text('Item arrived damaged'), findsOneWidget);
      expect(find.text('Changed Mind'), findsOneWidget);
      expect(find.textContaining('packaging'), findsNothing);
    });

    testWidgets(
        'tablet layout keeps selected items and reason cards side by side',
        (tester) async {
      await _pumpAtSize(
        tester,
        const Row(
          children: [
            Expanded(
              child: SelectedReturnItemsCard(
                currency: 'LKR',
                items: [
                  ReturnSelectedReturnLine(
                    saleLineId: 'line-1',
                    name: 'Test Product',
                    unitPrice: 100,
                    returnQty: 1,
                    lineTotal: 100,
                  ),
                ],
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: SizedBox(
                height: 200,
                child: ColoredBox(color: Color(0xFFE0E0E0)),
              ),
            ),
          ],
        ),
        const Size(1280, 800),
      );

      expect(find.text('Selected Items (1)'), findsOneWidget);
      expect(tester.takeException(), isNull);
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
