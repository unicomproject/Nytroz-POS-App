import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/network/dio_provider.dart';
import '../../application/usecases/create_outlet.dart';
import '../../application/usecases/delete_outlet.dart';
import '../../application/usecases/get_outlet_details.dart';
import '../../application/usecases/get_outlets.dart';
import '../../application/usecases/update_outlet.dart';
import '../../application/usecases/upload_outlet_image.dart';
import '../../application/usecases/delete_staged_outlet_image.dart';
import '../../data/datasources/outlet_remote_datasource.dart';
import '../../data/repositories/outlet_repository_impl.dart';
import '../../domain/entities/outlet.dart';
import '../../domain/entities/outlet_create_options.dart';
import '../../domain/entities/outlet_details.dart';
import '../../domain/entities/outlet_list_query.dart';
import '../../domain/repositories/outlet_repository.dart';
import '../utils/outlet_list_filters.dart';

final outletRemoteDatasourceProvider = Provider<OutletRemoteDatasource>((ref) {
  return OutletRemoteDatasource(ref.watch(appDioProvider));
});

final outletRepositoryProvider = Provider<OutletRepository>((ref) {
  return OutletRepositoryImpl(ref.watch(outletRemoteDatasourceProvider));
});

final getOutletsProvider = Provider<GetOutlets>((ref) {
  return GetOutlets(ref.watch(outletRepositoryProvider));
});

final getOutletDetailsProvider = Provider<GetOutletDetails>((ref) {
  return GetOutletDetails(ref.watch(outletRepositoryProvider));
});

final createOutletProvider = Provider<CreateOutlet>((ref) {
  return CreateOutlet(ref.watch(outletRepositoryProvider));
});

final updateOutletProvider = Provider<UpdateOutlet>((ref) {
  return UpdateOutlet(ref.watch(outletRepositoryProvider));
});

final deleteOutletProvider = Provider<DeleteOutlet>((ref) {
  return DeleteOutlet(ref.watch(outletRepositoryProvider));
});

final uploadOutletImageProvider = Provider<UploadOutletImage>((ref) {
  return UploadOutletImage(ref.watch(outletRepositoryProvider));
});

final deleteStagedOutletImageProvider =
    Provider<DeleteStagedOutletImage>((ref) {
  return DeleteStagedOutletImage(ref.watch(outletRepositoryProvider));
});

final outletSearchProvider = StateProvider<String>((ref) => '');

final outletStatusFilterProvider =
    StateProvider<OutletStatusFilter>((ref) => OutletStatusFilter.all);

final outletTypeFilterProvider =
    StateProvider<OutletTypeFilter>((ref) => OutletTypeFilter.all);

final outletPageProvider = StateProvider<int>((ref) => 1);

final outletPageSizeProvider = StateProvider<int>((ref) => 10);

final outletSortByProvider = StateProvider<String>((ref) => 'name');

final outletSortDirectionProvider = StateProvider<String>((ref) => 'asc');

final outletDetailsProvider =
    FutureProvider.family<OutletDetails, String>((ref, id) {
  return ref.watch(getOutletDetailsProvider).call(id);
});

final outletSummaryDashboardProvider =
    FutureProvider<OutletSummaryDashboard>((ref) async {
  return ref.watch(outletRepositoryProvider).getSummary();
});

final outletManagersProvider =
    FutureProvider<List<OutletManagerOption>>((ref) async {
  return ref.watch(outletRepositoryProvider).getManagerOptions();
});

final outletCreateOptionsProvider = FutureProvider<OutletCreateOptions>((ref) {
  return ref.watch(outletRepositoryProvider).getCreateOptions();
});

final outletListQueryProvider = Provider<OutletListQuery>((ref) {
  final search = ref.watch(outletSearchProvider);
  final statusFilter = ref.watch(outletStatusFilterProvider);
  final typeFilter = ref.watch(outletTypeFilterProvider);
  final page = ref.watch(outletPageProvider);
  final pageSize = ref.watch(outletPageSizeProvider);
  final sortBy = ref.watch(outletSortByProvider);
  final sortDirection = ref.watch(outletSortDirectionProvider);

  return OutletListQuery(
    search: search,
    page: page,
    pageSize: pageSize,
    status: statusFilter.apiStatus,
    outletType: typeFilter.apiType,
    sortBy: sortBy,
    sortDirection: sortDirection,
  );
});
