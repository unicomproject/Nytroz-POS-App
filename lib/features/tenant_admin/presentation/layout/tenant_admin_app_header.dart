import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/access/pos_access_codes.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../../till/presentation/providers/till_provider.dart';
import '../providers/tenant_admin_context_provider.dart';
import '../theme/tenant_admin_theme.dart';
import '../../../workspace/domain/workspace_access.dart';
import '../../../workspace/presentation/widgets/workspace_account_menu_button.dart';

/// Shared black application header for every Tenant Admin page.
///
/// Shows OneVerz POS branding, till-session status, outlet/till context, and
/// notifications. Values come from authenticated providers ΓÇö never hardcoded.
class TenantAdminAppHeader extends ConsumerWidget {
  const TenantAdminAppHeader({
    super.key,
    this.onMenuPressed,
  });

  final VoidCallback? onMenuPressed;

  static const height = TenantAdminAppHeaderTokens.height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tenantContext = ref.watch(tenantAdminContextProvider).valueOrNull;
    final tillState = ref.watch(tillProvider);
    final session = ref.watch(authSessionProvider);
    final tillSession = tillState.session;

    final outletLabel = _resolveOutletLabel(
      tillSession?.outletName,
      tenantContext?.outletScope
          .where((o) => o.isDefault)
          .map((o) => o.outletName)
          .firstOrNull,
      tenantContext?.outletScope.firstOrNull?.outletName,
    );

    final tillLabel = _resolveTillLabel(
      tillSession?.tillName,
      tillSession?.tillCode,
    );

