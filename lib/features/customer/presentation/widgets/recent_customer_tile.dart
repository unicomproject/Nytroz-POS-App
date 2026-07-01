import 'package:flutter/material.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/theme/tenant_admin_theme.dart';

import '../../domain/entities/pos_customer.dart';
import 'customer_membership_badge.dart';

/// A single recent-customer row: initials avatar, name, phone, membership badge
/// and loyalty points. Tapping selects the customer for the current sale.
class RecentCustomerTile extends StatelessWidget {
  const RecentCustomerTile({
    super.key,
    required this.customer,
    required this.onTap,
  });

  final PosCustomer customer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: TenantAdminColors.surface,
      borderRadius: BorderRadius.circular(TenantAdminRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: TenantAdminSpacing.sm,
            vertical: TenantAdminSpacing.md,
          ),
          child: Row(
            children: [
              _InitialsAvatar(customer: customer),
              const SizedBox(width: TenantAdminSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            customer.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(
                                  color: TenantAdminColors.bodyText,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                        if (customer.membershipTier !=
                            PosMembershipTier.none) ...[
                          const SizedBox(width: TenantAdminSpacing.sm),
                          CustomerMembershipBadge(
                            tier: customer.membershipTier,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: TenantAdminSpacing.xs),
                    Text(
                      customer.phone,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: TenantAdminColors.mutedText,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: TenantAdminSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${customer.loyaltyPoints}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: TenantAdminColors.bodyText,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  Text(
                    'Points',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: TenantAdminColors.mutedText,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({required this.customer});

  final PosCustomer customer;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: CustomerAvatarPalette.background(customer.membershipTier),
        shape: BoxShape.circle,
      ),
      child: Text(
        customer.initials,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: CustomerAvatarPalette.foreground(customer.membershipTier),
              fontWeight: FontWeight.w900,
            ),
      ),
    );
  }
}
