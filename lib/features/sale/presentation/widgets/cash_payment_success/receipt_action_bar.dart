import 'package:flutter/material.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../payment/pos_bottom_action_buttons.dart';

class ReceiptActionBar extends StatelessWidget {
  const ReceiptActionBar({
    super.key,
    this.onPrintReceipt,
    this.onNewSale,
    this.onViewSales,
  });

  final VoidCallback? onPrintReceipt;
  final VoidCallback? onNewSale;
  final VoidCallback? onViewSales;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useCompact = constraints.maxWidth < 760;
        final actions = <Widget>[
          if (onPrintReceipt != null)
            _OutlinedAction(
              label: 'Print Receipt',
              icon: Icons.print_outlined,
              onPressed: onPrintReceipt!,
              expand: useCompact,
            ),
          if (onNewSale != null)
            _OutlinedAction(
              label: 'New Sale',
              icon: Icons.add_shopping_cart_outlined,
              onPressed: onNewSale!,
              expand: useCompact,
            ),
          if (onViewSales != null)
            _PrimaryAction(
              label: 'View Sales',
              icon: Icons.receipt_long_outlined,
              onPressed: onViewSales!,
              expand: useCompact,
            ),
        ];

        if (actions.isEmpty) {
          return const SizedBox.shrink();
        }

        if (useCompact) {
          return Wrap(
            spacing: TenantAdminSpacing.sm,
            runSpacing: TenantAdminSpacing.sm,
            children: actions,
          );
        }

        return Row(
          children: [
            for (var index = 0; index < actions.length; index++) ...[
              if (index > 0) const SizedBox(width: TenantAdminSpacing.sm),
              Expanded(child: actions[index]),
            ],
          ],
        );
      },
    );
  }
}

class _OutlinedAction extends StatelessWidget {
  const _OutlinedAction({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.expand,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    return PosBottomOutlinedButton(
      label: label,
      icon: icon,
      onPressed: onPressed,
      expand: expand,
    );
  }
}

class _PrimaryAction extends StatelessWidget {
  const _PrimaryAction({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.expand,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    return PosBottomFilledButton(
      label: label,
      icon: icon,
      onPressed: onPressed,
      expand: expand,
    );
  }
}
