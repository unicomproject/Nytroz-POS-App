import '../../data/models/step5_barcode_dtos.dart';
import '../../data/models/duplicate_barcode_conflict_dto.dart';

enum Step5StatusFilter {
  all,
  complete,
  incomplete,
  error,
}

class Step5BarcodeSkuState {
  /// SIMPLE / BUNDLE: user-entered Base SKU (no productVariantId required).
  final String baseSku;

  /// SIMPLE / BUNDLE: Parent Product Barcode (optional unless validated as required).
  final String parentProductBarcode;

  /// SIMPLE / BUNDLE: selected barcode type for parent barcode.
  final String? parentBarcodeType;

  /// VARIANT (and shared list projection): per-target assignments.
  final List<Step5IdentifierTargetDto> identifierTargets;
  final List<BarcodeSkuAssignmentDto> assignments;
  final DuplicateBarcodeConflictDto? duplicateBarcodeConflict;

  /// UI-only multi-select — never persisted / never changes sellability.
  final Set<String> selectedClientKeys;

  final String searchQuery;
  final Step5StatusFilter statusFilter;

  const Step5BarcodeSkuState({
    this.baseSku = '',
    this.parentProductBarcode = '',
    this.parentBarcodeType,
    this.identifierTargets = const [],
    this.assignments = const [],
    this.duplicateBarcodeConflict,
    this.selectedClientKeys = const {},
    this.searchQuery = '',
    this.statusFilter = Step5StatusFilter.all,
  });

  Step5BarcodeSkuState copyWith({
    String? baseSku,
    String? parentProductBarcode,
    String? parentBarcodeType,
    bool clearParentBarcodeType = false,
    List<Step5IdentifierTargetDto>? identifierTargets,
    List<BarcodeSkuAssignmentDto>? assignments,
    DuplicateBarcodeConflictDto? duplicateBarcodeConflict,
    bool clearDuplicateBarcodeConflict = false,
    Set<String>? selectedClientKeys,
    String? searchQuery,
    Step5StatusFilter? statusFilter,
  }) {
    return Step5BarcodeSkuState(
      baseSku: baseSku ?? this.baseSku,
      parentProductBarcode:
          parentProductBarcode ?? this.parentProductBarcode,
      parentBarcodeType: clearParentBarcodeType
          ? null
          : (parentBarcodeType ?? this.parentBarcodeType),
      identifierTargets: identifierTargets ?? this.identifierTargets,
      assignments: assignments ?? this.assignments,
      duplicateBarcodeConflict: clearDuplicateBarcodeConflict
          ? null
          : (duplicateBarcodeConflict ?? this.duplicateBarcodeConflict),
      selectedClientKeys: selectedClientKeys ?? this.selectedClientKeys,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter ?? this.statusFilter,
    );
  }

  List<BarcodeSkuAssignmentDto> get filteredAssignments {
    final q = searchQuery.trim().toLowerCase();
    return assignments.where((a) {
      final status = a.effectiveStatus;
      switch (statusFilter) {
        case Step5StatusFilter.complete:
          if (status != 'COMPLETE') return false;
          break;
        case Step5StatusFilter.incomplete:
          if (status != 'INCOMPLETE') return false;
          break;
        case Step5StatusFilter.error:
          if (status != 'DUPLICATE' && status != 'INVALID') return false;
          break;
        case Step5StatusFilter.all:
          break;
      }

      if (q.isEmpty) return true;
      final haystack = [
        a.displayName,
        a.clientCombinationKey,
        a.sku,
        a.barcode,
      ].whereType<String>().join(' ').toLowerCase();
      return haystack.contains(q);
    }).toList();
  }

  int get completeCount =>
      assignments.where((a) => a.effectiveStatus == 'COMPLETE').length;
}
