import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../presentation/providers/tenant_admin_context_provider.dart';
import '../../../../../core/network/dio_provider.dart';
import '../../data/models/hardware_device_list_item_dto.dart';
import '../../data/mappers/hardware_device_list_item_mapper.dart';
import '../../domain/entities/hardware_device_list_item.dart';

typedef HardwareDashboardQuery = ({
  int page,
  String? outletId,
  String search,
  String type,
  String status,
  String sort
});

class HardwareDashboard {
  const HardwareDashboard(
      this.items, this.statuses, this.summary, this.totalCount,
      {this.checkedAt, this.notAssignedCount});
  final DateTime? checkedAt;
  final int? notAssignedCount;
  final List<HardwareDeviceListItem> items;
  final Map<String, String> statuses;
  final Map<String, int> summary;
  final int totalCount;
}

final hardwareDashboardProvider = FutureProvider.autoDispose
    .family<HardwareDashboard, HardwareDashboardQuery>((ref, query) async {
  final context = await ref.watch(tenantAdminContextProvider.future);
  if (query.outletId == null ||
      !context.accessibleOutletIds.contains(query.outletId)) {
    return const HardwareDashboard([], {}, {}, 0);
  }
  final response = await ref
      .watch(appDioProvider)
      .get('/api/v1/tenant-admin/hardware-devices/dashboard', queryParameters: {
    'page': query.page,
    if (query.outletId != null) 'outletId': query.outletId,
    'pageSize': 5,
    'search': query.search,
    'type': query.type,
    'status': query.status,
    'sort': query.sort
  });
  final data = Map<String, dynamic>.from(response.data['data'] as Map);
  // Refresh only while the dashboard has a listener; no device commands are sent.
  final timer = Timer(const Duration(seconds: 30), ref.invalidateSelf);
  ref.onDispose(timer.cancel);
  final rows = (data['items'] as List)
      .map((e) => Map<String, dynamic>.from(e as Map))
      .toList();
  return HardwareDashboard(
      rows
          .map((e) => HardwareDeviceListItemDto.fromJson(e).toEntity())
          .toList(),
      {
        for (final row in rows)
          row['hardwareDeviceId'] as String: row['readiness'] as String
      },
      Map<String, int>.from(data['summary'] as Map),
      data['totalCount'] as int,
      notAssignedCount: data['notAssignedCount'] as int?,
      checkedAt: DateTime.tryParse(data['checkedAt']?.toString() ?? ''));
});
