import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/access/tenant_admin_access_codes.dart';
import '../../../../../core/network/dio_provider.dart';
import '../../../../auth/presentation/providers/session_provider.dart';
import '../../../presentation/providers/tenant_admin_access_provider.dart';
import '../../../presentation/providers/tenant_admin_context_provider.dart';
import '../../application/usecases/get_permission_catalog.dart';
import '../../application/usecases/get_role_permissions.dart';
import '../../application/usecases/update_role_permissions.dart';
import '../../data/datasources/role_permission_remote_datasource.dart';
import '../../data/repositories/role_permission_repository_impl.dart';
import '../../domain/entities/permission_catalog.dart';
import '../../domain/entities/role_permissions.dart';
import '../../domain/repositories/role_permission_repository.dart';

final rolePermissionRemoteDatasourceProvider =
    Provider<RolePermissionRemoteDatasource>((ref) {
  return RolePermissionRemoteDatasource(ref.watch(appDioProvider));
});

final rolePermissionRepositoryProvider = Provider<RolePermissionRepository>((ref) {
  return RolePermissionRepositoryImpl(
    ref.watch(rolePermissionRemoteDatasourceProvider),
  );
});

final getPermissionCatalogProvider = Provider<GetPermissionCatalog>((ref) {
  return GetPermissionCatalog(ref.watch(rolePermissionRepositoryProvider));
});

final getRolePermissionsProvider = Provider<GetRolePermissions>((ref) {
  return GetRolePermissions(ref.watch(rolePermissionRepositoryProvider));
});

final updateRolePermissionsProvider = Provider<UpdateRolePermissions>((ref) {
  return UpdateRolePermissions(ref.watch(rolePermissionRepositoryProvider));
});

class RolePermissionsData {
  const RolePermissionsData({
    required this.catalog,
    required this.rolePermissions,
  });

  final PermissionCatalog catalog;
  final RolePermissions rolePermissions;
}

final rolePermissionsDataProvider =
    FutureProvider.autoDispose.family<RolePermissionsData, String>((ref, roleId) async {
  ref.watch(authHeaderSyncProvider);

  final catalog = await ref.watch(getPermissionCatalogProvider)();
  final rolePermissions =
      await ref.watch(getRolePermissionsProvider)(roleId);

  return RolePermissionsData(
    catalog: catalog,
    rolePermissions: rolePermissions,
  );
});

class RolePermissionsUiState {
  const RolePermissionsUiState({
    required this.selectedCodes,
    required this.searchQuery,
    required this.scopeFilter,
    required this.moduleFilter,
    required this.isSaving,
    this.saveMessage,
    this.saveError,
    this.initializedForRoleId,
  });

  const RolePermissionsUiState.initial()
      : selectedCodes = const {},
        searchQuery = '',
        scopeFilter = '',
        moduleFilter = null,
        isSaving = false,
        saveMessage = null,
        saveError = null,
        initializedForRoleId = null;

  final Set<String> selectedCodes;
  final String searchQuery;
  final String scopeFilter;
  final String? moduleFilter;
  final bool isSaving;
  final String? saveMessage;
  final String? saveError;
  final String? initializedForRoleId;

  bool get hasChanges => initializedForRoleId != null;

  RolePermissionsUiState copyWith({
    Set<String>? selectedCodes,
    String? searchQuery,
    String? scopeFilter,
    String? moduleFilter,
    bool clearModuleFilter = false,
    bool? isSaving,
    String? saveMessage,
    String? saveError,
    bool clearSaveMessage = false,
    bool clearSaveError = false,
    String? initializedForRoleId,
  }) {
    return RolePermissionsUiState(
      selectedCodes: selectedCodes ?? this.selectedCodes,
      searchQuery: searchQuery ?? this.searchQuery,
      scopeFilter: scopeFilter ?? this.scopeFilter,
      moduleFilter:
          clearModuleFilter ? null : moduleFilter ?? this.moduleFilter,
      isSaving: isSaving ?? this.isSaving,
      saveMessage: clearSaveMessage ? null : saveMessage ?? this.saveMessage,
      saveError: clearSaveError ? null : saveError ?? this.saveError,
      initializedForRoleId: initializedForRoleId ?? this.initializedForRoleId,
    );
  }
}

