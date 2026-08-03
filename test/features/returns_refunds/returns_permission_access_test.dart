import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/core/access/pos_access_codes.dart';
import 'package:nytroz_pos/core/access/pos_permission_access.dart';
import 'package:nytroz_pos/features/auth/domain/entities/auth_session.dart';
import 'package:nytroz_pos/features/returns_refunds/domain/entities/return_inspection.dart';
import 'package:nytroz_pos/features/returns_refunds/domain/entities/return_reason_option.dart';
import 'package:nytroz_pos/features/returns_refunds/domain/entities/return_sale_eligibility.dart';
import 'package:nytroz_pos/features/returns_refunds/domain/entities/return_sale_summary.dart';
import 'package:nytroz_pos/features/returns_refunds/presentation/navigation/returns_route_guard.dart';
import 'package:nytroz_pos/features/returns_refunds/presentation/providers/return_eligibility_provider.dart';
import 'package:nytroz_pos/features/returns_refunds/presentation/providers/return_flow_provider.dart';

AuthSession _session(List<String> codes) {
  return AuthSession(
    accessToken: 'token',
    refreshToken: 'refresh',
    expiresAt: DateTime.now().add(const Duration(hours: 1)),
    userId: 'user',
    userDisplayName: 'Cashier',
    permissionCodes: codes,
  );
}

ReturnSaleSummary _sale() {
  return const ReturnSaleSummary(
    saleId: 'sale-1',
    invoiceNo: 'INV-1',
    customerName: 'Customer',
    phone: '',
    paymentMethod: 'Cash',
    maskedCard: '',
    total: 100,
    itemCount: 1,
    currency: 'LKR',
  );
}

ReturnFlowState _flowWithSelection() {
  return ReturnFlowState(
    selectedSale: _sale(),
    selectedReturnLines: const [
      ReturnSelectedReturnLine(
        saleLineId: 'line-1',
        returnQty: 1,
        name: 'Item',
        sku: 'SKU',
        unitPrice: 10,
        lineTotal: 10,
      ),
    ],
  );
}

ReturnSaleEligibility _eligibleResult({bool canContinue = true}) {
  return ReturnSaleEligibility(
    saleId: 'sale-1',
    invoiceNo: 'INV-1',
    customerName: 'Customer',
    paymentMethod: 'Cash',
    maskedCard: '',
    currency: 'LKR',
    items: const [
      ReturnSaleLineEligibility(
        saleLineId: 'line-1',
        variantId: 'v1',
        name: 'Item',
        sku: 'SKU',
        soldQty: 1,
        returnedQty: 0,
        availableReturnQty: 1,
        unitPrice: 10,
        lineTotal: 10,
        isReturnable: true,
        eligibilityStatus: 'ELIGIBLE',
      ),
    ],
    policyChecks: const [],
    canContinue: canContinue,
    eligibleItemCount: canContinue ? 1 : 0,
  );
}

