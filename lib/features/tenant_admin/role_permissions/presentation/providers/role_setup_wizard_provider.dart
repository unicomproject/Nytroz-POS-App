import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../presentation/providers/tenant_admin_access_provider.dart';
import '../../../presentation/providers/tenant_admin_context_provider.dart';
import '../../../presentation/providers/tenant_admin_menu_provider.dart';
import '../../domain/entities/permission_catalog.dart';
import '../../domain/entities/role_assignment.dart';
import '../../domain/entities/role_setup.dart';
import 'role_permissions_providers.dart';

class RoleSetupWizardState {
  const RoleSetupWizardState({
    required this.currentStep,
    required this.availableRoles,
    required this.catalog,
    required this.selectedModules,
    required this.selectedPermissionCodes,
    required this.assignments,
    required this.isLoading,
    required this.isSaving,
    this.selectedRole,
    this.activeAssignmentUserId,
    this.expectedUpdatedAt,
    this.errorMessage,
    this.errorCode,
    this.successMessage,
  });

  const RoleSetupWizardState.initial()
      : currentStep = 1,
        availableRoles = const [],
        catalog = null,
        selectedRole = null,
        selectedModules = const {},
        selectedPermissionCodes = const {},
        assignments = const [],
        activeAssignmentUserId = null,
        expectedUpdatedAt = null,
        isLoading = false,
        isSaving = false,
        errorMessage = null,
        errorCode = null,
        successMessage = null;

  final int currentStep;
  final List<RoleSetupOption> availableRoles;
  final PermissionCatalog? catalog;
  final RoleSetupOption? selectedRole;
  final Set<String> selectedModules;
  final Set<String> selectedPermissionCodes;
  final List<RoleAssignment> assignments;
  final String? activeAssignmentUserId;
  final DateTime? expectedUpdatedAt;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final String? errorCode;
  final String? successMessage;

  bool get hasSelectedRole => selectedRole != null;

  bool get hasInvalidAssignment => assignments.any(
        (assignment) =>
            assignment.scopeType == RoleAccessScopeType.selectedOutlets &&
            assignment.outletIds.isEmpty,
      );

  RoleAssignment? get activeAssignment {
    final userId = activeAssignmentUserId;
    if (userId == null) return null;
    for (final assignment in assignments) {
      if (assignment.userId == userId) return assignment;
    }
    return null;
  }

  RoleSetupWizardState copyWith({
    int? currentStep,
    List<RoleSetupOption>? availableRoles,
    PermissionCatalog? catalog,
    RoleSetupOption? selectedRole,
    bool clearSelectedRole = false,
    Set<String>? selectedModules,
    Set<String>? selectedPermissionCodes,
    List<RoleAssignment>? assignments,
    String? activeAssignmentUserId,
    bool clearActiveAssignmentUser = false,
    DateTime? expectedUpdatedAt,
    bool clearExpectedUpdatedAt = false,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    String? errorCode,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return RoleSetupWizardState(
      currentStep: currentStep ?? this.currentStep,
      availableRoles: availableRoles ?? this.availableRoles,
      catalog: catalog ?? this.catalog,
      selectedRole:
          clearSelectedRole ? null : selectedRole ?? this.selectedRole,
      selectedModules: selectedModules ?? this.selectedModules,
      selectedPermissionCodes:
          selectedPermissionCodes ?? this.selectedPermissionCodes,
      assignments: assignments ?? this.assignments,
      activeAssignmentUserId: clearActiveAssignmentUser
          ? null
          : activeAssignmentUserId ?? this.activeAssignmentUserId,
      expectedUpdatedAt: clearExpectedUpdatedAt
          ? null
          : expectedUpdatedAt ?? this.expectedUpdatedAt,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      errorCode: clearError ? null : errorCode ?? this.errorCode,
      successMessage:
          clearSuccess ? null : successMessage ?? this.successMessage,
    );
  }
}

class RoleSetupWizardController extends Notifier<RoleSetupWizardState> {
  @override
  RoleSetupWizardState build() => const RoleSetupWizardState.initial();

