import '../../../../products/domain/entities/tenant_product.dart';
import '../../../../outlets/domain/entities/outlet.dart';

class OpeningStockState {
  const OpeningStockState({
    this.currentStep = 0,
    this.selectedProduct,
    this.selectedOutlet,
    this.quantity = 1,
    this.unitCost = 0.0,
    this.batchNumber = '',
    this.expiryDate,
    this.notes = '',
    this.isSubmitting = false,
    this.isSuccess = false,
    this.errorMessage,
    this.createdMovementId,
  });

  final int currentStep;
  final TenantProduct? selectedProduct;
  final Outlet? selectedOutlet;
  final double quantity;
  final double unitCost;
  final String batchNumber;
  final DateTime? expiryDate;
  final String notes;
  final bool isSubmitting;
  final bool isSuccess;
  final String? errorMessage;
  final String? createdMovementId;

  OpeningStockState copyWith({
    int? currentStep,
    TenantProduct? selectedProduct,
    bool clearProduct = false,
    Outlet? selectedOutlet,
    bool clearOutlet = false,
    double? quantity,
    double? unitCost,
    String? batchNumber,
    DateTime? expiryDate,
    bool clearExpiryDate = false,
    String? notes,
    bool? isSubmitting,
    bool? isSuccess,
    String? errorMessage,
    bool clearError = false,
    String? createdMovementId,
  }) {
    return OpeningStockState(
      currentStep: currentStep ?? this.currentStep,
      selectedProduct:
          clearProduct ? null : (selectedProduct ?? this.selectedProduct),
      selectedOutlet:
          clearOutlet ? null : (selectedOutlet ?? this.selectedOutlet),
      quantity: quantity ?? this.quantity,
      unitCost: unitCost ?? this.unitCost,
      batchNumber: batchNumber ?? this.batchNumber,
      expiryDate: clearExpiryDate ? null : (expiryDate ?? this.expiryDate),
      notes: notes ?? this.notes,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      createdMovementId: createdMovementId ?? this.createdMovementId,
    );
  }
}
