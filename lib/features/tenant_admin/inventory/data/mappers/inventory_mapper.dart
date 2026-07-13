import '../../domain/entities/inventory_entities.dart';
import '../models/inventory_dto.dart';

class InventoryMapper {
  const InventoryMapper._();

  static CurrentStockQueryDto toQueryDto(CurrentStockQuery query) {
    return CurrentStockQueryDto(
      outletId: query.outletId,
      search: query.search,
      stockStatus: query.stockStatus,
      categoryId: query.categoryId,
      batchNumber: query.batchNumber,
      expiryStatus: query.expiryStatus,
      page: query.page,
      pageSize: query.pageSize,
      sortBy: query.sortBy,
      sortDirection: query.sortDirection,
    );
  }

  static CurrentStockPage toPage(CurrentStockPageDto dto) {
    return CurrentStockPage(
      items: dto.items.map(toItem).toList(),
      page: dto.page,
      pageSize: dto.pageSize,
      totalCount: dto.totalCount,
    );
  }

  static CurrentStockItem toItem(CurrentStockItemDto dto) {
    return CurrentStockItem(
      inventoryBalanceId: dto.inventoryBalanceId,
      inventoryLocationId: dto.inventoryLocationId,
      outletId: dto.outletId,
      outletName: dto.outletName,
      productId: dto.productId,
      productName: dto.productName,
      productVariantId: dto.productVariantId,
      variantName: dto.variantName,
      variantOptions: dto.variantOptions
          .map(
            (option) => CurrentStockVariantOption(
              name: option.name,
              value: option.value,
            ),
          )
          .toList(),
      sku: dto.sku,
      barcode: dto.barcode,
      productBatchId: dto.productBatchId,
      batchNumber: dto.batchNumber,
      expiryDate: dto.expiryDate,
      onHandQuantity: dto.onHandQuantity,
      reservedQuantity: dto.reservedQuantity,
      damagedQuantity: dto.damagedQuantity,
      quarantineQuantity: dto.quarantineQuantity,
      availableQuantity: dto.availableQuantity,
      stockStatus: dto.stockStatus,
      expiryStatus: dto.expiryStatus,
      lastMovementAt: dto.lastMovementAt,
      rowVersion: dto.rowVersion,
    );
  }

  static CurrentStockSummary toSummary(CurrentStockSummaryDto dto) {
    return CurrentStockSummary(
      totalProducts: dto.totalProducts,
      totalVariants: dto.totalVariants,
      totalUnits: dto.totalUnits,
      lowStockCount: dto.lowStockCount,
      outOfStockCount: dto.outOfStockCount,
      expiringSoonCount: dto.expiringSoonCount,
    );
  }

  static CreateStockInRequestDto toStockInRequest(
    StockInFormInput input, {
    String? idempotencyKey,
  }) {
    return CreateStockInRequestDto(
      outletId: input.outletId!,
      referenceNumber: _nullableTrimmed(input.referenceNumber),
      receivedAt: input.receivedAt?.toUtc().toIso8601String(),
      notes: _nullableTrimmed(input.notes),
      idempotencyKey: idempotencyKey,
      items: input.items
          .where(
            (line) =>
                line.productVariantId != null &&
                line.productVariantId!.isNotEmpty &&
                (line.quantity ?? 0) > 0,
          )
          .map(toStockInLineRequest)
          .toList(),
    );
  }

  static StockInLineRequestDto toStockInLineRequest(StockInLineInput line) {
    return StockInLineRequestDto(
      productVariantId: line.productVariantId!,
      batchNumber: _nullableTrimmed(line.batchNumber),
      manufacturedDate: _dateOnly(line.manufacturedDate),
      expiryDate: _dateOnly(line.expiryDate),
      quantity: line.quantity ?? 0,
      unitCost: line.unitCost,
      barcode: _nullableTrimmed(line.barcode),
    );
  }

  static StockInResult toStockInResult(StockInResponseDto dto) {
    return StockInResult(
      operationId: dto.operationId,
      outletId: dto.outletId,
      outletName: dto.outletName,
      referenceNumber: dto.referenceNumber,
      receivedAt: dto.receivedAt,
      itemCount: dto.itemCount,
      totalQuantity: dto.totalQuantity,
      status: dto.status,
      createdAt: dto.createdAt,
    );
  }

  static VariantLookup toVariantLookup(VariantLookupDto dto) {
    return VariantLookup(
      productId: dto.productId,
      productName: dto.productName,
      isBatchTracked: dto.isBatchTracked,
      isExpiryTracked: dto.isExpiryTracked,
      variants: dto.variants
          .where((variant) => variant.status.toUpperCase() == 'ACTIVE')
          .map(toVariantLookupItem)
          .toList(),
    );
  }

  static VariantLookupItem toVariantLookupItem(VariantLookupItemDto dto) {
    return VariantLookupItem(
      id: dto.id,
      name: dto.name,
      sku: dto.sku,
      barcode: dto.barcode,
      status: dto.status,
      isBatchTracked: dto.isBatchTracked,
      isExpiryTracked: dto.isExpiryTracked,
      optionValues: dto.optionValues
          .map(
            (value) => VariantOptionValue(
              attributeName: value.attributeName,
              value: value.value,
            ),
          )
          .toList(),
    );
  }

  static String? _nullableTrimmed(String? value) {
    if (value == null) {
      return null;
    }

    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static String? _dateOnly(DateTime? value) {
    if (value == null) {
      return null;
    }

    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
