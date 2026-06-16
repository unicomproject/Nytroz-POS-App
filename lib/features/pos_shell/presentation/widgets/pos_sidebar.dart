import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../config/pos_shell_nav_destinations.dart';
import '../providers/pos_shell_navigation_provider.dart';
import '../../domain/entities/pos_shell_nav_destination.dart';
import 'pos_shell_nav_item.dart';

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
      width: 112,
      color: TenantAdminColors.navy,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 14, 10, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _BrandHeader(),
              const SizedBox(height: TenantAdminSpacing.lg),
              ...visibleDestinations.map((destination) {
                return PosShellNavItem(
                  icon: destination.icon,
                  label: destination.label,
                  selected: destination.routePath == currentPath,
                  isEnabled: destination.isEnabled(grantedPermissions),
                  onTap: () => _handleDestinationTap(
                    context,
                    destination,
                    grantedPermissions,
                  ),
                );
              }),
              const Spacer(),
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

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _LogoPlaceholder(),
        SizedBox(height: TenantAdminSpacing.sm),
        Text(
          'SCS-TIX',
          maxLines: 1,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
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
        borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
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
        height: 58,
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
                  radius: 24,
                  backgroundColor: TenantAdminColors.navySoft,
                  child: Icon(Icons.person_outline, color: Colors.white),
                ),
                Positioned(
                  right: 16,
                  bottom: 7,
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
    if (box == null) {
      return;
    }

    final offset = box.localToGlobal(Offset.zero);
    final selected = await showMenu<_UserMenuAction>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx + box.size.width,
        offset.dy,
        offset.dx,
        offset.dy + box.size.height,
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
