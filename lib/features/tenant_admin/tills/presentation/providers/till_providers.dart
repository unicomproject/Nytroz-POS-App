import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/network/dio_provider.dart';
import '../../application/usecases/create_till.dart';
import '../../application/usecases/delete_till.dart';
import '../../application/usecases/get_till_by_id.dart';
import '../../application/usecases/get_tills.dart';
import '../../application/usecases/get_till_summary.dart';
import '../../application/usecases/get_till_hardware_readiness.dart';
import '../../application/usecases/update_till.dart';
import '../../data/datasources/till_remote_datasource.dart';
import '../../data/repositories/till_repository_impl.dart';
import '../../../presentation/providers/tenant_admin_access_provider.dart';
import '../../domain/entities/till.dart';
import '../../domain/entities/till_create_options.dart';
import '../../domain/entities/till_monitoring.dart';
import '../../domain/entities/till_hardware_readiness.dart';
import '../../domain/repositories/till_repository.dart';
import '../utils/till_list_filters.dart';

final tillRemoteDatasourceProvider = Provider<TillRemoteDatasource>((ref) {
  return TillRemoteDatasource(ref.watch(appDioProvider));
});

final tillRepositoryProvider = Provider<TillRepository>((ref) {
  return TillRepositoryImpl(ref.watch(tillRemoteDatasourceProvider));
});

final getTillsProvider = Provider<GetTills>((ref) {
  return GetTills(ref.watch(tillRepositoryProvider));
});

final getTillSummaryProvider = Provider<GetTillSummary>((ref) {
  return GetTillSummary(ref.watch(tillRepositoryProvider));
});

final getTillHardwareReadinessProvider =
    Provider<GetTillHardwareReadiness>((ref) {
  return GetTillHardwareReadiness(ref.watch(tillRepositoryProvider));
});

final createTillProvider = Provider<CreateTill>((ref) {
  return CreateTill(ref.watch(tillRepositoryProvider));
});

final createTillSetupProvider =
    Provider<Future<CreatedTill> Function(AddTillFormData)>((ref) {
  return (AddTillFormData form) =>
      ref.watch(tillRepositoryProvider).createTillSetup(form);
});

final getTillByIdProvider = Provider<GetTillById>((ref) {
  return GetTillById(ref.watch(tillRepositoryProvider));
});

final updateTillProvider = Provider<UpdateTill>((ref) {
  return UpdateTill(ref.watch(tillRepositoryProvider));
});

final deleteTillProvider = Provider<DeleteTill>((ref) {
  return DeleteTill(ref.watch(tillRepositoryProvider));
});

final tillDetailProvider =
    FutureProvider.autoDispose.family<TillDetail?, String>((ref, tillId) async {
  final accessChecker =
      await ref.watch(tenantAdminAccessCheckerProvider.future);

  if (!accessChecker.canAccessTillModule()) {
    return null;
  }

  return ref.watch(getTillByIdProvider).call(tillId);
});

final tillOutletOptionsProvider = FutureProvider<List<OutletOption>>((ref) {
  return ref.watch(tillRepositoryProvider).getOutletOptions();
});

final tillSearchProvider = StateProvider<String>((ref) => '');

final tillStatusFilterProvider =
    StateProvider<TillStatusFilter>((ref) => TillStatusFilter.all);

final tillPageProvider = StateProvider<int>((ref) => 1);

final tillPageSizeProvider = StateProvider<int>((ref) => 10);

final tillSortByProvider = StateProvider<String>((ref) => 'name');

final tillSortDirectionProvider = StateProvider<String>((ref) => 'asc');

final tillListQueryProvider = Provider<TillListQuery>((ref) {
  final search = ref.watch(tillSearchProvider);
  final statusFilter = ref.watch(tillStatusFilterProvider);
  final page = ref.watch(tillPageProvider);
  final pageSize = ref.watch(tillPageSizeProvider);
  final sortBy = ref.watch(tillSortByProvider);
  final sortDirection = ref.watch(tillSortDirectionProvider);

  return TillListQuery(
    search: search,
    page: page,
    pageSize: pageSize,
    status: statusFilter.apiStatus,
    sortBy: sortBy,
    sortDirection: sortDirection,
  );
});

final tillSummaryFutureProvider =
    FutureProvider.autoDispose<TillMonitoringSummary?>((ref) async {
  final accessChecker =
      await ref.watch(tenantAdminAccessCheckerProvider.future);
  if (!accessChecker.canAccessTillModule()) {
    return null;
  }
  return ref.watch(getTillSummaryProvider).call();
});

final tillListResultFutureProvider =
    FutureProvider.autoDispose<TillMonitoringResult?>((ref) async {
  final accessChecker =
      await ref.watch(tenantAdminAccessCheckerProvider.future);
  if (!accessChecker.canAccessTillModule()) {
    return null;
  }
  final query = ref.watch(tillListQueryProvider);
  return ref.watch(getTillsProvider).call(query: query);
});

final selectedTillIdProvider = StateProvider<String?>((ref) => null);

final tillHardwareReadinessFutureProvider = FutureProvider.autoDispose
    .family<TillHardwareReadiness?, String>((ref, tillId) async {
  final accessChecker =
      await ref.watch(tenantAdminAccessCheckerProvider.future);
  if (!accessChecker.canAccessTillModule()) {
    return null;
  }
  // Hardware readiness requires tenant.hardware.view (or manage).
  // Avoid unauthorized calls; the side panel falls back to list data.
  if (!accessChecker.canViewTillHardware()) {
    return null;
  }
  return ref.watch(getTillHardwareReadinessProvider).call(tillId);
});

final tillCreateOptionsProvider = FutureProvider.autoDispose
    .family<TillCreateOptions?, String?>((ref, outletId) async {
  final accessChecker =
      await ref.watch(tenantAdminAccessCheckerProvider.future);
  if (!accessChecker.canAccessTillModule()) {
    return null;
  }
  return ref.watch(tillRepositoryProvider).getCreateOptions(outletId: outletId);
});