class RolePermissionsUiController extends AutoDisposeFamilyNotifier<
    RolePermissionsUiState, String> {
  @override
  RolePermissionsUiState build(String roleId) {
    return const RolePermissionsUiState.initial();
  }

  void initializeFromRolePermissions(RolePermissions rolePermissions) {
    if (state.initializedForRoleId == rolePermissions.roleId) {
      return;
    }

    state = RolePermissionsUiState(
      selectedCodes: rolePermissions.assignedPermissionCodes.toSet(),
      searchQuery: '',
      scopeFilter: '',
      moduleFilter: null,
      isSaving: false,
      initializedForRoleId: rolePermissions.roleId,
    );
  }

  void setSearchQuery(String value) {
    state = state.copyWith(searchQuery: value);
  }

  void setScopeFilter(String value) {
    state = state.copyWith(scopeFilter: value);
  }

  void setModuleFilter(String? value) {
    state = state.copyWith(
      moduleFilter: value,
      clearModuleFilter: value == null || value.isEmpty,
    );
  }

  void togglePermission(String code) {
    final next = Set<String>.from(state.selectedCodes);
    if (next.contains(code)) {
      next.remove(code);
    } else {
      next.add(code);
    }

    state = state.copyWith(
      selectedCodes: next,
      clearSaveMessage: true,
      clearSaveError: true,
    );
  }

  Future<void> save(String roleId) async {
    if (state.isSaving) {
      return;
    }

    state = state.copyWith(
      isSaving: true,
      clearSaveMessage: true,
      clearSaveError: true,
    );

    try {
      final updated = await ref.read(updateRolePermissionsProvider)(
        roleId,
        UpdateRolePermissionsRequest(
          permissionCodes: state.selectedCodes.toList(growable: false)..sort(),
        ),
      );

      state = state.copyWith(
        selectedCodes: updated.assignedPermissionCodes.toSet(),
        isSaving: false,
        saveMessage: 'Role permissions saved.',
        initializedForRoleId: updated.roleId,
      );

      ref.invalidate(rolePermissionsDataProvider(roleId));
    } catch (error) {
      state = state.copyWith(
        isSaving: false,
        saveError: error.toString(),
      );
    }
  }
}

final rolePermissionsUiControllerProvider = NotifierProvider.autoDispose
    .family<RolePermissionsUiController, RolePermissionsUiState, String>(
  RolePermissionsUiController.new,
);

final rolePermissionsSelectedRoleIdProvider =
    StateProvider.autoDispose<String?>((ref) => null);

final rolePermissionsAvailableRolesProvider =
    Provider.autoDispose<List<TenantAdminRoleOption>>((ref) {
  final context = ref.watch(tenantAdminContextProvider).valueOrNull;
  if (context == null) {
    return const [];
  }

  return context.roles
      .where((role) => role.id.isNotEmpty)
      .map((role) => TenantAdminRoleOption(id: role.id, name: role.name))
      .toList(growable: false);
});

class TenantAdminRoleOption {
  const TenantAdminRoleOption({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;
}

final rolePermissionsCanViewProvider = Provider<bool>((ref) {
  final access = ref.watch(tenantAdminAccessCheckerProvider).valueOrNull;
  return access?.can(TenantAdminPermissionCodes.rolesPermissionsView) ?? false;
});

final rolePermissionsCanUpdateProvider = Provider<bool>((ref) {
  final access = ref.watch(tenantAdminAccessCheckerProvider).valueOrNull;
  return access?.can(TenantAdminPermissionCodes.rolesPermissionsUpdate) ?? false;
});
