import 'package:flutter/material.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/theme/tenant_admin_theme.dart';

import '../../domain/entities/pos_customer.dart';

/// Small pill that labels a customer's loyalty tier (Gold/Silver/Bronze).
///
/// Renders nothing for [PosMembershipTier.none] so non-member rows stay clean.
class CustomerMembershipBadge extends StatelessWidget {
  const CustomerMembershipBadge({super.key, required this.tier});

  final PosMembershipTier tier;

  @override
  Widget build(BuildContext context) {
    final style = _CustomerMembershipBadgeStyle.forTier(tier);
    if (style == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: TenantAdminSpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.workspace_premium_outlined, size: 12, color: style.foreground),
          const SizedBox(width: TenantAdminSpacing.xs),
          Text(
            style.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: style.foreground,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _CustomerMembershipBadgeStyle {
  const _CustomerMembershipBadgeStyle({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  static _CustomerMembershipBadgeStyle? forTier(PosMembershipTier tier) {
    switch (tier) {
      case PosMembershipTier.gold:
        return const _CustomerMembershipBadgeStyle(
          label: 'Gold Member',
          background: Color(0xFFFEF3C7),
          foreground: Color(0xFFB45309),
        );
      case PosMembershipTier.silver:
        return const _CustomerMembershipBadgeStyle(
          label: 'Silver Member',
          background: Color(0xFFF1F5F9),
          foreground: Color(0xFF475569),
        );
      case PosMembershipTier.bronze:
        return const _CustomerMembershipBadgeStyle(
          label: 'Bronze Member',
          background: Color(0xFFFFEDD5),
          foreground: Color(0xFF9A3412),
        );
      case PosMembershipTier.none:
        return null;
    }
  }
}

/// Background/foreground colours for the circular initials avatar, matched to
/// the loyalty tier so member rows read consistently.
class CustomerAvatarPalette {
  const CustomerAvatarPalette._();

  static Color background(PosMembershipTier tier) {
    switch (tier) {
      case PosMembershipTier.gold:
        return const Color(0xFFFEF3C7);
      case PosMembershipTier.silver:
        return const Color(0xFFF1F5F9);
      case PosMembershipTier.bronze:
        return const Color(0xFFFFEDD5);
      case PosMembershipTier.none:
        return TenantAdminColors.secondary;
    }
  }

  static Color foreground(PosMembershipTier tier) {
    switch (tier) {
      case PosMembershipTier.gold:
        return const Color(0xFFB45309);
      case PosMembershipTier.silver:
        return const Color(0xFF475569);
      case PosMembershipTier.bronze:
        return const Color(0xFF9A3412);
      case PosMembershipTier.none:
        return TenantAdminColors.info;
    }
  }
}
