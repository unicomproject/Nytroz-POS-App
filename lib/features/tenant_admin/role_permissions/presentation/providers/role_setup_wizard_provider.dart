import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/role_assignment.dart';
import 'role_permissions_providers.dart';

class RoleSetupWizardState {
  const RoleSetupWizardState({
    required this.currentStep,
    required this.selectedTemplateCode,
    this.roleId,
    this.roleName,
    this.roleDescription,
    required this.selectedModules,
    required this.selectedPermissionCodes,
    required this.assignments,
    required this.selectedUserIds,
    required this.accessScopeType,
    required this.selectedOutletIds,
    required this.isSaving,
    this.errorMessage,
  });

  const RoleSetupWizardState.initial()
      : currentStep = 1,
        selectedTemplateCode = '',
        roleId = null,
        roleName = null,
        roleDescription = null,
        selectedModules = const {},
        selectedPermissionCodes = const {},
        assignments = const [],
        selectedUserIds = const {},
        accessScopeType = RoleAccessScopeType.tenantWide,
        selectedOutletIds = const {},
        isSaving = false,
        errorMessage = null;

  final int currentStep;
  final String selectedTemplateCode;
  final String? roleId;
  final String? roleName;
  final String? roleDescription;
  final Set<String> selectedModules;
  final Set<String> selectedPermissionCodes;
  final List<RoleAssignment> assignments;
  final Set<String> selectedUserIds;
  final RoleAccessScopeType accessScopeType;
  final Set<String> selectedOutletIds;
  final bool isSaving;
  final String? errorMessage;

  bool get isDirty =>
      selectedTemplateCode.isNotEmpty ||
      selectedModules.isNotEmpty ||
      selectedPermissionCodes.isNotEmpty ||
      assignments.isNotEmpty ||
      selectedUserIds.isNotEmpty;

  /// Derive the display name for the selected role template.
  String get resolvedRoleName {
    if (roleName != null && roleName!.isNotEmpty) return roleName!;
    switch (selectedTemplateCode) {
      case 'tenant-admin':
        return 'Tenant Admin';
      case 'super-admin':
        return 'Super Admin';
      case 'cashier':
        return 'Cashier';
      default:
        return 'Custom Role';
    }
  }

  /// Derive a description for the selected role template.
  String get resolvedRoleDescription {
    if (roleDescription != null && roleDescription!.isNotEmpty) {
      return roleDescription!;
    }
    switch (selectedTemplateCode) {
      case 'tenant-admin':
        return 'Full access to manage all modules and settings.';
      case 'super-admin':
        return 'Advanced access with additional system configuration and tenant management.';
      case 'cashier':
        return 'Access to POS operations including sales, orders, customers and till functions.';
      default:
        return 'Custom role with configured permissions.';
    }
  }

  /// Determine role type label.
  String get roleTypeLabel {
    if (selectedTemplateCode == 'tenant-admin' ||
        selectedTemplateCode == 'super-admin' ||
        selectedTemplateCode == 'cashier') {
      return 'System Role';
    }
    return 'Custom Role';
  }

  /// Determine access level based on permission count.
  String get accessLevel {
    if (selectedPermissionCodes.length > 30) return 'High';
    if (selectedPermissionCodes.length > 15) return 'Medium';
    return 'Low';
  }

