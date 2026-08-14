import '../../data/models/step5_barcode_dtos.dart';
import '../../data/models/duplicate_barcode_conflict_dto.dart';

class Step5BarcodeSkuState {
  final String baseSku;
  final String parentProductBarcode;
  final List<Step5VariantIdentifierDto> variantIdentifiers;
  final List<Step5AdditionalBarcodeDto> additionalBarcodes;
  final DuplicateBarcodeConflictDto? duplicateBarcodeConflict;

  const Step5BarcodeSkuState({
    this.baseSku = '',
    this.parentProductBarcode = '',
    this.variantIdentifiers = const [],
    this.additionalBarcodes = const [],
    this.duplicateBarcodeConflict,
  });

  Step5BarcodeSkuState copyWith({
    String? baseSku,
    String? parentProductBarcode,
    List<Step5VariantIdentifierDto>? variantIdentifiers,
    List<Step5AdditionalBarcodeDto>? additionalBarcodes,
    DuplicateBarcodeConflictDto? duplicateBarcodeConflict,
  }) {
    return Step5BarcodeSkuState(
      baseSku: baseSku ?? this.baseSku,
      parentProductBarcode: parentProductBarcode ?? this.parentProductBarcode,
      variantIdentifiers: variantIdentifiers ?? this.variantIdentifiers,
      additionalBarcodes: additionalBarcodes ?? this.additionalBarcodes,
      duplicateBarcodeConflict:
          duplicateBarcodeConflict ?? this.duplicateBarcodeConflict,
    );
  }
}