  Future<void> load() async {
    if (state.isLoading || state.availableRoles.isNotEmpty) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final repository = ref.read(rolePermissionRepositoryProvider);
      final options = await repository.getSetupOptions();
      final catalog = await repository.getPermissionCatalog();
      state = state.copyWith(
        isLoading: false,
        availableRoles: options
            .where(
              (role) => role.code == 'TENANT_ADMIN' || role.code == 'CASHIER',
            )
            .toList(growable: false),
        catalog: catalog,
      );
    } catch (error) {
      _setError(error, fallback: 'Unable to load role setup options.');
    }
  }

  Future<void> selectRole(RoleSetupOption role) async {
    if (!role.isActive || state.isLoading) return;
    state =
        state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    try {
      final repository = ref.read(rolePermissionRepositoryProvider);
      final permissions = await repository.getRolePermissions(role.id);
      final assignments = await repository.getRoleAssignments(role.id);
      final selectedPermissionCodes =
          permissions.assignedPermissionCodes.toSet();
      state = state.copyWith(
        isLoading: false,
        selectedRole: role,
        selectedPermissionCodes: selectedPermissionCodes,
        selectedModules: _modulesForPermissions(selectedPermissionCodes),
        assignments: assignments,
        activeAssignmentUserId:
            assignments.isEmpty ? null : assignments.first.userId,
        expectedUpdatedAt: permissions.updatedAt ?? role.updatedAt,
      );
    } catch (error) {
      _setError(error, fallback: 'Unable to load the selected role access.');
    }
  }

  void nextStep() {
    if (state.currentStep < 5) {
      state =
          state.copyWith(currentStep: state.currentStep + 1, clearError: true);
    }
  }

  void previousStep() {
    if (state.currentStep > 1) {
      state =
          state.copyWith(currentStep: state.currentStep - 1, clearError: true);
    }
  }

  void goToStep(int step) {
    if (step >= 1 && step <= 5) {
      state = state.copyWith(currentStep: step, clearError: true);
    }
  }

  bool canConfigureModule(PermissionCatalogModule module) => module.features
      .expand((feature) => feature.permissions)
      .any((permission) => permission.assignable);

  void toggleModule(String moduleCode) {
    final module = _findModule(moduleCode);
    if (module == null || !canConfigureModule(module)) return;
    final modules = Set<String>.from(state.selectedModules);
    final codes = Set<String>.from(state.selectedPermissionCodes);
    if (modules.remove(moduleCode)) {
      for (final permission
          in module.features.expand((feature) => feature.permissions)) {
        if (permission.assignable) codes.remove(permission.code);
      }
    } else {
      modules.add(moduleCode);
    }
    state = state.copyWith(
      selectedModules: modules,
      selectedPermissionCodes: codes,
      clearError: true,
    );
  }

  void togglePermission(PermissionCatalogPermission permission) {
    if (!permission.assignable) return;
    final codes = Set<String>.from(state.selectedPermissionCodes);
    if (!codes.add(permission.code)) {
      codes.remove(permission.code);
    }
    state = state.copyWith(selectedPermissionCodes: codes, clearError: true);
  }

  void selectAllAssignablePermissions(String moduleCode) {
    final module = _findModule(moduleCode);
    if (module == null) return;
    final codes = Set<String>.from(state.selectedPermissionCodes);
    codes.addAll(
      module.features
          .expand((feature) => feature.permissions)
          .where((permission) => permission.assignable)
          .map((permission) => permission.code),
    );
    state = state.copyWith(selectedPermissionCodes: codes, clearError: true);
  }

  void toggleUser(
    String userId, {
    String? fullName,
    String? email,
  }) {
    final assignments = List<RoleAssignment>.from(state.assignments);
    final index =
        assignments.indexWhere((assignment) => assignment.userId == userId);
    if (index >= 0) {
      assignments.removeAt(index);
      state = state.copyWith(
        assignments: assignments,
        activeAssignmentUserId:
            assignments.isEmpty ? null : assignments.first.userId,
        clearError: true,
      );
      return;
    }
    assignments.add(
      RoleAssignment(
        userId: userId,
        scopeType: RoleAccessScopeType.tenantWide,
        outletIds: const [],
        fullName: fullName,
        email: email,
      ),
    );
    state = state.copyWith(
      assignments: assignments,
      activeAssignmentUserId: userId,
      clearError: true,
    );
  }

  void setActiveAssignmentUser(String userId) {
    if (state.assignments.any((assignment) => assignment.userId == userId)) {
      state = state.copyWith(activeAssignmentUserId: userId);
    }
  }

