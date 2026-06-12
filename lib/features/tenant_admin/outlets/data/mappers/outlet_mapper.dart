import '../../domain/entities/outlet.dart';
import '../../domain/entities/outlet_details.dart';
import '../models/outlet_dto.dart';

extension OutletMapper on OutletDto {
  Outlet toEntity() {
    return Outlet(
      id: id,
      name: name,
      code: code,
      location: location,
      status: status,
      tillCount: tillCount,
      onlineTillCount: onlineTillCount,
      staffCount: staffCount,
      todaysSales: todaysSales,
    );
  }
}

extension OutletListResultMapper on OutletListResultDto {
  OutletListResult toEntity() {
    return OutletListResult(
      summary: summary.toEntity(),
      items: items.map((item) => item.toEntity()).toList(),
    );
  }
}

extension OutletListSummaryMapper on OutletListSummaryDto {
  OutletListSummary toEntity() {
    return OutletListSummary(
      totalOutlets: totalOutlets,
      activeOutlets: activeOutlets,
      inactiveOutlets: inactiveOutlets,
      totalLocations: totalLocations,
    );
  }
}

extension OutletDetailsMapper on OutletDetailsDto {
  OutletDetails toEntity() {
    return OutletDetails(
      id: id,
      name: name,
      code: code,
      address: address,
      status: status,
      managerName: managerName,
      managerPhone: managerPhone,
      openingHours: openingHours,
      todaysStatus: todaysStatus,
      metrics: metrics.map((metric) => metric.toEntity()).toList(),
      assignedTills: assignedTills.map((item) => item.toEntity()).toList(),
      staff: staff.map((item) => item.toEntity()).toList(),
      needsAttention: needsAttention.map((item) => item.toEntity()).toList(),
    );
  }
}

extension OutletDetailMetricMapper on OutletDetailMetricDto {
  OutletDetailMetric toEntity() {
    return OutletDetailMetric(
      title: title,
      value: value,
      subtitle: subtitle,
      iconKey: iconKey,
    );
  }
}

extension OutletRelatedItemMapper on OutletRelatedItemDto {
  OutletRelatedItem toEntity() {
    return OutletRelatedItem(
      id: id,
      title: title,
      subtitle: subtitle,
      status: status,
    );
  }
}

extension OutletAttentionItemMapper on OutletAttentionItemDto {
  OutletAttentionItem toEntity() {
    return OutletAttentionItem(
      title: title,
      message: message,
      status: status,
    );
  }
}

extension OutletManagerOptionMapper on OutletManagerOptionDto {
  OutletManagerOption toEntity() {
    return OutletManagerOption(
      id: id,
      displayName: displayName,
    );
  }
}
