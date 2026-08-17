import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dio/dio.dart';

import '../../domain/entities/role_assignment.dart';
import '../../domain/entities/role_permissions.dart';
import '../providers/role_details_provider.dart';
import '../providers/role_permissions_providers.dart';
import '../providers/roles_list_providers.dart';

class EditRoleState {
  const EditRoleState({
    this.roleName = '',
    this.description = '',
    this.roleCode = '',
    this.selectedPermissionCodes = const {},
    this.assignments = const [],
    this.isSaving = false,
    this.error,
    this.isInitialized = false,
  });

  final String roleName;
  final String description;
  final String roleCode;
  final Set<String> selectedPermissionCodes;
  final List<RoleAssignment> assignments;
  final bool isSaving;
  final String? error;
  final bool isInitialized;

  EditRoleState copyWith({
    String? roleName,
    String? description,
    String? roleCode,
    Set<String>? selectedPermissionCodes,
    List<RoleAssignment>? assignments,
    bool? isSaving,
    String? error,
    bool clearError = false,
    bool? isInitialized,
  }) {
    return EditRoleState(
      roleName: roleName ?? this.roleName,
      description: description ?? this.description,
      roleCode: roleCode ?? this.roleCode,
      selectedPermissionCodes: selectedPermissionCodes ?? this.selectedPermissionCodes,
      assignments: assignments ?? this.assignments,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : error ?? this.error,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

class EditRoleController extends AutoDisposeFamilyNotifier<EditRoleState, String> {
  @override
  EditRoleState build(String arg) {
    _initialize(arg);
    return const EditRoleState();
  }

  Future<void> _initialize(String roleId) async {
    try {
      final repo = ref.read(rolePermissionRepositoryProvider);
      
      final roleDetails = await repo.getRoleById(roleId);
      final permissions = await ref.read(getRolePermissionsProvider)(roleId);
      final assignments = await repo.getRoleAssignments(roleId);

      state = state.copyWith(
        roleName: roleDetails.name,
        description: roleDetails.description ?? '',
        roleCode: roleDetails.templateCode,
        selectedPermissionCodes: permissions.assignedPermissionCodes.toSet(),
        assignments: assignments,
        isInitialized: true,
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to initialize edit screen: $e');
    }
  }

  void updateGeneralDetails({String? name, String? description, String? code}) {
    state = state.copyWith(
      roleName: name,
      description: description,
      roleCode: code,
      clearError: true,
    );
  }

  void togglePermission(String code) {
    final next = Set<String>.from(state.selectedPermissionCodes);
    if (next.contains(code)) {
      next.remove(code);
    } else {
      next.add(code);
    }
    state = state.copyWith(selectedPermissionCodes: next, clearError: true);
  }

  void updateAssignments(List<RoleAssignment> newAssignments) {
    state = state.copyWith(assignments: newAssignments, clearError: true);
  }

  Future<bool> save(String roleId) async {
    if (state.isSaving) return false;
    
    state = state.copyWith(isSaving: true, clearError: true);
    
    try {
      final repo = ref.read(rolePermissionRepositoryProvider);
      
      // 1. Update general details
      await repo.updateRole(
        roleId,
        state.roleName,
        state.description,
        state.roleCode,
        null, // Ignoring concurrency check for simplicity in this implementation if needed, but should use expectedUpdatedAt ideally.
      );

      // 2. Update permissions
      await ref.read(updateRolePermissionsProvider)(
        roleId,
        UpdateRolePermissionsRequest(
          permissionCodes: state.selectedPermissionCodes.toList(growable: false)..sort(),
        ),
      );

      // 3. Update assignments
      await repo.updateRoleAssignments(roleId, state.assignments);

      state = state.copyWith(isSaving: false);
      ref.invalidate(rolesListProvider);
      ref.invalidate(roleDetailsProvider(roleId));
      return true;
    } catch (e) {
      if (e is DioException && e.response?.data is Map) {
        final data = e.response!.data as Map;
        final message = data['message']?.toString() ?? e.toString();
        state = state.copyWith(isSaving: false, error: message);
      } else {
        state = state.copyWith(isSaving: false, error: e.toString());
      }
      return false;
    }
  }
}

final editRoleControllerProvider = NotifierProvider.autoDispose.family<EditRoleController, EditRoleState, String>(
  EditRoleController.new,
);
