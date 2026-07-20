import '../../../../core/access/pos_permission_access.dart';
import '../../../auth/domain/entities/auth_session.dart';
import '../../domain/entities/return_inspection.dart';
import '../../domain/entities/return_resolution_type.dart';
import '../../domain/entities/return_sale_eligibility.dart';
import '../providers/return_eligibility_provider.dart';
import '../providers/return_flow_provider.dart';

/// Central route permission mapping for Returns & Exchanges paths.
abstract final class ReturnsRouteGuard {
  static bool canAccessPath(AuthSession? session, String path) {
    if (session == null) {
      return false;
    }

    final granted = session.permissionCodes.toSet();
    if (!PosPermissionAccess.canViewHome(granted)) {
      return false;
    }

    switch (path) {
      case '/pos/returns-refunds/check-eligibility':
        // Step 4: shared Returns workflow — strict returns.view only.
        return PosPermissionAccess.canViewReturns(granted);

      case '/pos/returns-refunds/return-reason':
        // Advancement from Step 4 requires view + create.
        return PosPermissionAccess.canViewReturns(granted) &&
            PosPermissionAccess.canCreateReturn(granted);

      case '/pos/returns-refunds/inspect-items':
        // Inspect Items requires successfully saved reasons (create path).
        return PosPermissionAccess.canViewReturns(granted) &&
            PosPermissionAccess.canCreateReturn(granted);

      case '/pos/returns-refunds/choose-option':
        // Choose Option remains on the shared Returns path until a branch is selected.
        return PosPermissionAccess.canViewReturns(granted) &&
            PosPermissionAccess.canCreateReturn(granted);

      case '/pos/returns-refunds/refund-details':
      case '/pos/returns-refunds/create-credit':
        return PosPermissionAccess.canProcessRefund(granted);

      case '/pos/returns-refunds/exchange':
        return PosPermissionAccess.canProcessExchange(granted);

      case '/pos/returns-refunds/settlement':
        if (!PosPermissionAccess.canViewReturns(granted)) {
          return false;
        }
        return PosPermissionAccess.canProcessRefund(granted) ||
            PosPermissionAccess.canProcessExchange(granted);

      case '/pos/returns-refunds/receipt':
        return PosPermissionAccess.canAccessReturnSuccessRoute(granted);

      case '/pos/returns-refunds':
        // Step 1 Search Original Sale requires exact returns.view.
        return PosPermissionAccess.canViewReturns(granted);

      case '/pos/returns-refunds/summary':
        // Step 2 requires view + create; selected-sale context is enforced separately.
        return PosPermissionAccess.canViewReturns(granted) &&
            PosPermissionAccess.canCreateReturn(granted);

      case '/pos/returns-refunds/eligibility':
        // Step 3 view requires returns.view; mutation/Continue also needs returns.create
        // (enforced in screen/provider).
        return PosPermissionAccess.canViewReturns(granted);

      default:
        // Shared Returns workflow routes require exact returns.view.
        return PosPermissionAccess.canViewReturns(granted);
    }
  }

  /// Valid selected original sale for Continue / Step 2.
  static bool hasSelectedSaleContext(ReturnFlowState flow) {
    final sale = flow.selectedSale;
    final saleId = sale?.saleId.trim() ?? '';
    return sale != null && saleId.isNotEmpty;
  }

  /// Continue from Step 1 Search Original Sale.
  static bool canContinueFromSearch({
    required Set<String> granted,
    required bool hasValidSelection,
    required bool isLoading,
  }) {
    return PosPermissionAccess.canViewReturns(granted) &&
        PosPermissionAccess.canCreateReturn(granted) &&
        hasValidSelection &&
        !isLoading;
  }

  /// Valid workflow context to open Step 4 Check Eligibility.
  static bool hasCheckEligibilityContext(ReturnFlowState flow) {
    final sale = flow.selectedSale;
    final saleId = sale?.saleId.trim() ?? '';
    if (sale == null || saleId.isEmpty) {
      return false;
    }

    final lines = flow.selectedReturnLines;
    if (lines.isEmpty) {
      return false;
    }

    return lines.every(
      (line) => line.saleLineId.trim().isNotEmpty && line.returnQty > 0,
    );
  }

  /// Valid context to open Return Reason (after a successful Step 4 continue).
  static bool hasReturnReasonContext({
    required ReturnFlowState flow,
    required ReturnEligibilityState eligibility,
  }) {
    if (!hasCheckEligibilityContext(flow)) {
      return false;
    }

    final result = eligibility.checkResult;
    if (result == null || !result.canContinue) {
      return false;
    }

    return hasEligibleItems(result);
  }

  static bool hasEligibleItems(ReturnSaleEligibility result) {
    if (result.eligibleItemCount > 0) {
      return true;
    }
    return result.items.any((item) => item.isReturnable);
  }