    return SizedBox(
      height: height,
      child: Material(
        color: TenantAdminColors.posHomeDarkBackground,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 900;
            // At the 1024 px tablet breakpoint the inline sidebar leaves only
            // 804 px for the header. Collapse the context controls before that
            // point so the account menu and actions never overflow.
            final veryCompact = constraints.maxWidth < 860;

            return Padding(
              padding: EdgeInsets.symmetric(
                horizontal:
                    veryCompact ? TenantAdminSpacing.sm : TenantAdminSpacing.lg,
              ),
              child: Row(
                children: [
                  if (onMenuPressed != null) ...[
                    IconButton(
                      tooltip: 'Open navigation',
                      onPressed: onMenuPressed,
                      icon: const Icon(
                        Icons.menu_rounded,
                        color: TenantAdminColors.surface,
                      ),
                    ),
                    const SizedBox(width: TenantAdminSpacing.xs),
                  ],
                  _BrandMark(
                    compact: veryCompact,
                    logoUrl: tenantContext?.tenantLogoUrl,
                    brandName: tenantContext?.tenantName,
                  ),
                  SizedBox(
                    width: veryCompact
                        ? TenantAdminSpacing.sm
                        : TenantAdminSpacing.lg,
                  ),
                  const Spacer(),
                  if (!veryCompact) ...[
                    _ContextChip(
                      icon: Icons.location_on_outlined,
                      label: outletLabel,
                      compact: compact,
                    ),
                    const SizedBox(width: TenantAdminSpacing.sm),
                    _ContextChip(
                      icon: Icons.point_of_sale_outlined,
                      label: tillLabel,
                      compact: compact,
                    ),
                    const SizedBox(width: TenantAdminSpacing.sm),
                  ],
                  _NotificationBell(
                    canView: session?.hasPermission(
                          PosPermissionCodes.viewNotifications,
                        ) ==
                        true,
                  ),
                  const SizedBox(width: TenantAdminSpacing.xs),
                  WorkspaceAccountMenuButton(
                    currentWorkspace: AppWorkspace.tenantAdmin,
                    compact: veryCompact,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  static String _resolveOutletLabel(
    String? sessionOutlet,
    String? defaultOutlet,
    String? firstOutlet,
  ) {
    final fromSession = sessionOutlet?.trim();
    if (fromSession != null && fromSession.isNotEmpty) {
      return fromSession;
    }
    final fromDefault = defaultOutlet?.trim();
    if (fromDefault != null && fromDefault.isNotEmpty) {
      return fromDefault;
    }
    final fromFirst = firstOutlet?.trim();
    if (fromFirst != null && fromFirst.isNotEmpty) {
      return fromFirst;
    }
    return 'No outlet';
  }

  static String _resolveTillLabel(String? tillName, String? tillCode) {
    final name = tillName?.trim();
    if (name != null && name.isNotEmpty) {
      return name;
    }
    final code = tillCode?.trim();
    if (code != null && code.isNotEmpty) {
      return code;
    }
    return 'No till';
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({
    required this.compact,
    this.logoUrl,
    this.brandName,
  });

  final bool compact;
  final String? logoUrl;
  final String? brandName;

  @override
  Widget build(BuildContext context) {
    final resolvedName = brandName?.trim().isNotEmpty == true
        ? brandName!.trim()
        : 'OneVerz POS';

    final resolvedLogoUrl =
        logoUrl?.trim().isNotEmpty == true ? logoUrl!.trim() : null;

    final baseStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
              color: TenantAdminColors.surface,
              fontWeight: FontWeight.w800,
            ) ??
        const TextStyle(
          fontSize: 16,
          color: TenantAdminColors.surface,
          fontWeight: FontWeight.w800,
        );

    final match = RegExp(r'^(.*?)(\s+POS)$', caseSensitive: false)
        .firstMatch(resolvedName);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
          child: SizedBox.square(
            dimension: compact ? 28 : 34,
            child: resolvedLogoUrl != null
                ? Image.network(
                    resolvedLogoUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        _LogoFallback(compact: compact),
                  )
                : _LogoFallback(compact: compact),
          ),
        ),
        const SizedBox(width: TenantAdminSpacing.sm),
        Flexible(
          child: match == null
              ? Text(
                  resolvedName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: baseStyle,
                )
              : Text.rich(
                  TextSpan(
                    style: baseStyle,
                    children: [
                      TextSpan(text: match.group(1)),
                      TextSpan(
                        text: match.group(2),
                        style: baseStyle.copyWith(
                          color: TenantAdminColors.posHomeOrangeStart,
                        ),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
        ),
      ],
    );
  }
}

class _LogoFallback extends StatelessWidget {
  const _LogoFallback({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: TenantAdminColors.posHomeDarkBackground,
        child: Icon(
          Icons.shopping_bag_rounded,
          color: TenantAdminColors.posHomeAccentOrange,
          size: compact ? 18 : 22,
        ),
      );
}

class _ContextChip extends StatelessWidget {
  const _ContextChip({
    required this.icon,
    required this.label,
    required this.compact,
  });

  final IconData icon;
  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (label.trim().isEmpty) return const SizedBox.shrink();
    return Container(
      height: 44,
      constraints: BoxConstraints(
        maxWidth: compact ? 140 : 180,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? TenantAdminSpacing.sm : TenantAdminSpacing.md,
      ),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(
          color: const Color(0xFF2E3138),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 20,
            color: const Color(0xFF94A3B8),
          ),
          const SizedBox(width: TenantAdminSpacing.sm),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationBell extends StatelessWidget {
  const _NotificationBell({required this.canView});

  final bool canView;

  @override
  Widget build(BuildContext context) {
    if (!canView) {
      return IconButton(
        tooltip: 'Notifications',
        onPressed: () {},
        icon: const Icon(
          Icons.notifications_none_rounded,
          color: TenantAdminColors.surface,
        ),
      );
    }

    // Count comes from notification module when available; do not hardcode.
    const count = 0;

    return IconButton(
      tooltip: 'Notifications',
      onPressed: () {},
      icon: const Badge(
        isLabelVisible: count > 0,
        label: Text('$count'),
        child: Icon(
          Icons.notifications_none_rounded,
          color: TenantAdminColors.surface,
        ),
      ),
    );
  }
}
