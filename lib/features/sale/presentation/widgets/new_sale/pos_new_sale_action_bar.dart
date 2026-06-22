import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/access/pos_access_codes.dart';
import '../../../../auth/presentation/providers/session_provider.dart';
import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

class PosNewSaleActionBar extends ConsumerWidget {
  const PosNewSaleActionBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider);
    final canCreateCustomer =
        session?.hasPermission(PosPermissionCodes.createNewSaleCustomer) ==
            true;
    final canApplyDiscount =
        session?.hasPermission(PosPermissionCodes.applySaleDiscount) == true;
    final canParkSale =
        session?.hasPermission(PosPermissionCodes.createParkedSale) == true;
    final actions = <Widget>[
      if (canCreateCustomer)
        const Expanded(
          child: _ActionButton(
            icon: Icons.person_add_alt_1_outlined,
            label: 'Add Customer',
            onPressed: null,
          ),
        ),
      if (canApplyDiscount)
        const Expanded(
          child: _ActionButton(
            icon: Icons.discount_outlined,
            label: 'Apply Discount',
            onPressed: null,
          ),
        ),
      if (canParkSale)
        const Expanded(
          child: _ActionButton(
            icon: Icons.pause_circle_outline_rounded,
            label: 'Save as Parked Sale',
            onPressed: null,
          ),
        ),
    ];

    if (actions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        for (var index = 0; index < actions.length; index += 1) ...[
          if (index > 0) const SizedBox(width: TenantAdminSpacing.sm),
          actions[index],
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
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
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
