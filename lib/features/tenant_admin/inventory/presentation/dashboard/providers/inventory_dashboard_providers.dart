import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../core/network/dio_provider.dart';
import '../../../data/mock/inventory_frontend_mock.dart';
import '../../../data/models/inventory_dashboard_models.dart';
import '../../../data/repositories/inventory_repository_impl.dart';
import '../../../data/datasources/inventory_remote_datasource.dart';
import '../../../domain/repositories/i_inventory_repository.dart';

// --- Core Providers ---

final inventoryRemoteDatasourceProvider =
    Provider<InventoryRemoteDatasource>((ref) {
  return InventoryRemoteDatasource(ref.watch(appDioProvider));
});

final inventoryRepositoryProvider = Provider<IInventoryRepository>((ref) {
  return InventoryRepositoryImpl(ref.watch(inventoryRemoteDatasourceProvider));
});

// --- State Providers ---

// Tracks the selected outlet ID for the inventory dashboard (null means across all authorized outlets)
final inventoryDashboardOutletIdProvider =
    StateProvider<String?>((ref) => null);

// Metrics
final inventoryDashboardMetricsProvider =
    FutureProvider.autoDispose<InventoryDashboardMetricsDto>((ref) {
  if (ref.watch(inventoryFrontendMockEnabledProvider)) {
    return InventoryFrontendMock.metrics;
  }
  final outletId = ref.watch(inventoryDashboardOutletIdProvider);
  final repository = ref.watch(inventoryRepositoryProvider);

  return repository.getDashboardMetrics(outletId: outletId);
});

// Alerts
final inventoryDashboardAlertsProvider =
    FutureProvider.autoDispose<InventoryDashboardAlertsResponseDto>((ref) {
  if (ref.watch(inventoryFrontendMockEnabledProvider)) {
    return InventoryFrontendMock.alerts;
  }
  final outletId = ref.watch(inventoryDashboardOutletIdProvider);
  final repository = ref.watch(inventoryRepositoryProvider);

  return repository.getDashboardAlerts(outletId: outletId);
});

// Activities
final inventoryDashboardActivitiesProvider =
    FutureProvider.autoDispose<InventoryDashboardActivitiesResponseDto>((ref) {
  if (ref.watch(inventoryFrontendMockEnabledProvider)) {
    return InventoryFrontendMock.activities;
  }
  final outletId = ref.watch(inventoryDashboardOutletIdProvider);
  final repository = ref.watch(inventoryRepositoryProvider);

  return repository.getDashboardActivities(outletId: outletId);
});
