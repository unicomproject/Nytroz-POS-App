import '../../domain/entities/till.dart';
import '../models/till_dto.dart';

class TillMapper {
  const TillMapper._();

  static Till toEntity(TillDto dto) {
    return Till(
      id: dto.id,
      outletId: dto.outletId,
      outletName: dto.outletName,
      name: dto.name,
      code: dto.code,
      status: dto.status,
      operationalStatus: dto.operationalStatus,
      attentionLabel: dto.attentionLabel,
      lastActiveAt: dto.lastActiveAt,
    );
  }

  static TillListSummary toSummaryEntity(TillListSummaryDto dto) {
    return TillListSummary(
      totalTills: dto.totalTills,
      onlineCount: dto.onlineCount,
      offlineCount: dto.offlineCount,
      inactiveCount: dto.inactiveCount,
      needsAttentionCount: dto.needsAttentionCount,
    );
  }

  static TillListResult toListResult(TillListResultDto dto) {
    return TillListResult(
      summary: toSummaryEntity(dto.summary),
      items: dto.items.map(toEntity).toList(growable: false),
      page: dto.page,
      pageSize: dto.pageSize,
      totalCount: dto.totalCount,
    );
  }

  static CreatedTill toCreatedEntity(CreatedTillDto dto) {
    return CreatedTill(
      id: dto.id,
      outletId: dto.outletId,
      name: dto.name,
      code: dto.code,
      status: dto.status,
    );
  }

  static TillDetail toDetailEntity(TillDetailDto dto) {
    return TillDetail(
      id: dto.id,
      outletId: dto.outletId,
      outletName: dto.outletName,
      outletCode: dto.outletCode,
      name: dto.name,
      code: dto.code,
      status: dto.status,
      deviceStatus: dto.deviceStatus,
      needsAttention: dto.needsAttention,
      lastActiveAt: dto.lastActiveAt,
      deviceName: dto.deviceName,
      printerName: dto.printerName,
      scannerName: dto.scannerName,
      cashDrawerName: dto.cashDrawerName,
      cardReaderName: dto.cardReaderName,
      internalNote: dto.internalNote,
      createdAt: dto.createdAt,
      updatedAt: dto.updatedAt,
    );
  }
}
