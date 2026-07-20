import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/exchange_replacement_selection.dart';
import '../../domain/entities/refund_method_type.dart';
import '../../domain/entities/return_credit_preview.dart';
import '../../domain/entities/return_flow_steps.dart';
import '../../domain/entities/return_inspection.dart';
import '../../domain/entities/return_reason_option.dart';
import '../../domain/entities/return_receipt.dart';
import '../../domain/entities/return_resolution_type.dart';
import '../../domain/entities/return_sale_summary.dart';

class ReturnFlowState {
  const ReturnFlowState({
    this.currentStep = ReturnFlowSteps.searchSale,
    this.selectedSale,
    this.selectedReturnLines = const [],
    this.selectedReasonCode,
    this.returnNotes = '',
    this.applySameReasonToAll = true,
    this.lineReasonSelections = const {},
    this.lineInspections = const {},
    this.reasonsValidated = false,
    this.requiresInspection = false,
    this.requiresManagerApproval = false,
    this.inspectionsValidated = false,
    this.selectedResolution,
    this.resolutionPersisted = false,
    this.refundPreview,
    this.selectedRefundMethod,
    this.selectedReplacement,
    this.creditPreviewConfirmed = false,
    this.selectedSettlementMethodCode,
    this.completedReceipt,
  });

  final ReturnsExchangeStep currentStep;
  final ReturnSaleSummary? selectedSale;
  final List<ReturnSelectedReturnLine> selectedReturnLines;
  final String? selectedReasonCode;
  final String returnNotes;
  final bool applySameReasonToAll;
  final Map<String, ReturnLineReasonSelection> lineReasonSelections;
  final Map<String, ReturnLineInspection> lineInspections;
  final bool reasonsValidated;
  final bool requiresInspection;
  final bool requiresManagerApproval;
  final bool inspectionsValidated;
  final ReturnResolutionType? selectedResolution;
  final bool resolutionPersisted;
  final ReturnCreditPreview? refundPreview;
  final RefundMethodType? selectedRefundMethod;
  final ExchangeReplacementSelection? selectedReplacement;
  final bool creditPreviewConfirmed;
  final String? selectedSettlementMethodCode;
  final ReturnReceipt? completedReceipt;

  ReturnFlowState copyWith({
    ReturnsExchangeStep? currentStep,
    ReturnSaleSummary? selectedSale,
    List<ReturnSelectedReturnLine>? selectedReturnLines,
    String? selectedReasonCode,
    String? returnNotes,
    bool? applySameReasonToAll,
    Map<String, ReturnLineReasonSelection>? lineReasonSelections,
    Map<String, ReturnLineInspection>? lineInspections,
    bool? reasonsValidated,
    bool? requiresInspection,
    bool? requiresManagerApproval,
    bool? inspectionsValidated,
    ReturnResolutionType? selectedResolution,
    bool? resolutionPersisted,
    ReturnCreditPreview? refundPreview,
    RefundMethodType? selectedRefundMethod,
    ExchangeReplacementSelection? selectedReplacement,
    bool? creditPreviewConfirmed,
    String? selectedSettlementMethodCode,
    ReturnReceipt? completedReceipt,
    bool clearSelectedSale = false,
    bool clearSelectedReturnLines = false,
    bool clearReturnReason = false,
    bool clearSelectedResolution = false,
    bool clearResolutionPersisted = false,
    bool clearRefundPreview = false,
    bool clearSelectedRefundMethod = false,
    bool clearSelectedReplacement = false,
    bool clearCreditPreviewConfirmation = false,
    bool clearSettlementMethod = false,
    bool clearCompletedReceipt = false,
  }) {
    return ReturnFlowState(
      currentStep: currentStep ?? this.currentStep,
      selectedSale:
          clearSelectedSale ? null : selectedSale ?? this.selectedSale,
      selectedReturnLines: clearSelectedReturnLines
          ? const []
          : selectedReturnLines ?? this.selectedReturnLines,
      selectedReasonCode: clearReturnReason
          ? null
          : selectedReasonCode ?? this.selectedReasonCode,
      returnNotes: clearReturnReason ? '' : returnNotes ?? this.returnNotes,
      applySameReasonToAll: clearReturnReason
          ? true
          : applySameReasonToAll ?? this.applySameReasonToAll,
      lineReasonSelections: clearReturnReason
          ? const {}
          : lineReasonSelections ?? this.lineReasonSelections,
      lineInspections: clearReturnReason
          ? const {}
          : lineInspections ?? this.lineInspections,
      reasonsValidated: clearReturnReason
          ? false
          : reasonsValidated ?? this.reasonsValidated,
      requiresInspection: clearReturnReason
          ? false
          : requiresInspection ?? this.requiresInspection,
      requiresManagerApproval: clearReturnReason
          ? false
          : requiresManagerApproval ?? this.requiresManagerApproval,
      inspectionsValidated: clearReturnReason
          ? false
          : inspectionsValidated ?? this.inspectionsValidated,
      selectedResolution: clearSelectedResolution
          ? null
          : selectedResolution ?? this.selectedResolution,
      resolutionPersisted: clearResolutionPersisted
          ? false
          : resolutionPersisted ?? this.resolutionPersisted,
      refundPreview:
          clearRefundPreview ? null : refundPreview ?? this.refundPreview,
      selectedRefundMethod: clearSelectedRefundMethod
          ? null
          : selectedRefundMethod ?? this.selectedRefundMethod,
      selectedReplacement: clearSelectedReplacement
          ? null
          : selectedReplacement ?? this.selectedReplacement,
      creditPreviewConfirmed: clearCreditPreviewConfirmation
          ? false
          : creditPreviewConfirmed ?? this.creditPreviewConfirmed,
      selectedSettlementMethodCode: clearSettlementMethod
          ? null
          : selectedSettlementMethodCode ?? this.selectedSettlementMethodCode,
      completedReceipt: clearCompletedReceipt
          ? null
          : completedReceipt ?? this.completedReceipt,
    );
  }
}

