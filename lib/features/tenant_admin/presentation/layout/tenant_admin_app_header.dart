import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/access/pos_access_codes.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../../till/presentation/providers/till_provider.dart';
import '../providers/tenant_admin_context_provider.dart';
import '../theme/tenant_admin_theme.dart';

/// Shared black application header for every Tenant Admin page.
///
/// Shows OneVerz POS branding, till-session status, outlet/till context, and
/// notifications. Values come from authenticated providers — never hardcoded.
class TenantAdminAppHeader extends ConsumerWidget {
  const TenantAdminAppHeader({
    super.key,
    this.onMenuPressed,
  });

  final VoidCallback? onMenuPressed;

  static const height = 64.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tenantContext = ref.watch(tenantAdminContextProvider).valueOrNull;
    final tillState = ref.watch(tillProvider);
    final session = ref.watch(authSessionProvider);
    final tillSession = tillState.session;
    final isOpen = tillState.hasOpenSession;

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

    return Material(
      color: TenantAdminColors.posHomeDarkBackground,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: height,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 900;
              final veryCompact = constraints.maxWidth < 700;

              return Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: veryCompact
                      ? TenantAdminSpacing.sm
                      : TenantAdminSpacing.lg,
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
                    _BrandMark(compact: veryCompact),
                    SizedBox(
                      width: veryCompact
                          ? TenantAdminSpacing.sm
                          : TenantAdminSpacing.lg,
                    ),
                    if (!veryCompact)
                      _TillSessionChip(isOpen: isOpen, compact: compact),
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
                  ],
                ),
              );
            },
          ),
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
  const _BrandMark({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/logo.png',
          width: compact ? 28 : 34,
          height: compact ? 28 : 34,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Icon(
            Icons.shopping_bag_rounded,
            color: TenantAdminColors.posHomeOrangeStart,
            size: compact ? 26 : 30,
          ),
        ),
        const SizedBox(width: TenantAdminSpacing.sm),
        Flexible(
          child: RichText(
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: TenantAdminColors.surface,
                    fontWeight: FontWeight.w800,
                  ),
              children: const [
                TextSpan(text: 'OneVerz '),
                TextSpan(
                  text: 'POS',
                  style: TextStyle(color: TenantAdminColors.posHomeOrangeStart),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TillSessionChip extends StatelessWidget {
  const _TillSessionChip({
    required this.isOpen,
    required this.compact,
  });

  final bool isOpen;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: compact ? 40 : 44),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? TenantAdminSpacing.sm : TenantAdminSpacing.md,
        vertical: TenantAdminSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: TenantAdminColors.posHomeDarkBackground,
        border: Border.all(color: TenantAdminColors.surface.withValues(alpha: 0.55)),
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.circle,
            size: 10,
            color: isOpen ? TenantAdminColors.success : TenantAdminColors.danger,
          ),
          const SizedBox(width: TenantAdminSpacing.sm),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isOpen ? 'OPEN' : 'CLOSED',
                style: TextStyle(
                  color: isOpen
                      ? TenantAdminColors.success
                      : TenantAdminColors.danger,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  height: 1.1,
                ),
              ),
              if (!compact)
                const Text(
                  'Till Session',
                  style: TextStyle(
                    color: TenantAdminColors.surface,
                    fontSize: 10,
                    height: 1.1,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
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
    return Container(
      constraints: BoxConstraints(
        minHeight: compact ? 40 : 44,
        maxWidth: compact ? 140 : 180,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? TenantAdminSpacing.sm : TenantAdminSpacing.md,
      ),
      decoration: BoxDecoration(
        color: TenantAdminColors.posHomeDarkBackground,
        border: Border.all(color: TenantAdminColors.surface.withValues(alpha: 0.55)),
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: TenantAdminColors.surface),
          const SizedBox(width: TenantAdminSpacing.sm),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: TenantAdminColors.surface,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 18,
            color: TenantAdminColors.surface,
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
      icon: Badge(
        isLabelVisible: count > 0,
        label: Text('$count'),
        child: const Icon(
          Icons.notifications_none_rounded,
          color: TenantAdminColors.surface,
        ),
      ),
    );
  }
}
