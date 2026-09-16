import '../../../../../core/network/dio_provider.dart';
import '../../../tills/domain/entities/till_monitoring.dart';
import 'hardware_list_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../presentation/providers/tenant_admin_context_provider.dart';
import '../../../tills/domain/entities/till.dart';
import '../../../tills/presentation/providers/till_providers.dart';

/// Additional hardware-only restrictions, intersected with normal user access.
final hardwareAccessScopeProvider =
    FutureProvider<HardwareAccessScope>((ref) async {
  // Re-fetch when the authenticated tenant/user context changes.
  await ref.watch(tenantAdminContextProvider.future);
  final response = await ref
      .watch(appDioProvider)
      .get('/api/v1/tenant-admin/hardware-devices/create-options');
  final envelope = response.data;
  final data = envelope is Map ? envelope['data'] : null;
  final scope = data is Map ? data['hardwareScope'] : null;
  if (scope is! Map ||
      scope['restricted'] is! bool ||
      scope['outletIds'] is! List ||
      scope['tillIds'] is! List) {
    throw StateError('Hardware access scope is unavailable.');
  }
  Set<String> ids(dynamic value) {
    if ((value as List).any((id) => id is! String || id.isEmpty)) {
      throw StateError('Hardware access scope is invalid.');
    }
    return value.cast<String>().toSet();
  }

  return HardwareAccessScope(scope['restricted'] as bool,
      ids(scope['outletIds']), ids(scope['tillIds']));
});

class HardwareAccessScope {
  const HardwareAccessScope(this.restricted, this.outletIds, this.tillIds);
  final bool restricted;
  final Set<String> outletIds;
  final Set<String> tillIds;
  bool allowsOutlet(String id) => !restricted || outletIds.contains(id);
  bool allowsTill(String id) => !restricted || tillIds.contains(id);
}

/// An empty explicit projection grants no outlet; never interpret it as all.
final hardwareOutletOptionsProvider =
    FutureProvider<List<OutletOption>>((ref) async {
  final context = await ref.watch(tenantAdminContextProvider.future);
  final options = await ref.watch(tillOutletOptionsProvider.future);
  final hardwareScope = await ref.watch(hardwareAccessScopeProvider.future);
  final allowed = context.accessibleOutletIds.toSet();
  return options
      .where((o) =>
          o.status == 'ACTIVE' &&
          allowed.contains(o.id) &&
          hardwareScope.allowsOutlet(o.id))
      .toList();
});

/// Current user detail is the existing explicit till-scope projection.
/// If access to it is denied/missing, no assignment choices are exposed.
final hardwareAssignableTillsProvider =
    FutureProvider.autoDispose<List<TillMonitoringItem>>((ref) async {
  final context = await ref.watch(tenantAdminContextProvider.future);
  final hardwareScope = await ref.watch(hardwareAccessScopeProvider.future);
  final response = await ref
      .watch(appDioProvider)
      .get('/api/v1/tenant-admin/users/${context.userId}');
  final data = response.data['data'];
  if (data is! Map || !data.containsKey('tillAccessScope')) {
    throw StateError('Explicit till scope is unavailable.');
  }
  final allowedOutlets = context.accessibleOutletIds.toSet();
  final scope = data['tillAccessScope'];
  final selected = <String>{
    if (data['tills'] is List)
      for (final item in data['tills'] as List)
        if (item is Map && (item['tillId'] ?? item['id']) is String)
          (item['tillId'] ?? item['id']) as String,
  };
  final tills = await ref.watch(hardwareTillsProvider.future);
  return tills
      .where((t) =>
          allowedOutlets.contains(t.outletId) &&
          hardwareScope.allowsOutlet(t.outletId) &&
          hardwareScope.allowsTill(t.id) &&
          t.lifecycleStatus == TillLifecycleStatus.active &&
          (scope == 'ALL_ACCESSIBLE_TILLS' ||
              (scope == 'SELECTED_TILLS' && selected.contains(t.id))))
      .toList();
});
