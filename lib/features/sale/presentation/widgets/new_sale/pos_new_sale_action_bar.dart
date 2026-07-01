import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/access/pos_access_codes.dart';
import '../../../../../core/access/pos_permission_access.dart';
import '../../../../auth/presentation/providers/session_provider.dart';
import '../../../../customer/presentation/widgets/add_customer_dialog.dart';
import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

class PosNewSaleActionBar extends ConsumerWidget {
  const PosNewSaleActionBar({
    super.key,
    this.compact = false,
  });

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider);
    final canAddCustomer = session != null &&
        PosPermissionAccess.canViewCustomers(session.permissionCodes.toSet());
    final canApplyDiscount =
        session?.hasPermission(PosPermissionCodes.applySaleDiscount) == true;
    final canParkSale =
        session?.hasPermission(PosPermissionCodes.createParkedSale) == true;
    final actions = <Widget>[
      if (canAddCustomer)
        _ActionButton(
          icon: Icons.person_add_alt_1_outlined,
          label: 'Add Customer',
          expand: compact,
          onPressed: () => showAddCustomerDialog(context),
        ),
      if (canApplyDiscount)
        _ActionButton(
          icon: Icons.discount_outlined,
          label: 'Apply Discount',
          expand: compact,
          onPressed: null,
        ),
      if (canParkSale)
        _ActionButton(
          icon: Icons.pause_circle_outline_rounded,
          label: 'Save as Parked Sale',
          expand: compact,
          onPressed: null,
        ),
    ];

    if (actions.isEmpty) {
      return const SizedBox.shrink();
    }

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < actions.length; index += 1) ...[
            if (index > 0) const SizedBox(height: TenantAdminSpacing.sm),
            actions[index],
          ],
        ],
      );
    }

    return Row(
      children: [
        for (var index = 0; index < actions.length; index += 1) ...[
          if (index > 0) const SizedBox(width: TenantAdminSpacing.sm),
          Expanded(child: actions[index]),
        ],
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.expand = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: expand ? double.infinity : null,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: TenantAdminSpacing.sm,
          ),
          textStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TenantAdminRadius.md),
          ),
        ),
      ),
    );
  }
}
