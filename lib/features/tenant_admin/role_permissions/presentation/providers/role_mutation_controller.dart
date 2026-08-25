import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dio/dio.dart';

import 'role_permissions_providers.dart';
import 'roles_list_providers.dart';

class RoleMutationState {
  const RoleMutationState({
    required this.isLoading,
    this.error,
    this.message,
  });

  final bool isLoading;
  final String? error;
  final String? message;

  RoleMutationState copyWith({
    bool? isLoading,
    String? error,
    String? message,
    bool clearError = false,
    bool clearMessage = false,
  }) {
    return RoleMutationState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      message: clearMessage ? null : message ?? this.message,
    );
  }
}

class RoleMutationController extends AutoDisposeNotifier<RoleMutationState> {
  @override
  RoleMutationState build() {
    return const RoleMutationState(isLoading: false);
  }

  Future<bool> updateRole(
    String roleId,
    String roleName,
    String? description,
    String roleCode,
    DateTime? expectedUpdatedAt,
  ) async {
    state = state.copyWith(isLoading: true, clearError: true, clearMessage: true);
    try {
      final repo = ref.read(rolePermissionRepositoryProvider);
      await repo.updateRole(roleId, roleName, description, roleCode, expectedUpdatedAt);
      state = state.copyWith(isLoading: false, message: 'Role updated successfully.');
      ref.invalidate(rolesListProvider);
      return true;
    } catch (e) {
      _handleError(e);
      return false;
    }
  }

  Future<bool> updateRoleStatus(
    String roleId,
    bool isActive,
    DateTime? expectedUpdatedAt,
  ) async {
    state = state.copyWith(isLoading: true, clearError: true, clearMessage: true);
    try {
      final repo = ref.read(rolePermissionRepositoryProvider);
      await repo.updateRoleStatus(roleId, isActive, expectedUpdatedAt);
      state = state.copyWith(isLoading: false, message: 'Role status updated successfully.');
      ref.invalidate(rolesListProvider);
      return true;
    } catch (e) {
      _handleError(e);
      return false;
    }
  }

  Future<bool> deleteRole(String roleId, DateTime? expectedUpdatedAt) async {
    state = state.copyWith(isLoading: true, clearError: true, clearMessage: true);
    try {
      final repo = ref.read(rolePermissionRepositoryProvider);
      await repo.deleteRole(roleId, expectedUpdatedAt);
      state = state.copyWith(isLoading: false, message: 'Role deleted successfully.');
      ref.invalidate(rolesListProvider);
      return true;
    } catch (e) {
      _handleError(e);
      return false;
    }
  }

  void _handleError(Object e) {
    if (e is DioException && e.response?.data is Map) {
      final data = e.response!.data as Map;
      final message = data['message']?.toString() ?? e.toString();
      state = state.copyWith(isLoading: false, error: message);
    } else {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final roleMutationControllerProvider = NotifierProvider.autoDispose<RoleMutationController, RoleMutationState>(
  RoleMutationController.new,
);
