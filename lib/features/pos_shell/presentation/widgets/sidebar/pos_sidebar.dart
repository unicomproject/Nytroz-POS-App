import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../../auth/presentation/providers/session_provider.dart';
import '../../config/pos_shell_nav_destinations.dart';
import '../../providers/pos_shell_navigation_provider.dart';
import '../../../domain/entities/pos_shell_nav_destination.dart';
import '../pos_shell_nav_item.dart';

class PosSidebar extends ConsumerWidget {
  const PosSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPath = GoRouterState.of(context).uri.path;
    final grantedPermissions = ref.watch(posShellGrantedPermissionsProvider);
    final visibleDestinations = posShellNavDestinations
        .where((destination) => destination.isVisible(grantedPermissions))
        .toList(growable: false);

    return Container(
      width: 92,
      color: TenantAdminColors.navy,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _BrandHeader(),
              const SizedBox(height: TenantAdminSpacing.md),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    ...visibleDestinations.map((destination) {
                      return PosShellNavItem(
                        icon: destination.icon,
                        label: destination.label,
                        selected: _isDestinationSelected(
                          destination,
                          currentPath,
                        ),
                        isEnabled: destination.isEnabled(grantedPermissions),
                        onTap: () => _handleDestinationTap(
                          context,
                          destination,
                          grantedPermissions,
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: TenantAdminSpacing.md),
              const _UserMenu(),
            ],
          ),
        ),
      ),
    );
  }

  void _handleDestinationTap(
    BuildContext context,
    PosShellNavDestination destination,
    Set<String> grantedPermissions,
  ) {
    if (destination.isEnabled(grantedPermissions)) {
      context.go(destination.routePath!);
      return;
    }

    final message = destination.unavailableMessage;
    if (message == null) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

bool _isDestinationSelected(
  PosShellNavDestination destination,
  String currentPath,
) {
  final routePath = destination.routePath;
  if (routePath == null) {
    return false;
  }

  if (currentPath == routePath) {
    return true;
  }

  if (destination.key == 'new-sale' &&
      currentPath.startsWith('/pos/new-sale')) {
    return true;
  }

  if (destination.key == 'cash-drawer' &&
      currentPath.startsWith('/pos/cash-drawer')) {
    return true;
  }

  return false;
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _LogoPlaceholder(),
        SizedBox(height: TenantAdminSpacing.xs),
        Text(
          'NytrozPOS',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _LogoPlaceholder extends StatelessWidget {
  const _LogoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: TenantAdminColors.info,
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
      ),
      child: const Icon(
        Icons.local_activity_outlined,
        color: Colors.white,
        size: 24,
      ),
    );
  }
}

enum _UserMenuAction { profile, logout }

class _UserMenu extends ConsumerWidget {
  const _UserMenu();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Tooltip(
      message: 'User profile',
      child: SizedBox(
        height: 52,
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => _showUserMenu(context, ref),
            child: const Stack(
              alignment: Alignment.center,
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: TenantAdminColors.navySoft,
                  child: Icon(Icons.person_outline, color: Colors.white),
                ),
                Positioned(
                  right: 15,
                  bottom: 6,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: TenantAdminColors.success,
                      shape: BoxShape.circle,
                      border: Border.fromBorderSide(
                        BorderSide(color: TenantAdminColors.navy, width: 2),
                      ),
                    ),
                    child: SizedBox(width: 12, height: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showUserMenu(BuildContext context, WidgetRef ref) async {
    final box = context.findRenderObject() as RenderBox?;
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (box == null || overlay == null) {
      return;
    }

    const menuWidth = 168.0;
    const menuHeight = 104.0;
    final offset = box.localToGlobal(Offset.zero, ancestor: overlay);
    final left = offset.dx + box.size.width + TenantAdminSpacing.sm;
    final top = (offset.dy + box.size.height - menuHeight).clamp(
      TenantAdminSpacing.sm,
      overlay.size.height - menuHeight - TenantAdminSpacing.sm,
    );
    final selected = await showMenu<_UserMenuAction>(
      context: context,
      position: RelativeRect.fromLTRB(
        left,
        top,
        overlay.size.width - left - menuWidth,
        overlay.size.height - top - menuHeight,
      ),
      elevation: 8,
      color: TenantAdminColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        side: const BorderSide(color: TenantAdminColors.border),
      ),
      items: const [
        PopupMenuItem(
          value: _UserMenuAction.profile,
          child: Text('Profile'),
        ),
        PopupMenuItem(
          value: _UserMenuAction.logout,
          child: Text('Logout'),
        ),
      ],
    );

    if (!context.mounted || selected == null) {
      return;
    }

    switch (selected) {
      case _UserMenuAction.profile:
        context.go('/pos/profile');
      case _UserMenuAction.logout:
        await ref.read(authSessionProvider.notifier).clear();
        if (context.mounted) {
          context.go('/tenant-login');
        }
    }
  }
}
