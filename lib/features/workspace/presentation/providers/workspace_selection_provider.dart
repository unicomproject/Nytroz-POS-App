import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/secure_storage_provider.dart';
import '../../../auth/domain/entities/auth_session.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../domain/workspace_access.dart';

class WorkspaceSelectionState {
  const WorkspaceSelectionState({
    required this.access,
    this.selected,
    this.rememberChoice = false,
    this.isPreferenceLoading = false,
  });

  const WorkspaceSelectionState.none()
      : access = const WorkspaceAccess(
          canAccessTenantAdmin: false,
          canAccessPos: false,
        ),
        selected = null,
        rememberChoice = false,
        isPreferenceLoading = false;

  final WorkspaceAccess access;
  final AppWorkspace? selected;
  final bool rememberChoice;
  final bool isPreferenceLoading;
}

class WorkspaceSelectionNotifier
    extends StateNotifier<WorkspaceSelectionState> {
  WorkspaceSelectionNotifier(this._ref)
      : super(const WorkspaceSelectionState.none()) {
    _ref.listen<AuthSession?>(
      authSessionProvider,
      _onSessionChanged,
      fireImmediately: true,
    );
  }

  final Ref _ref;
  String? _userId;
  int _preferenceLoadId = 0;

  String _preferenceKey(String userId) => 'workspace.preference.$userId';

  void _onSessionChanged(AuthSession? previous, AuthSession? next) {
    if (next == null || !next.isAuthenticated) {
      _userId = null;
      _preferenceLoadId++;
      state = const WorkspaceSelectionState.none();
      return;
    }

    final access = resolveWorkspaceAccess(next.permissionCodes);
    final sameUser = _userId == next.userId;
    final existing =
        sameUser && state.selected != null && access.allows(state.selected!)
            ? state.selected
            : null;

    _userId = next.userId;
    state = WorkspaceSelectionState(
      access: access,
      selected: access.onlyWorkspace ?? existing,
      rememberChoice: sameUser && state.rememberChoice,
      isPreferenceLoading: access.hasMultiple && existing == null,
    );

    if (access.hasMultiple && existing == null) {
      unawaited(_restorePreference(next.userId, access));
    }
  }

  Future<void> _restorePreference(
    String userId,
    WorkspaceAccess access,
  ) async {
    final loadId = ++_preferenceLoadId;
    final value =
        await _ref.read(secureStorageProvider).read(_preferenceKey(userId));
    if (!mounted || loadId != _preferenceLoadId || _userId != userId) return;

    final remembered = switch (value) {
      'tenantAdmin' => AppWorkspace.tenantAdmin,
      'pos' => AppWorkspace.pos,
      _ => null,
    };
    state = WorkspaceSelectionState(
      access: access,
      selected:
          remembered != null && access.allows(remembered) ? remembered : null,
      rememberChoice: remembered != null && access.allows(remembered),
    );
  }

  Future<bool> select(
    AppWorkspace workspace, {
    required bool rememberChoice,
  }) async {
    if (!state.access.allows(workspace)) return false;
    _preferenceLoadId++;
    state = WorkspaceSelectionState(
      access: state.access,
      selected: workspace,
      rememberChoice: rememberChoice,
    );

    final userId = _userId;
    if (userId != null && state.access.hasMultiple) {
      final storage = _ref.read(secureStorageProvider);
      if (rememberChoice) {
        await storage.write(_preferenceKey(userId), workspace.name);
      } else {
        await storage.delete(_preferenceKey(userId));
      }
    }
    return true;
  }

  void setRememberChoice(bool value) {
    state = WorkspaceSelectionState(
      access: state.access,
      selected: state.selected,
      rememberChoice: value,
      isPreferenceLoading: state.isPreferenceLoading,
    );
  }

  void showChooser() {
    if (!state.access.hasMultiple) return;
    state = WorkspaceSelectionState(
      access: state.access,
      rememberChoice: state.rememberChoice,
    );
  }
}

final workspaceSelectionProvider =
    StateNotifierProvider<WorkspaceSelectionNotifier, WorkspaceSelectionState>(
        (ref) {
  return WorkspaceSelectionNotifier(ref);
});