class ReturnSelectedReturnLine {
  const ReturnSelectedReturnLine({
    required this.saleLineId,
    required this.name,
    required this.unitPrice,
    required this.returnQty,
    required this.lineTotal,
    this.sku = '',
    this.variantLabel = '',
    this.imageStorageKey,
  });

  final String saleLineId;
  final String name;
  final double unitPrice;
  final int returnQty;
  final double lineTotal;
  final String sku;
  final String variantLabel;
  final String? imageStorageKey;
}

class ReturnFlowController extends StateNotifier<ReturnFlowState> {
  ReturnFlowController() : super(const ReturnFlowState());

  void setStep(ReturnsExchangeStep step) {
    state = state.copyWith(currentStep: step);
  }

  void selectSale(ReturnSaleSummary sale) {
    state = state.copyWith(
      selectedSale: sale,
      currentStep: ReturnFlowSteps.searchSale,
      clearSelectedReturnLines: true,
      clearReturnReason: true,
      clearSelectedResolution: true,
      clearResolutionPersisted: true,
      clearRefundPreview: true,
      clearSelectedRefundMethod: true,
      clearSelectedReplacement: true,
      clearCreditPreviewConfirmation: true,
      clearSettlementMethod: true,
      clearCompletedReceipt: true,
    );
  }

  void setSelectedReturnLines(List<ReturnSelectedReturnLine> lines) {
    state = state.copyWith(
      selectedReturnLines: lines,
      clearReturnReason: true,
      clearSelectedResolution: true,
      clearResolutionPersisted: true,
      clearRefundPreview: true,
      clearSelectedRefundMethod: true,
      clearSelectedReplacement: true,
      clearCreditPreviewConfirmation: true,
      clearSettlementMethod: true,
      clearCompletedReceipt: true,
    );
  }

  void setReturnReason({
    required String reasonCode,
    String notes = '',
    bool applySameReasonToAll = true,
    Map<String, ReturnLineReasonSelection> lineSelections = const {},
    bool reasonsValidated = false,
    bool requiresInspection = false,
    bool requiresManagerApproval = false,
  }) {
    state = state.copyWith(
      selectedReasonCode: reasonCode,
      returnNotes: notes,
      applySameReasonToAll: applySameReasonToAll,
      lineReasonSelections: lineSelections,
      reasonsValidated: reasonsValidated,
      requiresInspection: requiresInspection,
      requiresManagerApproval: requiresManagerApproval,
      inspectionsValidated: false,
      clearCreditPreviewConfirmation: true,
      clearSettlementMethod: true,
      clearCompletedReceipt: true,
    );
  }

