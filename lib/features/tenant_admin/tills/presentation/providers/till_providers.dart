import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/network/dio_provider.dart';
import '../../application/usecases/create_till.dart';
import '../../application/usecases/get_tills.dart';
import '../../data/datasources/till_remote_datasource.dart';
import '../../data/repositories/till_repository_impl.dart';
import '../../domain/entities/till.dart';
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

final createTillProvider = Provider<CreateTill>((ref) {
  return CreateTill(ref.watch(tillRepositoryProvider));
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
