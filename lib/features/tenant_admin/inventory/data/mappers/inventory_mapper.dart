import '../models/stock_in_dtos.dart';
import '../../domain/entities/stock_in_entities.dart';

class InventoryMapper {
  static CreateStockInRequestDto toStockInRequest(
    StockInFormInput input, {
    String? idempotencyKey,
  }) {
    return CreateStockInRequestDto(
      outletId: input.outletId,
      referenceNumber: input.referenceNumber?.trim().isEmpty ?? true ? null : input.referenceNumber,
      notes: input.notes?.trim().isEmpty ?? true ? null : input.notes,
      idempotencyKey: idempotencyKey,
      items: input.items.map((e) => StockInLineRequestDto(
        productVariantId: e.productVariantId,
        quantity: e.quantity,
        batchNumber: e.batchNumber?.trim().isEmpty ?? true ? null : e.batchNumber,
        manufacturedDate: e.manufacturedDate != null ? '${e.manufacturedDate!.year}-${e.manufacturedDate!.month.toString().padLeft(2, '0')}-${e.manufacturedDate!.day.toString().padLeft(2, '0')}' : null,
        expiryDate: e.expiryDate != null ? '${e.expiryDate!.year}-${e.expiryDate!.month.toString().padLeft(2, '0')}-${e.expiryDate!.day.toString().padLeft(2, '0')}' : null,
      )).toList(),
    );
  }
}
