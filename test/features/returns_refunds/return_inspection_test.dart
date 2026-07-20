import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/returns_refunds/domain/entities/return_flow_steps.dart';
import 'package:nytroz_pos/features/returns_refunds/domain/entities/return_inspection.dart';
import 'package:nytroz_pos/features/returns_refunds/presentation/providers/return_flow_provider.dart';
import 'package:nytroz_pos/features/returns_refunds/presentation/providers/return_inspection_provider.dart';
import 'package:nytroz_pos/features/returns_refunds/presentation/widgets/inspect_items/inspection_summary_card.dart';
import 'package:nytroz_pos/features/returns_refunds/presentation/widgets/return_stepper.dart';

void main() {
  group('ReturnInspectionState', () {
    const conditions = [
      InspectionConditionOption(
        id: '1',
        code: 'OPENED_GOOD',
        displayName: 'Opened - Good',
        statusCategory: 'GOOD',
        sortOrder: 0,
        isResellable: true,
        refundImpact: 'NONE',
        requiresNotes: false,
        requiresPhoto: false,
        requiresApproval: false,
      ),
      InspectionConditionOption(
        id: '2',
        code: 'DAMAGED',
        displayName: 'Damaged',
        statusCategory: 'WARNING',
        sortOrder: 1,
        isResellable: false,
        refundImpact: 'PARTIAL',
        requiresNotes: true,
        requiresPhoto: true,
        requiresApproval: false,
      ),
    ];

    test('canContinue is false when condition not selected', () {
      const state = ReturnInspectionState(
        conditions: conditions,
        lineInspections: {
          'line-1': ReturnLineInspection(saleLineId: 'line-1'),
        },
      );

      expect(state.canContinue, isFalse);
      expect(state.pendingItemCount, 1);
      expect(state.inspectedItemCount, 0);
    });

    test('canContinue is true when simple condition complete', () {
      const state = ReturnInspectionState(
        conditions: conditions,
        lineInspections: {
          'line-1': ReturnLineInspection(
            saleLineId: 'line-1',
            conditionCode: 'OPENED_GOOD',
            conditionId: '1',
          ),
        },
      );

      expect(state.canContinue, isTrue);
      expect(state.pendingItemCount, 0);
    });

    test('canContinue is false when required notes missing', () {
      const state = ReturnInspectionState(
        conditions: conditions,
        lineInspections: {
          'line-1': ReturnLineInspection(
            saleLineId: 'line-1',
            conditionCode: 'DAMAGED',
            conditionId: '2',
            notes: '',
          ),
        },
      );

      expect(state.canContinue, isFalse);
    });

    test('condition breakdown updates dynamically', () {
      const state = ReturnInspectionState(
        conditions: conditions,
        lineInspections: {
          'line-1': ReturnLineInspection(
            saleLineId: 'line-1',
            conditionCode: 'OPENED_GOOD',
            conditionId: '1',
            notes: 'ok',
          ),
          'line-2': ReturnLineInspection(saleLineId: 'line-2'),
        },
      );

      expect(state.conditionBreakdown['OPENED_GOOD'], 1);
      expect(state.conditionBreakdown['PENDING'], 1);
      expect(state.selectedItemCount, 2);
    });

    test('backend validation summary overrides local counts', () {
      const state = ReturnInspectionState(
        conditions: conditions,
        lineInspections: {
          'line-1': ReturnLineInspection(
            saleLineId: 'line-1',
            conditionCode: 'OPENED_GOOD',
            conditionId: '1',
          ),
        },
        validationResult: InspectionValidationResult(
          canContinue: true,
          selectedItemCount: 3,
          inspectedItemCount: 2,
          pendingItemCount: 1,
          conditionBreakdown: {
            'OPENED_GOOD': 2,
            'PENDING': 1,
          },
          policyMessages: [],
          requiresReview: false,
          notesMaxLength: 200,
          maxPhotosPerLine: 5,
          maxPhotoSizeBytes: 5242880,
        ),
        inspectionsValidated: true,
      );

      expect(state.selectedItemCount, 3);
      expect(state.inspectedItemCount, 2);
      expect(state.pendingItemCount, 1);
      expect(state.conditionBreakdown['OPENED_GOOD'], 2);
      expect(state.inspectionsValidated, isTrue);
    });

    test('canContinue is false while validating', () {
      const state = ReturnInspectionState(
        conditions: conditions,
        isValidating: true,
        lineInspections: {
          'line-1': ReturnLineInspection(
            saleLineId: 'line-1',
            conditionCode: 'OPENED_GOOD',
            conditionId: '1',
          ),
        },
      );

      expect(state.canContinue, isFalse);
    });

    test('canContinue is false while saving', () {
      const state = ReturnInspectionState(
        conditions: conditions,
        isSaving: true,
        lineInspections: {
          'line-1': ReturnLineInspection(
            saleLineId: 'line-1',
            conditionCode: 'OPENED_GOOD',
            conditionId: '1',
          ),
        },
      );

      expect(state.canContinue, isFalse);
    });

    test('step6 flags derive from selected conditions', () {
      const state = ReturnInspectionState(
        conditions: conditions,
        lineInspections: {
          'line-1': ReturnLineInspection(
            saleLineId: 'line-1',
            conditionCode: 'DAMAGED',
            conditionId: '2',
            notes: 'box crushed',
            media: [
              InspectionMediaItem(
                mediaId: 'media-1',
                previewUrl: '/media/1',
              ),
            ],
          ),
        },
      );

      expect(state.step6RequiresInspection, isTrue);
      expect(state.step6RequiresManagerApproval, isFalse);
    });
  });

  group('InspectionConditionOption', () {
    test('fromJson parses API fields', () {
      final option = InspectionConditionOption.fromJson({
        'id': 'eeee0001-0001-4000-8000-000000000001',
        'code': 'OPENED_GOOD',
        'displayName': 'Opened - Good',
        'description': 'Opened but resellable.',
        'statusCategory': 'GOOD',
        'sortOrder': 0,
        'isResellable': true,
        'refundImpact': 'NONE',
        'requiresNotes': false,
        'requiresPhoto': false,
        'requiresApproval': false,
      });

      expect(option.code, 'OPENED_GOOD');
      expect(option.requiresPhoto, isFalse);
    });
  });

  group('InspectionValidationResult', () {
    test('parses draft identity and only accepts VALIDATED status', () {
      final validated = InspectionValidationResult.fromJson({
        'draftId': 'draft-1',
        'status': 'VALIDATED',
        'canContinue': true,
        'selectedItemCount': 1,
        'inspectedItemCount': 1,
        'pendingItemCount': 0,
        'conditionBreakdown': {},
        'policyMessages': [],
        'requiresReview': false,
        'notesMaxLength': 200,
        'maxPhotosPerLine': 5,
        'maxPhotoSizeBytes': 5242880,
      });
      final draft = InspectionValidationResult.fromJson({
        'draftId': 'draft-1',
        'status': 'DRAFT',
        'canContinue': true,
        'selectedItemCount': 1,
        'inspectedItemCount': 1,
        'pendingItemCount': 0,
        'conditionBreakdown': {},
        'policyMessages': [],
        'requiresReview': false,
        'notesMaxLength': 200,
        'maxPhotosPerLine': 5,
        'maxPhotoSizeBytes': 5242880,
      });

      expect(validated.draftId, 'draft-1');
      expect(validated.status, 'VALIDATED');
      expect(validated.isValidated, isTrue);
      expect(draft.isValidated, isFalse);
    });

    test('parses version, expiry, and approval flags', () {
      final result = InspectionValidationResult.fromJson({
        'draftId': 'draft-1',
        'status': 'VALIDATED',
        'canContinue': true,
        'selectedItemCount': 1,
        'inspectedItemCount': 1,
        'pendingItemCount': 0,
        'conditionBreakdown': {},
        'policyMessages': [],
        'requiresReview': true,
        'notesMaxLength': 200,
        'maxPhotosPerLine': 5,
        'maxPhotoSizeBytes': 5242880,
        'version': 3,
        'expiresAt': '2026-07-18T12:00:00.000Z',
        'requiresInspection': true,
        'requiresManagerApproval': true,
      });

      expect(result.version, 3);
      expect(result.expiresAt, isNotNull);
      expect(result.requiresInspection, isTrue);
      expect(result.requiresManagerApproval, isTrue);
      expect(result.requiresReview, isTrue);
    });
  });

  group('InspectionDraft', () {
    test('fromJson parses version and expiresAt', () {
      final draft = InspectionDraft.fromJson({
        'draftId': 'draft-1',
        'status': 'DRAFT',
        'version': 2,
        'expiresAt': '2026-07-18T12:00:00.000Z',
        'lines': [],
      });

      expect(draft.version, 2);
      expect(draft.expiresAt, isNotNull);
    });
  });

  group('ReturnFlowState flag merge', () {
    test('applyInspectionValidation OR-merges without downgrading', () {
      final controller = ReturnFlowController();
      controller.setReturnReason(
        reasonCode: 'DAMAGED',
        requiresInspection: true,
        requiresManagerApproval: false,
      );

      controller.applyInspectionValidation(
        inspections: const {
          'line-1': ReturnLineInspection(saleLineId: 'line-1'),
        },
        inspectionsValidated: true,
        step6RequiresInspection: false,
        step6RequiresManagerApproval: true,
        validationRequiresInspection: false,
        validationRequiresManagerApproval: false,
      );

      expect(controller.state.requiresInspection, isTrue);
      expect(controller.state.requiresManagerApproval, isTrue);
      expect(controller.state.inspectionsValidated, isTrue);
    });

    test('applyInspectionValidation keeps earlier true when validation false',
        () {
      final controller = ReturnFlowController();
      controller.setReturnReason(
        reasonCode: 'OTHER',
        requiresInspection: false,
        requiresManagerApproval: true,
      );

      controller.applyInspectionValidation(
        inspections: const {
          'line-1': ReturnLineInspection(saleLineId: 'line-1'),
        },
        inspectionsValidated: true,
        validationRequiresInspection: false,
        validationRequiresManagerApproval: false,
      );

      expect(controller.state.requiresManagerApproval, isTrue);
      expect(controller.state.requiresInspection, isFalse);
    });
  });

  group('resolveInspectionApiError', () {
    DioException error({
      required int? statusCode,
      String? code,
      String? message,
    }) {
      return DioException(
        requestOptions: RequestOptions(path: '/test'),
        response: Response<Map<String, dynamic>>(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: statusCode,
          data: {
            if (code != null) 'code': code,
            if (message != null) 'message': message,
          },
        ),
        type: DioExceptionType.badResponse,
      );
    }

    test('maps draft conflict and expired codes', () {
      expect(
        resolveInspectionApiError(error(
          statusCode: 409,
          code: 'pos_returns.inspection_draft_conflict',
          message: 'Draft conflict',
        )),
        'Draft conflict',
      );
      expect(
        resolveInspectionApiError(error(
          statusCode: 400,
          code: 'pos_returns.inspection_draft_expired',
        )),
        contains('expired'),
      );
      expect(
        resolveInspectionApiError(error(
          statusCode: 400,
          code: 'pos_returns.inspection_draft_consumed',
        )),
        contains('already used'),
      );
    });

    test('maps 413, 415, and 500 status codes', () {
      expect(
        resolveInspectionApiError(error(statusCode: 413)),
        contains('too large'),
      );
      expect(
        resolveInspectionApiError(error(statusCode: 415)),
        contains('not supported'),
      );
      expect(
        resolveInspectionApiError(
            error(statusCode: 500, message: 'Server down')),
        'Server down',
      );
    });

    test('maps not-found style codes', () {
      expect(
        resolveInspectionApiError(error(
          statusCode: 404,
          code: 'pos_returns.inspection_draft_not_found',
        )),
        contains('could not be found'),
      );
    });
  });

  group('Inspect items widgets', () {
    testWidgets('stepper shows step 6 active and steps 1-5 completed',
        (tester) async {
      await _pumpAtSize(
        tester,
        const ReturnStepper(currentStep: ReturnFlowSteps.inspectItems),
        const Size(1280, 800),
      );

      expect(find.text('Inspect Items'), findsOneWidget);
      expect(find.text('Return Reason'), findsOneWidget);
      expect(find.text('Choose Option'), findsOneWidget);
      expect(find.byIcon(Icons.check_rounded), findsWidgets);
    });

    testWidgets('summary card renders dynamic counts', (tester) async {
      const state = ReturnInspectionState(
        conditions: [
          InspectionConditionOption(
            id: '1',
            code: 'OPENED_GOOD',
            displayName: 'Opened - Good',
            statusCategory: 'GOOD',
            sortOrder: 0,
            isResellable: true,
            refundImpact: 'NONE',
            requiresNotes: false,
            requiresPhoto: false,
            requiresApproval: false,
          ),
        ],
        lineInspections: {
          'line-1': ReturnLineInspection(
            saleLineId: 'line-1',
            conditionCode: 'OPENED_GOOD',
            conditionId: '1',
          ),
          'line-2': ReturnLineInspection(saleLineId: 'line-2'),
        },
      );

      await _pumpAtSize(
        tester,
        const InspectionSummaryCard(state: state),
        const Size(400, 300),
      );

      expect(find.text('Inspection Summary'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('1'), findsNWidgets(2));
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