  void setAssignmentScope(RoleAccessScopeType scope) {
    final active = state.activeAssignment;
    if (active == null) return;
    _replaceAssignment(
      RoleAssignment(
        userId: active.userId,
        scopeType: scope,
        outletIds: scope == RoleAccessScopeType.tenantWide
            ? const []
            : active.outletIds,
        fullName: active.fullName,
        email: active.email,
      ),
    );
  }

  void toggleAssignmentOutlet(String outletId) {
    final active = state.activeAssignment;
    if (active == null ||
        active.scopeType != RoleAccessScopeType.selectedOutlets) {
      return;
    }
    final outletIds = Set<String>.from(active.outletIds);
    if (!outletIds.add(outletId)) {
      outletIds.remove(outletId);
    }
    _replaceAssignment(
      RoleAssignment(
        userId: active.userId,
        scopeType: active.scopeType,
        outletIds: outletIds.toList()..sort(),
        fullName: active.fullName,
        email: active.email,
      ),
    );
  }

  Future<bool> saveRoleAccess() async {
    final role = state.selectedRole;
    if (role == null || state.isSaving) return false;
    if (state.hasInvalidAssignment) {
      state = state.copyWith(
        errorCode: 'tenant_roles.assignment_invalid',
        errorMessage:
            'Select at least one outlet for every outlet-scoped user.',
      );
      return false;
    }

    state =
        state.copyWith(isSaving: true, clearError: true, clearSuccess: true);
    try {
      final result = await ref
          .read(rolePermissionRepositoryProvider)
          .saveRoleSetup(
            role.id,
            SaveRoleSetupRequest(
              permissionCodes: state.selectedPermissionCodes.toList()..sort(),
              assignments: state.assignments,
              expectedUpdatedAt: state.expectedUpdatedAt,
            ),
          );
      state = state.copyWith(
        isSaving: false,
        expectedUpdatedAt: result.updatedAt ?? state.expectedUpdatedAt,
        successMessage: 'Role access saved successfully.',
      );
      ref.invalidate(rolePermissionsAvailableRolesProvider);
      ref.invalidate(tenantAdminContextProvider);
      ref.invalidate(tenantAdminAccessCheckerProvider);
      ref.invalidate(tenantAdminMenuProvider);
      ref.invalidate(rolePermissionsDataProvider(role.id));
      return true;
    } catch (error) {
      _setError(error,
          fallback: 'Unable to save role access. Please try again.');
      return false;
    }
  }

  void reset() => state = const RoleSetupWizardState.initial();

  PermissionCatalogModule? _findModule(String code) {
    for (final module
        in state.catalog?.modules ?? const <PermissionCatalogModule>[]) {
      if (module.code == code) return module;
    }
    return null;
  }

  void _replaceAssignment(RoleAssignment replacement) {
    final assignments = state.assignments
        .map((assignment) =>
            assignment.userId == replacement.userId ? replacement : assignment)
        .toList(growable: false);
    state = state.copyWith(assignments: assignments, clearError: true);
  }

  Set<String> _modulesForPermissions(Set<String> permissionCodes) {
    return (state.catalog?.modules ?? const <PermissionCatalogModule>[])
        .where(
          (module) => module.features
              .expand((feature) => feature.permissions)
              .any((permission) => permissionCodes.contains(permission.code)),
        )
        .map((module) => module.code)
        .toSet();
  }

  void _setError(Object error, {required String fallback}) {
    var message = fallback;
    String? code;
    if (error is DioException && error.response?.data is Map) {
      final data = Map<String, dynamic>.from(error.response!.data as Map);
      final details = data['error'] is Map
          ? Map<String, dynamic>.from(data['error'] as Map)
          : data;
      code = details['code']?.toString() ?? data['code']?.toString();
      message = details['message']?.toString() ??
          data['message']?.toString() ??
          data['title']?.toString() ??
          fallback;
    }
    state = state.copyWith(
      isLoading: false,
      isSaving: false,
      errorCode: code,
      errorMessage: message,
    );
  }
}

final roleSetupWizardProvider =
    NotifierProvider<RoleSetupWizardController, RoleSetupWizardState>(
  RoleSetupWizardController.new,
);
