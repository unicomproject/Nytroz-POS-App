import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/tenant_admin_context_provider.dart';
import '../../data/datasources/outlet_remote_datasource.dart';
import '../../data/repositories/outlet_repository_impl.dart';
import '../../domain/entities/outlet.dart';
import '../../domain/entities/outlet_details.dart';
import '../../domain/repositories/outlet_repository.dart';
import '../../domain/usecases/create_outlet.dart';
import '../../domain/usecases/get_outlet_details.dart';
import '../../domain/usecases/get_outlets.dart';
import '../../domain/usecases/update_outlet.dart';

final outletRemoteDatasourceProvider = Provider<OutletRemoteDatasource>((ref) {
  return OutletRemoteDatasource(ref.watch(tenantAdminDioProvider));
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

final outletSearchProvider = StateProvider<String>((ref) => '');

final outletListProvider = FutureProvider<OutletListResult>((ref) {
  final search = ref.watch(outletSearchProvider);
  return ref.watch(getOutletsProvider).call(search: search);
});

final outletDetailsProvider =
    FutureProvider.family<OutletDetails, String>((ref, id) {
  return ref.watch(getOutletDetailsProvider).call(id);
});

final outletManagersProvider =
    FutureProvider<List<OutletManagerOption>>((ref) async {
  return ref.watch(outletRepositoryProvider).getManagerOptions();
});
