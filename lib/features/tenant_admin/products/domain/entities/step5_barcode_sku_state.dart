import '../../data/models/step5_barcode_dtos.dart';
import '../../data/models/duplicate_barcode_conflict_dto.dart';

class Step5BarcodeSkuState {
  /// SIMPLE / BUNDLE: user-entered Base SKU (no productVariantId required).
  final String baseSku;

  /// SIMPLE / BUNDLE: Parent Product Barcode (optional unless validated as required).
  final String parentProductBarcode;

  /// VARIANT (and shared list projection): per-target assignments.
  final List<Step5IdentifierTargetDto> identifierTargets;
  final List<BarcodeSkuAssignmentDto> assignments;
  final DuplicateBarcodeConflictDto? duplicateBarcodeConflict;

  const Step5BarcodeSkuState({
    this.baseSku = '',
    this.parentProductBarcode = '',
    this.identifierTargets = const [],
    this.assignments = const [],
    this.duplicateBarcodeConflict,
  });

  Step5BarcodeSkuState copyWith({
    String? baseSku,
    String? parentProductBarcode,
    List<Step5IdentifierTargetDto>? identifierTargets,
    List<BarcodeSkuAssignmentDto>? assignments,
    DuplicateBarcodeConflictDto? duplicateBarcodeConflict,
    bool clearDuplicateBarcodeConflict = false,
  }) {
    return Step5BarcodeSkuState(
      baseSku: baseSku ?? this.baseSku,
      parentProductBarcode: parentProductBarcode ?? this.parentProductBarcode,
      identifierTargets: identifierTargets ?? this.identifierTargets,
      assignments: assignments ?? this.assignments,
      duplicateBarcodeConflict: clearDuplicateBarcodeConflict
          ? null
          : (duplicateBarcodeConflict ?? this.duplicateBarcodeConflict),
    );
  }
}