void main() {
  group('Returns permission access', () {
    test('module entry accepts any view code', () {
      expect(
        PosPermissionAccess.canViewReturnsOrRefunds(
          {PosPermissionCodes.viewReturns},
        ),
        isTrue,
      );
      expect(
        PosPermissionAccess.canViewReturnsOrRefunds(
          {PosPermissionCodes.viewRefunds},
        ),
        isTrue,
      );
      expect(
        PosPermissionAccess.canViewReturnsOrRefunds(
          {PosPermissionCodes.viewExchanges},
        ),
        isTrue,
      );
      expect(
        PosPermissionAccess.canViewReturnsOrRefunds(
          {PosPermissionCodes.createRefund},
        ),
        isFalse,
      );
    });

    test('create refund and exchange are independent', () {
      expect(
        PosPermissionAccess.canCreateRefund({PosPermissionCodes.createRefund}),
        isTrue,
      );
      expect(
        PosPermissionAccess.canCreateExchange(
          {PosPermissionCodes.createExchange},
        ),
        isTrue,
      );
      expect(
        PosPermissionAccess.canCreateRefund(
          {PosPermissionCodes.createExchange},
        ),
        isFalse,
      );
      expect(
        PosPermissionAccess.canCreateExchange(
          {PosPermissionCodes.createRefund},
        ),
        isFalse,
      );
      expect(
        PosPermissionAccess.canCreateRefund({PosPermissionCodes.createReturn}),
        isTrue,
      );
    });

    test('strict resolution branch permissions require exact branch codes', () {
      expect(
        PosPermissionAccess.canSelectRefundResolution({
          PosPermissionCodes.viewReturns,
          PosPermissionCodes.createReturn,
          PosPermissionCodes.createRefund,
        }),
        isTrue,
      );
      expect(
        PosPermissionAccess.canSelectRefundResolution({
          PosPermissionCodes.viewReturns,
          PosPermissionCodes.createReturn,
        }),
        isFalse,
      );
      expect(
        PosPermissionAccess.canSelectExchangeResolution({
          PosPermissionCodes.viewReturns,
          PosPermissionCodes.createReturn,
          PosPermissionCodes.createExchange,
        }),
        isTrue,
      );
      expect(
        PosPermissionAccess.canSelectExchangeResolution({
          PosPermissionCodes.viewReturns,
          PosPermissionCodes.createReturn,
        }),
        isFalse,
      );
    });

    test('approve refund is separate from create', () {
      expect(
        PosPermissionAccess.canApproveRefund(
          {PosPermissionCodes.approveRefund},
        ),
        isTrue,
      );
      expect(
        PosPermissionAccess.canApproveRefund(
          {PosPermissionCodes.createRefund},
        ),
        isFalse,
      );
    });

    test('grantsCanonicalPermission maps each code distinctly', () {
      expect(
        PosPermissionAccess.grantsCanonicalPermission(
          {PosPermissionCodes.createRefund},
          PosPermissionCodes.createRefund,
        ),
        isTrue,
      );
      expect(
        PosPermissionAccess.grantsCanonicalPermission(
          {PosPermissionCodes.viewReturns},
          PosPermissionCodes.createRefund,
        ),
        isFalse,
      );
      expect(
        PosPermissionAccess.grantsCanonicalPermission(
          {PosPermissionCodes.approveRefund},
          PosPermissionCodes.approveRefund,
        ),
        isTrue,
      );
    });
  });

  group('ReturnsRouteGuard', () {
    test('search requires module view permission', () {
      expect(
        ReturnsRouteGuard.canAccessPath(
          _session(
              [PosPermissionCodes.viewHome, PosPermissionCodes.viewReturns]),
          '/pos/returns-refunds',
        ),
        isTrue,
      );
      expect(
        ReturnsRouteGuard.canAccessPath(
          _session([PosPermissionCodes.viewHome]),
          '/pos/returns-refunds',
        ),
        isFalse,
      );
    });

    test('Step 4 check-eligibility requires strict returns.view', () {
      expect(
        ReturnsRouteGuard.canAccessPath(
          _session([
            PosPermissionCodes.viewHome,
            PosPermissionCodes.viewReturns,
          ]),
          '/pos/returns-refunds/check-eligibility',
        ),
        isTrue,
      );
      expect(
        ReturnsRouteGuard.canAccessPath(
          _session([
            PosPermissionCodes.viewHome,
            PosPermissionCodes.viewRefunds,
          ]),
          '/pos/returns-refunds/check-eligibility',
        ),
        isFalse,
      );
      expect(
        ReturnsRouteGuard.canAccessPath(
          _session([
            PosPermissionCodes.viewHome,
            PosPermissionCodes.viewExchanges,
          ]),
          '/pos/returns-refunds/check-eligibility',
        ),
        isFalse,
      );
      expect(
        ReturnsRouteGuard.canAccessPath(
          _session([PosPermissionCodes.viewHome]),
          '/pos/returns-refunds/check-eligibility',
        ),
        isFalse,
      );
    });

    test('return-reason requires returns.view and returns.create', () {
      expect(
        ReturnsRouteGuard.canAccessPath(
          _session([
            PosPermissionCodes.viewHome,
            PosPermissionCodes.viewReturns,
            PosPermissionCodes.createReturn,
          ]),
          '/pos/returns-refunds/return-reason',
        ),
        isTrue,
      );
      expect(
        ReturnsRouteGuard.canAccessPath(
          _session([
            PosPermissionCodes.viewHome,
            PosPermissionCodes.viewReturns,
          ]),
          '/pos/returns-refunds/return-reason',
        ),
        isFalse,
      );
      expect(
        ReturnsRouteGuard.canAccessPath(
          _session([
            PosPermissionCodes.viewHome,
            PosPermissionCodes.viewRefunds,
            PosPermissionCodes.createReturn,
          ]),
          '/pos/returns-refunds/return-reason',
        ),
        isFalse,
      );
    });

    test('inspect-items requires returns.view and returns.create', () {
      expect(
        ReturnsRouteGuard.canAccessPath(
          _session([
            PosPermissionCodes.viewHome,
            PosPermissionCodes.viewReturns,
            PosPermissionCodes.createReturn,
          ]),
          '/pos/returns-refunds/inspect-items',
        ),
        isTrue,
      );
      expect(
        ReturnsRouteGuard.canAccessPath(
          _session([
            PosPermissionCodes.viewHome,
            PosPermissionCodes.viewReturns,
          ]),
          '/pos/returns-refunds/inspect-items',
        ),
        isFalse,
      );
      expect(
        ReturnsRouteGuard.canAccessPath(
          _session([
            PosPermissionCodes.viewHome,
            PosPermissionCodes.viewExchanges,
          ]),
          '/pos/returns-refunds/inspect-items',
        ),
        isFalse,
      );
    });

    test('choose-option requires returns.view and returns.create', () {
      expect(
        ReturnsRouteGuard.canAccessPath(
          _session([
            PosPermissionCodes.viewHome,
            PosPermissionCodes.viewReturns,
            PosPermissionCodes.createReturn,
          ]),
          '/pos/returns-refunds/choose-option',
        ),
        isTrue,
      );
      expect(
        ReturnsRouteGuard.canAccessPath(
          _session([
            PosPermissionCodes.viewHome,
            PosPermissionCodes.viewReturns,
          ]),
          '/pos/returns-refunds/choose-option',
        ),
        isFalse,
      );
      expect(
        ReturnsRouteGuard.canAccessPath(
          _session([
            PosPermissionCodes.viewHome,
            PosPermissionCodes.viewRefunds,
          ]),
          '/pos/returns-refunds/choose-option',
        ),
        isFalse,
      );
    });

    test('refund details requires returns view/create and refunds.create', () {
      expect(
        ReturnsRouteGuard.canAccessPath(
          _session([
            PosPermissionCodes.viewHome,
            PosPermissionCodes.viewReturns,
            PosPermissionCodes.createReturn,
            PosPermissionCodes.createRefund,
          ]),
          '/pos/returns-refunds/refund-details',
        ),
        isTrue,
      );
      expect(
        ReturnsRouteGuard.canAccessPath(
          _session([
            PosPermissionCodes.viewHome,
            PosPermissionCodes.viewReturns,
            PosPermissionCodes.createReturn,
          ]),
          '/pos/returns-refunds/refund-details',
        ),
        isFalse,
      );
      expect(
        ReturnsRouteGuard.canAccessPath(
          _session([
            PosPermissionCodes.viewHome,
            PosPermissionCodes.viewRefunds,
            PosPermissionCodes.createRefund,
          ]),
          '/pos/returns-refunds/refund-details',
        ),
        isFalse,
      );
    });

    test('exchange requires returns view/create and exchanges.create', () {
      expect(
        ReturnsRouteGuard.canAccessPath(
          _session([
            PosPermissionCodes.viewHome,
            PosPermissionCodes.viewReturns,
            PosPermissionCodes.createReturn,
            PosPermissionCodes.createExchange,
          ]),
          '/pos/returns-refunds/exchange',
        ),
        isTrue,
      );
      expect(
        ReturnsRouteGuard.canAccessPath(
          _session([
            PosPermissionCodes.viewHome,
            PosPermissionCodes.viewReturns,
            PosPermissionCodes.createReturn,
            PosPermissionCodes.createRefund,
          ]),
          '/pos/returns-refunds/exchange',
        ),
        isFalse,
      );
      expect(
        ReturnsRouteGuard.canAccessPath(
          _session([
            PosPermissionCodes.viewHome,
            PosPermissionCodes.viewExchanges,
            PosPermissionCodes.createExchange,
          ]),
          '/pos/returns-refunds/exchange',
        ),
        isFalse,
      );
    });
  });

  group('Step 4 continue gating', () {
    test('Continue disabled without returns.create', () {
      final eligibility = ReturnEligibilityState(
        checkResult: _eligibleResult(),
      );
      expect(
        ReturnsRouteGuard.canContinueFromEligibilityCheck(
          granted: {PosPermissionCodes.viewReturns},
          flow: _flowWithSelection(),
          eligibility: eligibility,
        ),
        isFalse,
      );
    });

    test('Continue disabled when API canContinue is false', () {
      final eligibility = ReturnEligibilityState(
        checkResult: _eligibleResult(canContinue: false),
      );
      expect(
        ReturnsRouteGuard.canContinueFromEligibilityCheck(
          granted: {
            PosPermissionCodes.viewReturns,
            PosPermissionCodes.createReturn,
          },
          flow: _flowWithSelection(),
          eligibility: eligibility,
        ),
        isFalse,
      );
    });

    test('Continue enabled with create and valid eligible result', () {
      final eligibility = ReturnEligibilityState(
        checkResult: _eligibleResult(),
      );
      expect(
        ReturnsRouteGuard.canContinueFromEligibilityCheck(
          granted: {
            PosPermissionCodes.viewReturns,
            PosPermissionCodes.createReturn,
          },
          flow: _flowWithSelection(),
          eligibility: eligibility,
        ),
        isTrue,
      );
    });

    test('invalid deep-link context is rejected', () {
      expect(
        ReturnsRouteGuard.hasCheckEligibilityContext(const ReturnFlowState()),
        isFalse,
      );
      expect(
        ReturnsRouteGuard.hasReturnReasonContext(
          flow: _flowWithSelection(),
          eligibility: const ReturnEligibilityState(),
        ),
        isFalse,
      );
    });

    test('permission helpers use session access codes only', () {
      expect(
        PosPermissionAccess.canViewReturns({PosPermissionCodes.viewReturns}),
        isTrue,
      );
      expect(
        PosPermissionAccess.canCreateReturn({PosPermissionCodes.createReturn}),
        isTrue,
      );
      expect(
        PosPermissionAccess.canViewReturns({PosPermissionCodes.viewRefunds}),
        isFalse,
      );
    });
  });

  group('Step 5 continue and inspect gating', () {
    ReturnEligibilityState eligibilityReady() => ReturnEligibilityState(
          checkResult: _eligibleResult(),
        );

    ReturnFlowState flowWithReason() => ReturnFlowState(
          selectedSale: _sale(),
          selectedReturnLines: const [
            ReturnSelectedReturnLine(
              saleLineId: 'line-1',
              returnQty: 1,
              name: 'Item',
              sku: 'SKU',
              unitPrice: 10,
              lineTotal: 10,
            ),
          ],
          selectedReasonCode: 'DAMAGED',
          reasonsValidated: true,
          lineReasonSelections: const {
            'line-1': ReturnLineReasonSelection(
              saleLineId: 'line-1',
              reasonCode: 'DAMAGED',
              reasonId: 'reason-1',
              notes: '',
            ),
          },
        );

    test('Continue disabled without returns.create', () {
      expect(
        ReturnsRouteGuard.canContinueFromReturnReason(
          granted: {PosPermissionCodes.viewReturns},
          flow: _flowWithSelection(),
          eligibility: eligibilityReady(),
          reasonCanContinue: true,
          isSaving: false,
        ),
        isFalse,
      );
    });

    test('Continue disabled while saving', () {
      expect(
        ReturnsRouteGuard.canContinueFromReturnReason(
          granted: {
            PosPermissionCodes.viewReturns,
            PosPermissionCodes.createReturn,
          },
          flow: _flowWithSelection(),
          eligibility: eligibilityReady(),
          reasonCanContinue: true,
          isSaving: true,
        ),
        isFalse,
      );
    });

    test('Continue enabled with view+create and valid reason state', () {
      expect(
        ReturnsRouteGuard.canContinueFromReturnReason(
          granted: {
            PosPermissionCodes.viewReturns,
            PosPermissionCodes.createReturn,
          },
          flow: _flowWithSelection(),
          eligibility: eligibilityReady(),
          reasonCanContinue: true,
          isSaving: false,
        ),
        isTrue,
      );
    });

    test('Inspect Items deep-link blocked without validated reasons', () {
      expect(
        ReturnsRouteGuard.hasInspectItemsContext(
          flow: flowWithReason(),
          eligibility: eligibilityReady(),
          reasonsValidated: false,
        ),
        isFalse,
      );
    });

    test('Inspect Items context allowed after validated reasons', () {
      expect(
        ReturnsRouteGuard.hasInspectItemsContext(
          flow: flowWithReason(),
          eligibility: eligibilityReady(),
          reasonsValidated: true,
        ),
        isTrue,
      );
    });

    test('refunds.view alone does not unlock Step 5 continue', () {
      expect(
        ReturnsRouteGuard.canContinueFromReturnReason(
          granted: {
            PosPermissionCodes.viewRefunds,
            PosPermissionCodes.createReturn,
          },
          flow: _flowWithSelection(),
          eligibility: eligibilityReady(),
          reasonCanContinue: true,
          isSaving: false,
        ),
        isFalse,
      );
    });
  });

  group('Step 6 continue and choose-option gating', () {
    ReturnEligibilityState eligibilityReady() => ReturnEligibilityState(
          checkResult: _eligibleResult(),
        );

    ReturnFlowState flowReadyForInspect() => ReturnFlowState(
          selectedSale: _sale(),
          selectedReturnLines: const [
            ReturnSelectedReturnLine(
              saleLineId: 'line-1',
              returnQty: 1,
              name: 'Item',
              sku: 'SKU',
              unitPrice: 10,
              lineTotal: 10,
            ),
          ],
          selectedReasonCode: 'DAMAGED',
          reasonsValidated: true,
          lineReasonSelections: const {
            'line-1': ReturnLineReasonSelection(
              saleLineId: 'line-1',
              reasonCode: 'DAMAGED',
              reasonId: 'reason-1',
              notes: '',
            ),
          },
          lineInspections: const {
            'line-1': ReturnLineInspection(
              saleLineId: 'line-1',
              conditionCode: 'OPENED_GOOD',
              conditionId: 'cond-1',
            ),
          },
        );

    test('Continue disabled without returns.create', () {
      expect(
        ReturnsRouteGuard.canContinueFromInspection(
          granted: {PosPermissionCodes.viewReturns},
          flow: flowReadyForInspect(),
          eligibility: eligibilityReady(),
          reasonsValidated: true,
          localCanContinue: true,
          isValidating: false,
          hasUploadInProgress: false,
        ),
        isFalse,
      );
    });

    test('Continue disabled while upload in progress', () {
      expect(
        ReturnsRouteGuard.canContinueFromInspection(
          granted: {
            PosPermissionCodes.viewReturns,
            PosPermissionCodes.createReturn,
          },
          flow: flowReadyForInspect(),
          eligibility: eligibilityReady(),
          reasonsValidated: true,
          localCanContinue: true,
          isValidating: false,
          hasUploadInProgress: true,
        ),
        isFalse,
      );
    });

    test('Continue enabled with view+create and complete local state', () {
      expect(
        ReturnsRouteGuard.canContinueFromInspection(
          granted: {
            PosPermissionCodes.viewReturns,
            PosPermissionCodes.createReturn,
          },
          flow: flowReadyForInspect(),
          eligibility: eligibilityReady(),
          reasonsValidated: true,
          localCanContinue: true,
          isValidating: false,
          hasUploadInProgress: false,
        ),
        isTrue,
      );
    });

    test('Choose Option deep-link blocked without validated inspection', () {
      expect(
        ReturnsRouteGuard.hasChooseOptionContext(
          flow: flowReadyForInspect(),
          eligibility: eligibilityReady(),
          reasonsValidated: true,
          inspectionsValidated: false,
        ),
        isFalse,
      );
    });

    test('Choose Option context allowed after validated inspection', () {
      expect(
        ReturnsRouteGuard.hasChooseOptionContext(
          flow: flowReadyForInspect(),
          eligibility: eligibilityReady(),
          reasonsValidated: true,
          inspectionsValidated: true,
        ),
        isTrue,
      );
    });

    test('exchanges.view alone does not unlock Step 6 continue', () {
      expect(
        ReturnsRouteGuard.canContinueFromInspection(
          granted: {
            PosPermissionCodes.viewExchanges,
            PosPermissionCodes.createExchange,
          },
          flow: flowReadyForInspect(),
          eligibility: eligibilityReady(),
          reasonsValidated: true,
          localCanContinue: true,
          isValidating: false,
          hasUploadInProgress: false,
        ),
        isFalse,
      );
    });
  });
}
