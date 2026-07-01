import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../customer/domain/entities/pos_customer.dart';
import '../../../customer/presentation/providers/customer_search_provider.dart';
import '../../../customer/presentation/widgets/add_customer_dialog.dart';
import '../../../customer/presentation/widgets/customer_membership_badge.dart';
import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

/// Shows the customer attached to the current sale at the top of the Cart
/// panel (under the header, above cart items). Renders nothing when no customer
/// is selected.
///
/// Edit reopens the existing Add Customer modal; Remove clears the selection
/// from UI/sale state only — it never deletes the customer or the cart items.
class PosSelectedCustomerCard extends ConsumerWidget {
  const PosSelectedCustomerCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customer = ref.watch(selectedCustomerProvider);
    if (customer == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: TenantAdminSpacing.md),
      child: Container(
        decoration: BoxDecoration(
          color: TenantAdminColors.background,
          borderRadius: BorderRadius.circular(TenantAdminRadius.md),
          border: Border.all(color: TenantAdminColors.border),
        ),
        padding: const EdgeInsets.fromLTRB(
          TenantAdminSpacing.sm,
          TenantAdminSpacing.sm,
          TenantAdminSpacing.xs,
          TenantAdminSpacing.sm,
        ),
        child: Row(
          children: [
            _InitialsAvatar(customer: customer),
            const SizedBox(width: TenantAdminSpacing.sm),
            Expanded(child: _CustomerDetails(customer: customer)),
            _CustomerIconButton(
              icon: Icons.edit_outlined,
              tooltip: 'Change customer',
              color: TenantAdminColors.info,
              onPressed: () => showAddCustomerDialog(context),
            ),
            _CustomerIconButton(
              icon: Icons.close_rounded,
              tooltip: 'Remove customer',
              color: TenantAdminColors.danger,
              onPressed: () =>
                  ref.read(selectedCustomerProvider.notifier).state = null,
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomerDetails extends StatelessWidget {
  const _CustomerDetails({required this.customer});

  final PosCustomer customer;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Customer',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: TenantAdminColors.mutedText,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          customer.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: TenantAdminColors.bodyText,
                fontWeight: FontWeight.w800,
              ),
        ),
        if (customer.phone.trim().isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            customer.phone,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: TenantAdminColors.mutedText,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ],
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({required this.customer});

  final PosCustomer customer;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: CustomerAvatarPalette.background(customer.membershipTier),
        shape: BoxShape.circle,
      ),
      child: Text(
        customer.initials,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: CustomerAvatarPalette.foreground(customer.membershipTier),
              fontWeight: FontWeight.w900,
            ),
      ),
    );
  }
}

class _CustomerIconButton extends StatelessWidget {
  const _CustomerIconButton({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Icon(icon, size: 20),
      color: color,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
    );
  }
}
