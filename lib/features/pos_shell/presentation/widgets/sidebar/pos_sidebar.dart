import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../../auth/presentation/providers/session_provider.dart';
import '../../../../device_activation/presentation/providers/device_activation_provider.dart';
import '../../../../till/presentation/providers/till_provider.dart';
import '../../../../../core/access/pos_permission_access.dart';
import '../../config/pos_shell_nav_destinations.dart';
import '../../providers/pos_home_dashboard_provider.dart';
import '../../providers/pos_shell_navigation_provider.dart';
import '../../../domain/entities/pos_shell_nav_destination.dart';
import '../pos_shell_nav_item.dart';

const _oneVerzLogoAsset = 'assets/images/logo.png';
const _sidebarWidth = 160.0;

class PosSidebar extends ConsumerWidget {
  const PosSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPath = GoRouterState.of(context).uri.path;
    final grantedPermissions = ref.watch(posShellGrantedPermissionsProvider);
    final visibleDestinations = posShellNavDestinations
        .where((destination) => destination.isVisible(grantedPermissions))
        .toList(growable: false);

    return SizedBox(
      width: _sidebarWidth,
      child: ColoredBox(
        color: TenantAdminColors.navy,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 22, 12, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _BrandHeader(),
                const SizedBox(height: 30),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    physics: const ClampingScrollPhysics(),
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
                const _UserProfileBlock(),
              ],
            ),
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

  if (destination.key == 'returns-refunds' &&
      currentPath.startsWith('/pos/returns-refunds')) {
    return true;
  }

  return false;
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFF075DFF),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(7),
            child: Image.asset(
              _oneVerzLogoAsset,
              width: 24,
              height: 24,
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(width: TenantAdminSpacing.md),
        Flexible(
          child: Text(
            'SCS-TIX',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
          ),
        ),
      ],
    );
  }
}

enum _UserMenuAction { profile, endShift }

const _endShiftCloseTillRoute = '/pos/cash-drawer/close-till?endShift=true';

class _UserProfileBlock extends ConsumerWidget {
  const _UserProfileBlock();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayName = ref.watch(authSessionProvider)?.userDisplayName.trim();
    final resolvedName =
        displayName == null || displayName.isEmpty ? 'Cashier' : displayName;
    final profileImageUrl = ref
        .watch(posHomeDashboardProvider)
        .asData
        ?.value
        .cashierProfileImageUrl;

    return Material(
      color: Colors.white.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(TenantAdminRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        onTap: () => _showUserMenu(context, ref),
        child: Padding(
          padding: const EdgeInsets.all(TenantAdminSpacing.md),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: const Color(0xFF075DFF),
                    child: Text(
                      _initialsFor(resolvedName),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (_hasProfileImage(profileImageUrl))
                    Positioned.fill(
                      child: ClipOval(
                        child: Image.network(
                          profileImageUrl!.trim(),
                          key: const Key('pos-sidebar-profile-image'),
                          fit: BoxFit.cover,
                          webHtmlElementStrategy:
                              WebHtmlElementStrategy.fallback,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        ),
                      ),
                    ),
                  const Positioned(
                    right: -1,
                    bottom: 0,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: TenantAdminColors.success,
                        shape: BoxShape.circle,
                        border: Border.fromBorderSide(
                          BorderSide(color: TenantAdminColors.navy, width: 2),
                        ),
                      ),
                      child: SizedBox(width: 10, height: 10),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: TenantAdminSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      resolvedName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
    final canEndShift = _canEndShift(ref);
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
      items: [
        const PopupMenuItem(
          value: _UserMenuAction.profile,
          child: Text('Profile'),
        ),
        PopupMenuItem(
          value: _UserMenuAction.endShift,
          enabled: canEndShift,
          child: const Text('End Shift'),
        ),
      ],
    );

    if (!context.mounted || selected == null) {
      return;
    }

    switch (selected) {
      case _UserMenuAction.profile:
        context.go('/pos/profile');
      case _UserMenuAction.endShift:
        await _startEndShiftFlow(context, ref);
    }
  }

  Future<void> _startEndShiftFlow(BuildContext context, WidgetRef ref) async {
    if (_canEndShift(ref)) {
      context.go(_endShiftCloseTillRoute);
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('An open assigned till is required to end shift.'),
        ),
      );
  }
}

bool _hasProfileImage(String? value) =>
    value != null && value.trim().isNotEmpty;

bool _canEndShift(WidgetRef ref) {
  final session = ref.read(authSessionProvider);
  if (session == null || !session.isAuthenticated) {
    return false;
  }

  final granted = session.permissionCodes.toSet();
  if (!PosPermissionAccess.canCloseTill(granted)) {
    return false;
  }

  final deviceContext = ref.read(deviceActivationProvider).deviceContext;
  if (deviceContext == null ||
      !deviceContext.isTrusted ||
      deviceContext.deviceId.trim().isEmpty ||
      deviceContext.tillId.trim().isEmpty) {
    return false;
  }

  final tillSession = ref.read(tillProvider).session;
  if (tillSession == null || tillSession.status != 'open') {
    return false;
  }

  return tillSession.tillId == deviceContext.tillId &&
      tillSession.openedDeviceId == deviceContext.deviceId;
}

String _initialsFor(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) {
    return 'C';
  }
  if (parts.length == 1) {
    final end = parts.first.length < 2 ? parts.first.length : 2;
    return parts.first.substring(0, end).toUpperCase();
  }
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}
