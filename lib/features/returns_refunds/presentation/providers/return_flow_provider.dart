import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/return_flow_steps.dart';
import '../../domain/entities/return_receipt.dart';
import '../../domain/entities/return_sale_summary.dart';

class ReturnFlowState {
  const ReturnFlowState({
    this.currentStep = ReturnFlowSteps.searchSale,
    this.selectedSale,
    this.selectedReturnLines = const [],
    this.selectedReasonCode,
    this.returnNotes = '',
    this.creditPreviewConfirmed = false,
    this.selectedSettlementMethodCode,
    this.completedReceipt,
  });

  final int currentStep;
  final ReturnSaleSummary? selectedSale;
  final List<ReturnSelectedReturnLine> selectedReturnLines;
  final String? selectedReasonCode;
  final String returnNotes;
  final bool creditPreviewConfirmed;
  final String? selectedSettlementMethodCode;
  final ReturnReceipt? completedReceipt;

  ReturnFlowState copyWith({
    int? currentStep,
    ReturnSaleSummary? selectedSale,
    List<ReturnSelectedReturnLine>? selectedReturnLines,
    String? selectedReasonCode,
    String? returnNotes,
    bool? creditPreviewConfirmed,
    String? selectedSettlementMethodCode,
    ReturnReceipt? completedReceipt,
    bool clearSelectedSale = false,
    bool clearSelectedReturnLines = false,
    bool clearReturnReason = false,
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

  void setStep(int step) {
    state = state.copyWith(currentStep: step);
  }

  void selectSale(ReturnSaleSummary sale) {
    state = state.copyWith(
      selectedSale: sale,
      currentStep: ReturnFlowSteps.searchSale,
      clearSelectedReturnLines: true,
      clearReturnReason: true,
      clearCreditPreviewConfirmation: true,
      clearSettlementMethod: true,
      clearCompletedReceipt: true,
    );
  }

  void setSelectedReturnLines(List<ReturnSelectedReturnLine> lines) {
    state = state.copyWith(
      selectedReturnLines: lines,
      clearReturnReason: true,
      clearCreditPreviewConfirmation: true,
      clearSettlementMethod: true,
      clearCompletedReceipt: true,
    );
  }

  void setReturnReason({
    required String reasonCode,
    String notes = '',
  }) {
    state = state.copyWith(
      selectedReasonCode: reasonCode,
      returnNotes: notes,
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

  void setCompletedReceipt(ReturnReceipt receipt) {
    state = state.copyWith(completedReceipt: receipt);
  }

  void reset() {
    state = const ReturnFlowState();
  }
}

final returnFlowProvider =
    StateNotifierProvider<ReturnFlowController, ReturnFlowState>(
  (ref) => ReturnFlowController(),
);
