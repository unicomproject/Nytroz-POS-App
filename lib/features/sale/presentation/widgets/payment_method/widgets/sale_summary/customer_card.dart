import 'package:nytroz_pos/features/tenant_admin/presentation/theme/tenant_admin_theme.dart';
import 'package:flutter/material.dart';

import '../../../../../../cart/presentation/providers/pos_new_sale_cart_provider.dart';
import '../../payment_method_style.dart';

class CustomerCard extends StatelessWidget {
  const CustomerCard({
    super.key,
    required this.cart,
    this.onTap,
  });

  final PosNewSaleCartState cart;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final customer = cart.selectedCustomer;
    final hasCustomer = customer != null;

    final initials = hasCustomer ? _getInitials(customer.displayName) : '';
    final phone = customer?.phone?.trim();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          key: const ValueKey('payment-customer-card'),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: hasCustomer
                ? TenantAdminColors.successSurface
                : PaymentMethodStyle.subtleBackground,
            border: Border.all(
              color: hasCustomer
                  ? TenantAdminColors.successBorder
                  : PaymentMethodStyle.border,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: hasCustomer
                    ? TenantAdminColors.successSurface
                    : TenantAdminColors.subtleBackground,
                child: hasCustomer
                    ? Text(
                        initials,
                        style: const TextStyle(
                          color: TenantAdminColors.success,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : const Icon(
                        Icons.person_outline_rounded,
                        color: TenantAdminColors.mutedText,
                        size: 20,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasCustomer ? customer.displayName : 'Guest',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: PaymentMethodStyle.navy,
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (hasCustomer && phone != null && phone.isNotEmpty) ...[
                      Text(
                        phone,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: TenantAdminColors.mutedText,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ] else if (!hasCustomer) ...[
                      const Text(
                        'Walk-in Customer',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: TenantAdminColors.mutedText,
                        ),
                      ),
                    ],
                    if (hasCustomer) ...[
                      Wrap(
                        spacing: 6,
                        runSpacing: 2,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: TenantAdminColors.successSurface,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Attached to Sale',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: TenantAdminColors.success,
                              ),
                            ),
                          ),
                          if (customer.statusLabel.isNotEmpty) ...[
                            Text(
                              customer.statusLabel,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: TenantAdminColors.success,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap to change customer',
                        key: const ValueKey('payment-customer-change-hint'),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 4),
                      Text(
                        'Tap to select customer',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (hasCustomer)
                const Icon(
                  Icons.check_circle_rounded,
                  color: TenantAdminColors.success,
                  size: 22,
                ),
              const SizedBox(width: 6),
              const Icon(
                Icons.chevron_right_rounded,
                color: TenantAdminColors.mutedText,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return 'C';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts.last[0]).toUpperCase();
  }
}

class PaymentInfoCard extends StatelessWidget {
  const PaymentInfoCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.success = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String trailing;
  final bool success;

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: success
              ? TenantAdminColors.successSurface
              : TenantAdminColors.subtleBackground,
          border: Border.all(
            color: success
                ? TenantAdminColors.successBorder
                : PaymentMethodStyle.border,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: success
                  ? TenantAdminColors.successSurface
                  : TenantAdminColors.subtleBackground,
              child: Icon(
                icon,
                size: 18,
                color: success
                    ? TenantAdminColors.success
                    : TenantAdminColors.mutedText,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: success
                          ? TenantAdminColors.success
                          : PaymentMethodStyle.navy,
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: TenantAdminColors.mutedText,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              trailing,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: success
                    ? TenantAdminColors.success
                    : PaymentMethodStyle.navy,
              ),
            ),
          ],
        ),
      );
}