  RoleSetupWizardState copyWith({
    int? currentStep,
    String? selectedTemplateCode,
    String? roleId,
    String? roleName,
    String? roleDescription,
    Set<String>? selectedModules,
    Set<String>? selectedPermissionCodes,
    List<RoleAssignment>? assignments,
    Set<String>? selectedUserIds,
    RoleAccessScopeType? accessScopeType,
    Set<String>? selectedOutletIds,
    bool? isSaving,
    String? errorMessage,
    bool clearErrorMessage = false,
    bool clearRoleName = false,
    bool clearRoleDescription = false,
  }) {
    return RoleSetupWizardState(
      currentStep: currentStep ?? this.currentStep,
      selectedTemplateCode: selectedTemplateCode ?? this.selectedTemplateCode,
      roleId: roleId ?? this.roleId,
      roleName: clearRoleName ? null : roleName ?? this.roleName,
      roleDescription: clearRoleDescription
          ? null
          : roleDescription ?? this.roleDescription,
      selectedModules: selectedModules ?? this.selectedModules,
      selectedPermissionCodes:
          selectedPermissionCodes ?? this.selectedPermissionCodes,
      assignments: assignments ?? this.assignments,
      selectedUserIds: selectedUserIds ?? this.selectedUserIds,
      accessScopeType: accessScopeType ?? this.accessScopeType,
      selectedOutletIds: selectedOutletIds ?? this.selectedOutletIds,
      isSaving: isSaving ?? this.isSaving,
      errorMessage:
          clearErrorMessage ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class RoleSetupWizardController extends Notifier<RoleSetupWizardState> {
  @override
  RoleSetupWizardState build() {
    return const RoleSetupWizardState.initial();
  }

  void nextStep() {
    if (state.currentStep < 5) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  void previousStep() {
    if (state.currentStep > 1) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  void goToStep(int step) {
    if (step >= 1 && step <= 5) {
      state = state.copyWith(currentStep: step);
    }
  }

  void selectTemplate(String templateCode) {
    String? defaultName;
    String? defaultDesc;
    switch (templateCode) {
      case 'tenant-admin':
        defaultName = 'Custom Tenant Admin';
        defaultDesc = 'Full access to manage outlets, users, roles, products, inventory, reports and settings.';
        break;
      case 'super-admin':
        defaultName = 'Custom Super Admin';
        defaultDesc = 'Advanced access with additional system configuration and tenant management.';
        break;
      case 'cashier':
        defaultName = 'Custom Cashier';
        defaultDesc = 'Access to POS operations including sales, orders, customers and till functions.';
        break;
    }
    state = state.copyWith(
      selectedTemplateCode: templateCode,
      roleName: defaultName,
      roleDescription: defaultDesc,
    );
  }

  void setRoleName(String name) {
    state = state.copyWith(roleName: name);
  }

  void setRoleDescription(String description) {
    state = state.copyWith(roleDescription: description);
  }

  void toggleModule(String moduleCode) {
    final modules = Set<String>.from(state.selectedModules);
    if (modules.contains(moduleCode)) {
      modules.remove(moduleCode);
    } else {
      modules.add(moduleCode);
    }
    state = state.copyWith(selectedModules: modules);
  }

  void togglePermission(String permissionCode) {
    final permissions = Set<String>.from(state.selectedPermissionCodes);
    if (permissions.contains(permissionCode)) {
      permissions.remove(permissionCode);
    } else {
      permissions.add(permissionCode);
    }
    state = state.copyWith(selectedPermissionCodes: permissions);
  }

  // ── User selection (Step 4) ──────────────────────────────────────────

  void toggleUser(String userId) {
    final users = Set<String>.from(state.selectedUserIds);
    if (users.contains(userId)) {
      users.remove(userId);
    } else {
      users.add(userId);
    }
    state = state.copyWith(selectedUserIds: users);
  }

  void clearAllUsers() {
    state = state.copyWith(selectedUserIds: const {});
  }

  // ── Access scope (Step 4) ────────────────────────────────────────────

  void setAccessScope(RoleAccessScopeType scope) {
    state = state.copyWith(accessScopeType: scope);
  }

  void toggleOutlet(String outletId) {
    final outlets = Set<String>.from(state.selectedOutletIds);
    if (outlets.contains(outletId)) {
      outlets.remove(outletId);
    } else {
      outlets.add(outletId);
    }
    state = state.copyWith(selectedOutletIds: outlets);
  }

  // ── Assignments (legacy compat) ──────────────────────────────────────

  void updateAssignment(RoleAssignment assignment) {
    final assignments = List<RoleAssignment>.from(state.assignments);
    final index = assignments
        .indexWhere((element) => element.userId == assignment.userId);
    if (index >= 0) {
      assignments[index] = assignment;
    } else {
      assignments.add(assignment);
    }
    state = state.copyWith(assignments: assignments);
  }

  void removeAssignment(String userId) {
    final assignments = List<RoleAssignment>.from(state.assignments);
    assignments.removeWhere((element) => element.userId == userId);
    state = state.copyWith(assignments: assignments);
  }

  /// Build final assignments list from selected users + scope.
  List<RoleAssignment> buildFinalAssignments() {
    return state.selectedUserIds.map((userId) {
      return RoleAssignment(
        userId: userId,
        scopeType: state.accessScopeType,
        outletIds: state.accessScopeType == RoleAccessScopeType.selectedOutlets
            ? state.selectedOutletIds.toList()
            : const [],
      );
    }).toList();
  }

  Future<bool> saveDraft() async {
    // Draft functionality placeholder
    return true;
  }

  Future<bool> createRole() async {
    state = state.copyWith(isSaving: true, clearErrorMessage: true);

    try {
      final repository = ref.read(rolePermissionRepositoryProvider);

      final roleName = state.resolvedRoleName;

      // Build assignments from the user selection + scope
      final finalAssignments = buildFinalAssignments();

      final role = await repository.createRole(
        roleName,
        state.resolvedRoleDescription,
        state.selectedTemplateCode,
        permissionCodes: state.selectedPermissionCodes.isNotEmpty
            ? state.selectedPermissionCodes.toList()
            : null,
        assignments: finalAssignments.isNotEmpty ? finalAssignments : null,
      );

      final roleId = role.id;

      state = state.copyWith(isSaving: false, roleId: roleId);

      // Invalidate list to refresh UI
      ref.invalidate(rolePermissionsAvailableRolesProvider);
      return true;
    } on DioException catch (e) {
      String msg = 'Failed to create role. Please try again.';
      if (e.response?.data is Map) {
        final data = e.response!.data as Map;
        if (data['title'] != null && data['title'].toString().isNotEmpty) {
          msg = data['title'].toString();
        } else if (data['message'] != null && data['message'].toString().isNotEmpty) {
          msg = data['message'].toString();
        }
      }
      state = state.copyWith(
        isSaving: false,
        errorMessage: msg,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Failed to create role: $e',
      );
      return false;
    }
  }
}

final roleSetupWizardProvider =
    NotifierProvider<RoleSetupWizardController, RoleSetupWizardState>(
  RoleSetupWizardController.new,
);