  /// Continue from Step 4 to Return Reason.
  static bool canContinueFromEligibilityCheck({
    required Set<String> granted,
    required ReturnFlowState flow,
    required ReturnEligibilityState eligibility,
  }) {
    if (!PosPermissionAccess.canCreateReturn(granted)) {
      return false;
    }
    if (eligibility.isChecking) {
      return false;
    }
    if (!hasCheckEligibilityContext(flow)) {
      return false;
    }

    final result = eligibility.checkResult;
    if (result == null || !result.canContinue) {
      return false;
    }

    return hasEligibleItems(result);
  }

  /// Valid context to open Inspect Items after Step 5 reasons are saved.
  static bool hasInspectItemsContext({
    required ReturnFlowState flow,
    required ReturnEligibilityState eligibility,
    required bool reasonsValidated,
  }) {
    if (!hasReturnReasonContext(flow: flow, eligibility: eligibility)) {
      return false;
    }
    if (!reasonsValidated) {
      return false;
    }

    final reasonCode = flow.selectedReasonCode?.trim() ?? '';
    if (reasonCode.isEmpty) {
      return false;
    }

    return flow.lineReasonSelections.isNotEmpty &&
        flow.lineReasonSelections.values.every(
          (selection) => selection.reasonCode.trim().isNotEmpty,
        );
  }

  static bool canContinueFromReturnReason({
    required Set<String> granted,
    required ReturnFlowState flow,
    required ReturnEligibilityState eligibility,
    required bool reasonCanContinue,
    required bool isSaving,
  }) {
    if (!PosPermissionAccess.canViewReturns(granted) ||
        !PosPermissionAccess.canCreateReturn(granted)) {
      return false;
    }
    if (isSaving || !reasonCanContinue) {
      return false;
    }
    return hasReturnReasonContext(flow: flow, eligibility: eligibility);
  }

  /// Valid context to open Choose Option after Step 6 inspection is validated.
  static bool hasChooseOptionContext({
    required ReturnFlowState flow,
    required ReturnEligibilityState eligibility,
    required bool reasonsValidated,
    required bool inspectionsValidated,
  }) {
    if (!hasInspectItemsContext(
      flow: flow,
      eligibility: eligibility,
      reasonsValidated: reasonsValidated,
    )) {
      return false;
    }
    if (!inspectionsValidated) {
      return false;
    }

    if (flow.lineInspections.isEmpty) {
      return false;
    }

    return flow.selectedReturnLines.every((line) {
      final inspection = flow.lineInspections[line.saleLineId];
      final code = inspection?.conditionCode?.trim() ?? '';
      return code.isNotEmpty;
    });
  }

  static bool canContinueFromInspection({
    required Set<String> granted,
    required ReturnFlowState flow,
    required ReturnEligibilityState eligibility,
    required bool reasonsValidated,
    required bool localCanContinue,
    required bool isValidating,
    required bool hasUploadInProgress,
  }) {
    if (!PosPermissionAccess.canViewReturns(granted) ||
        !PosPermissionAccess.canCreateReturn(granted)) {
      return false;
    }
    if (isValidating || hasUploadInProgress || !localCanContinue) {
      return false;
    }
    return hasInspectItemsContext(
      flow: flow,
      eligibility: eligibility,
      reasonsValidated: reasonsValidated,
    );
  }

  /// Whether a local inspection line satisfies client-side completeness rules.
  static bool isInspectionLineComplete({
    required ReturnLineInspection line,
    required List<InspectionConditionOption> conditions,
  }) {
    final code = line.conditionCode;
    if (code == null || code.isEmpty) {
      return false;
    }

    InspectionConditionOption? condition;
    for (final option in conditions) {
      if (option.code == code) {
        condition = option;
        break;
      }
    }
    if (condition == null) {
      return false;
    }

    if (condition.requiresNotes && line.notes.trim().isEmpty) {
      return false;
    }

    if (condition.requiresPhoto) {
      final uploadedCount = line.media
          .where((item) =>
              item.uploadStatus == InspectionMediaUploadStatus.uploaded)
          .length;
      if (uploadedCount == 0) {
        return false;
      }
    }

    if (line.hasUploadInProgress || line.hasUploadFailure) {
      return false;
    }

    return true;
  }

  static bool hasRefundBranchContext(ReturnFlowState flow) {
    return flow.resolutionPersisted &&
        flow.selectedResolution == ReturnResolutionType.refund;
  }

  static bool hasExchangeReviewContext({
    required ReturnFlowState flow,
    required bool replacementPersisted,
    required bool previewLoaded,
    bool previewCanProceed = true,
  }) {
    return hasExchangeBranchContext(flow) &&
        replacementPersisted &&
        previewLoaded &&
        previewCanProceed;
  }

  static bool hasExchangeBranchContext(ReturnFlowState flow) {
    return flow.resolutionPersisted &&
        flow.selectedResolution == ReturnResolutionType.exchange;
  }
}
