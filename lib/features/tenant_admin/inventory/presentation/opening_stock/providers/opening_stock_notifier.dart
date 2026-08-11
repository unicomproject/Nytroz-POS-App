import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../products/domain/entities/tenant_product.dart';
import '../../../../outlets/domain/entities/outlet.dart';
import '../../../domain/entities/opening_stock_param.dart';
import '../../../domain/repositories/opening_stock_repository.dart';
import 'opening_stock_state.dart';

class OpeningStockNotifier extends StateNotifier<OpeningStockState> {
  OpeningStockNotifier(this._repository) : super(const OpeningStockState());

  final OpeningStockRepository _repository;

  void setStep(int step) {
    state = state.copyWith(currentStep: step);
  }

  void nextStep() {
    if (state.currentStep < 3) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  void selectProduct(TenantProduct product) {
    state = state.copyWith(
      selectedProduct: product,
      clearError: true,
    );
  }

  void selectOutlet(Outlet outlet) {
    state = state.copyWith(
      selectedOutlet: outlet,
      clearError: true,
    );
  }

  void setQuantity(double quantity) {
    state = state.copyWith(quantity: quantity);
  }

  void setUnitCost(double unitCost) {
    state = state.copyWith(unitCost: unitCost);
  }

  void setBatchNumber(String batchNumber) {
    state = state.copyWith(batchNumber: batchNumber);
  }

  void setExpiryDate(DateTime? expiryDate) {
    if (expiryDate == null) {
      state = state.copyWith(clearExpiryDate: true);
    } else {
      state = state.copyWith(expiryDate: expiryDate);
    }
  }

  void setNotes(String notes) {
    state = state.copyWith(notes: notes);
  }

  Future<bool> submit() async {
    if (state.selectedProduct == null || state.selectedOutlet == null) {
      state = state.copyWith(errorMessage: 'Please select a product and an outlet.');
      return false;
    }

    if (state.quantity <= 0) {
      state = state.copyWith(errorMessage: 'Quantity must be greater than 0.');
      return false;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);

    try {
      final param = OpeningStockParam(
        outletId: state.selectedOutlet!.id,
        notes: state.notes.isNotEmpty ? state.notes : null,
        items: [
          OpeningStockLineParam(
            productId: state.selectedProduct!.id,
            quantity: state.quantity,
            unitCost: state.unitCost,
            batchNumber: state.batchNumber.isNotEmpty ? state.batchNumber : null,
            expiryDate: state.expiryDate != null
                ? "${state.expiryDate!.year.toString().padLeft(4, '0')}-${state.expiryDate!.month.toString().padLeft(2, '0')}-${state.expiryDate!.day.toString().padLeft(2, '0')}"
                : null,
          ),
        ],
      );

      final result = await _repository.submitOpeningStock(param);

      state = state.copyWith(
        isSubmitting: false,
        isSuccess: true,
        createdMovementId: result.stockMovementId,
        currentStep: 3, // Success step
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  void reset() {
    state = const OpeningStockState();
  }
}
