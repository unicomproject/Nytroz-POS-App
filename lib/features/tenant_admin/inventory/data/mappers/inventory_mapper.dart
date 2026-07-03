import '../../domain/entities/inventory.dart';
import '../models/inventory_dto.dart';

class InventoryMapper {
  const InventoryMapper._();

  static InventoryLocation toLocationEntity(InventoryLocationDto dto) {
    return InventoryLocation(
      id: dto.id,
      name: dto.name,
      code: dto.code,
    );
  }

  static InventoryBalanceSummary toSummaryEntity(InventoryBalanceSummaryDto dto) {
    return InventoryBalanceSummary(
      onHand: dto.onHand,
      reserved: dto.reserved,
      available: dto.available,
      lowStockItems: dto.lowStockItems,
    );
  }

  static InventoryBalanceRow toBalanceRowEntity(InventoryBalanceRowDto dto) {
    return InventoryBalanceRow(
      productId: dto.productId,
      productName: dto.productName,
      variantId: dto.variantId,
      variantLabel: dto.variantLabel,
      onHand: dto.onHand,
      reserved: dto.reserved,
      available: dto.available,
      lowStockThreshold: dto.lowStockThreshold,
    );
  }

  static InventoryBalanceListResult toBalanceListResult(
    InventoryBalanceListResultDto dto,
  ) {
    return InventoryBalanceListResult(
      summary: toSummaryEntity(dto.summary),
      items: dto.items.map(toBalanceRowEntity).toList(growable: false),
      page: dto.page,
      pageSize: dto.pageSize,
      totalCount: dto.totalCount,
    );
  }
}
