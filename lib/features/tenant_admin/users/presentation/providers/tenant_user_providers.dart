import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/network/dio_provider.dart';
import '../../application/usecases/create_user.dart';
import '../../application/usecases/delete_user.dart';
import '../../application/usecases/get_user_create_options.dart';
import '../../application/usecases/get_user_detail.dart';
import '../../application/usecases/get_users.dart';
import '../../application/usecases/update_user.dart';
import '../../data/datasources/tenant_user_remote_datasource.dart';
import '../../data/repositories/tenant_user_repository_impl.dart';
import '../../domain/entities/tenant_user.dart';
import '../../domain/repositories/tenant_user_repository.dart';
import '../utils/user_list_filters.dart';

final tenantUserRemoteDatasourceProvider =
    Provider<TenantUserRemoteDatasource>((ref) {
  return TenantUserRemoteDatasource(ref.watch(appDioProvider));
});

final tenantUserRepositoryProvider = Provider<TenantUserRepository>((ref) {
  return TenantUserRepositoryImpl(
      ref.watch(tenantUserRemoteDatasourceProvider));
});

final getUsersProvider = Provider<GetUsers>((ref) {
  return GetUsers(ref.watch(tenantUserRepositoryProvider));
});

final getUserCreateOptionsUseCaseProvider =
    Provider<GetUserCreateOptions>((ref) {
  return GetUserCreateOptions(ref.watch(tenantUserRepositoryProvider));
});

final createUserProvider = Provider<CreateUser>((ref) {
  return CreateUser(ref.watch(tenantUserRepositoryProvider));
});

final getUserDetailProvider = Provider<GetUserDetail>((ref) {
  return GetUserDetail(ref.watch(tenantUserRepositoryProvider));
});

final updateUserProvider = Provider<UpdateUser>((ref) {
  return UpdateUser(ref.watch(tenantUserRepositoryProvider));
});

final deleteUserProvider = Provider<DeleteUser>((ref) {
  return DeleteUser(ref.watch(tenantUserRepositoryProvider));
});

final userCreateOptionsProvider =
    FutureProvider.autoDispose<TenantUserCreateOptions>((ref) {
  return ref.watch(getUserCreateOptionsUseCaseProvider).call();
});

final userDetailProvider =
    FutureProvider.autoDispose.family<TenantUserDetail, String>((ref, id) {
  return ref.watch(getUserDetailProvider).call(id);
});

final userSearchProvider = StateProvider<String>((ref) => '');

final userStatusFilterProvider =
    StateProvider<UserStatusFilter>((ref) => UserStatusFilter.all);

final userPageProvider = StateProvider<int>((ref) => 1);

final userPageSizeProvider = StateProvider<int>((ref) => 10);

final userSortByProvider = StateProvider<String>((ref) => 'name');

final userSortDirectionProvider = StateProvider<String>((ref) => 'asc');

final userListQueryProvider = Provider<TenantUserListQuery>((ref) {
  final search = ref.watch(userSearchProvider);
  final statusFilter = ref.watch(userStatusFilterProvider);
  final page = ref.watch(userPageProvider);
  final pageSize = ref.watch(userPageSizeProvider);
  final sortBy = ref.watch(userSortByProvider);
  final sortDirection = ref.watch(userSortDirectionProvider);

  return TenantUserListQuery(
    search: search,
    page: page,
    pageSize: pageSize,
    status: statusFilter.apiStatus,
    sortBy: sortBy,
    sortDirection: sortDirection,
  );
});
