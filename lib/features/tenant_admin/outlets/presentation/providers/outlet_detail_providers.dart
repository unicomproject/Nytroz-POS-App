import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/outlet_detail_entities.dart';
import 'outlet_providers.dart';

final outletDetailProvider =
    FutureProvider.family<OutletDetail, String>((ref, id) {
  return ref.watch(outletRepositoryProvider).getOutletDetail(id);
});

final outletRevenueSummaryProvider =
    FutureProvider.family<OutletRevenueSummary, String>((ref, id) {
  return ref.watch(outletRepositoryProvider).getOutletRevenueSummary(id);
});

final outletAssignedUsersProvider =
    FutureProvider.family<OutletAssignedUsersResult, String>((ref, id) {
  return ref.watch(outletRepositoryProvider).getOutletAssignedUsers(id);
});

final outletTillsDetailProvider =
    FutureProvider.family<OutletTillsDetailResult, String>((ref, id) {
  return ref.watch(outletRepositoryProvider).getOutletTillsDetail(id);
});
