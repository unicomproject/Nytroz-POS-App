import '../../domain/entities/till.dart';
import '../models/create_till_request_dto.dart';
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
      todaySalesAmount: dto.todaySalesAmount,
      currency: dto.currency,
      lastSyncAt: dto.lastSyncAt,
    );
  }

  static TillListSummary toSummary(TillListSummaryDto dto) {
    return TillListSummary(
      totalTills: dto.totalTills,
      onlineCount: dto.onlineCount,
      offlineCount: dto.offlineCount,
      needsAttentionCount: dto.needsAttentionCount,
    );
  }

  static TillListResult toListResult(TillListResultDto dto) {
    return TillListResult(
      summary: toSummary(dto.summary),
      items: dto.items.map(toEntity).toList(growable: false),
      page: dto.page,
      pageSize: dto.pageSize,
      totalCount: dto.totalCount,
    );
  }

  static CreateTillRequestDto toCreateRequest(CreateTillInput input) {
    return CreateTillRequestDto(
      name: input.name.trim(),
      code: input.code.trim(),
      outletId: input.outletId,
      status: input.status,
    );
  }
}
