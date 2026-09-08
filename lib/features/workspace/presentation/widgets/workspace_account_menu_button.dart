import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/providers/session_provider.dart';
import '../../../../shared/pos_session/pos_session_bootstrap_provider.dart';
import '../../domain/workspace_access.dart';
import '../../workspace_router.dart';
import '../providers/workspace_selection_provider.dart';

enum _AccountAction { tenantAdmin, pos, settings, signOut }

class WorkspaceAccountMenuButton extends ConsumerWidget {
  const WorkspaceAccountMenuButton({
    required this.currentWorkspace,
    this.compact = false,
    super.key,
  });

  final AppWorkspace currentWorkspace;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider);
    final workspaceState = ref.watch(workspaceSelectionProvider);
    final name = session?.userDisplayName.trim().isNotEmpty == true
        ? session!.userDisplayName.trim()
        : 'User';

    return PopupMenuButton<_AccountAction>(
      tooltip: 'Account menu',
      position: PopupMenuPosition.under,
      onSelected: (action) => _handleAction(context, ref, action),
      itemBuilder: (context) => [
        if (workspaceState.access.hasMultiple)
          const PopupMenuItem<_AccountAction>(
            enabled: false,
            child: Text(
              'SWITCH WORKSPACE',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
        if (workspaceState.access.hasMultiple)
          PopupMenuItem<_AccountAction>(
            value: _AccountAction.tenantAdmin,
            enabled: currentWorkspace != AppWorkspace.tenantAdmin,
            child: const _MenuRow(
              icon: Icons.apartment_rounded,
              label: 'Tenant Admin',
            ),
          ),
        if (workspaceState.access.hasMultiple)
          PopupMenuItem<_AccountAction>(
            value: _AccountAction.pos,
            enabled: currentWorkspace != AppWorkspace.pos,
            child: const _MenuRow(
              icon: Icons.point_of_sale_rounded,
              label: 'POS / Cashier',
            ),
          ),
        if (workspaceState.access.hasMultiple) const PopupMenuDivider(),
        const PopupMenuItem<_AccountAction>(
          value: _AccountAction.settings,
          child: _MenuRow(
            icon: Icons.settings_outlined,
            label: 'Account Settings',
          ),
        ),
        const PopupMenuItem<_AccountAction>(
          value: _AccountAction.signOut,
          child: _MenuRow(
            icon: Icons.logout_rounded,
            label: 'Sign Out',
            color: Colors.red,
          ),
        ),
      ],
      child: Container(
        height: 44,
        padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 10),
        decoration: BoxDecoration(
          color: Colors.black,
          border: Border.all(color: const Color(0xFF2E3138)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 15,
              backgroundColor: const Color(0xFF374151),
              child: Text(
                _initials(name),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (!compact) ...[
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 110),
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
            const Icon(Icons.keyboard_arrow_down_rounded,
                color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAction(
    BuildContext context,
    WidgetRef ref,
    _AccountAction action,
  ) async {
    switch (action) {
      case _AccountAction.tenantAdmin:
        final remember = ref.read(workspaceSelectionProvider).rememberChoice;
        await ref.read(workspaceSelectionProvider.notifier).select(
              AppWorkspace.tenantAdmin,
              rememberChoice: remember,
            );
        if (context.mounted) context.go('/tenant-admin');
      case _AccountAction.pos:
        final remember = ref.read(workspaceSelectionProvider).rememberChoice;
        await ref.read(workspaceSelectionProvider.notifier).select(
              AppWorkspace.pos,
              rememberChoice: remember,
            );
        await ref
            .read(posSessionBootstrapProvider.notifier)
            .bootstrap(force: true);
        if (context.mounted) context.go('/pos/home');
      case _AccountAction.settings:
        context.go(workspaceAccountSettingsRoute);
      case _AccountAction.signOut:
        await ref.read(authSessionProvider.notifier).clear();
    }
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.label,
    this.color = const Color(0xFF111827),
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 19, color: color),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(color: color)),
        ],
      );
}

String _initials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList(growable: false);
  if (parts.isEmpty) return 'U';
  if (parts.length == 1) {
    final length = parts.first.length < 2 ? parts.first.length : 2;
    return parts.first.substring(0, length).toUpperCase();
  }
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}