  void setLineInspections(
    Map<String, ReturnLineInspection> inspections, {
    bool inspectionsValidated = false,
  }) {
    state = state.copyWith(
      lineInspections: inspections,
      inspectionsValidated: inspectionsValidated,
      clearCreditPreviewConfirmation: true,
      clearSettlementMethod: true,
      clearCompletedReceipt: true,
    );
  }

  /// Merges Step 4/5/6 inspection and approval flags without downgrading
  /// earlier true values to false.
  void applyInspectionValidation({
    required Map<String, ReturnLineInspection> inspections,
    required bool inspectionsValidated,
    bool step6RequiresInspection = false,
    bool step6RequiresManagerApproval = false,
    bool validationRequiresInspection = false,
    bool validationRequiresManagerApproval = false,
  }) {
    state = state.copyWith(
      lineInspections: inspections,
      inspectionsValidated: inspectionsValidated,
      requiresInspection: state.requiresInspection ||
          step6RequiresInspection ||
          validationRequiresInspection,
      requiresManagerApproval: state.requiresManagerApproval ||
          step6RequiresManagerApproval ||
          validationRequiresManagerApproval,
      clearCreditPreviewConfirmation: true,
      clearSettlementMethod: true,
      clearCompletedReceipt: true,
    );
  }

  void setSelectedResolution(ReturnResolutionType resolution) {
    final previous = state.selectedResolution;

    state = state.copyWith(
      selectedResolution: resolution,
      resolutionPersisted: false,
      clearRefundPreview: previous != null && previous != resolution,
      clearSelectedRefundMethod: resolution == ReturnResolutionType.exchange,
      clearSelectedReplacement: resolution == ReturnResolutionType.refund,
      clearCreditPreviewConfirmation: true,
      clearSettlementMethod: true,
      clearCompletedReceipt: true,
    );
  }

  void applyPersistedResolution({
    required ReturnResolutionType resolution,
    required bool persisted,
  }) {
    state = state.copyWith(
      selectedResolution: resolution,
      resolutionPersisted: persisted,
    );
  }

  void clearPersistedResolution() {
    state = state.copyWith(
      clearSelectedResolution: true,
      clearResolutionPersisted: true,
      clearRefundPreview: true,
      clearSelectedRefundMethod: true,
      clearSelectedReplacement: true,
      clearCreditPreviewConfirmation: true,
      clearSettlementMethod: true,
      clearCompletedReceipt: true,
    );
  }

  void setSelectedReplacement(ExchangeReplacementSelection selection) {
    state = state.copyWith(
      selectedReplacement: selection,
      clearCreditPreviewConfirmation: true,
      clearSettlementMethod: true,
      clearCompletedReceipt: true,
    );
  }

  void setRefundPreview(ReturnCreditPreview? preview) {
    if (preview == null) {
      state = state.copyWith(clearRefundPreview: true);
      return;
    }
    state = state.copyWith(refundPreview: preview);
  }

  void setSelectedRefundMethod(RefundMethodType method) {
    state = state.copyWith(
      selectedRefundMethod: method,
      clearCreditPreviewConfirmation: true,
      clearSettlementMethod: true,
      clearCompletedReceipt: true,
    );
  }

  void setCreditPreviewConfirmed(bool value) {
    state = state.copyWith(creditPreviewConfirmed: value);
  }

  void setSettlementMethod(String code) {
    state = state.copyWith(
      selectedSettlementMethodCode: code,
      clearCompletedReceipt: true,
    );
  }

  void clearSettlementMethod() {
    state = state.copyWith(clearSettlementMethod: true);
  }

  void setCompletedReceipt(ReturnReceipt receipt) {
    state = state.copyWith(completedReceipt: receipt);
  }

  void reset() {
    state = const ReturnFlowState();
  }

  /// Clears the active Returns & Exchanges draft while preserving
  /// auth/session/till/device context held outside this provider.
  void resetReturnExchangeDraft() {
    reset();
  }
}

final returnFlowProvider =
    StateNotifierProvider<ReturnFlowController, ReturnFlowState>(
  (ref) => ReturnFlowController(),
);
