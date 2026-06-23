import 'package:flutter/material.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../payment/pos_bottom_action_buttons.dart';

class ReceiptActionBar extends StatelessWidget {
  const ReceiptActionBar({
    super.key,
    required this.onPrintReceipt,
    required this.onEmailReceipt,
    required this.onNewSale,
    required this.onViewSales,
  });

  final VoidCallback onPrintReceipt;
  final VoidCallback onEmailReceipt;
  final VoidCallback onNewSale;
  final VoidCallback onViewSales;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useCompact = constraints.maxWidth < 760;

        if (useCompact) {
          return Wrap(
            spacing: TenantAdminSpacing.sm,
            runSpacing: TenantAdminSpacing.sm,
            children: [
              _OutlinedAction(
                label: 'Print Receipt',
                icon: Icons.print_outlined,
                onPressed: onPrintReceipt,
              ),
              _OutlinedAction(
                label: 'Email Receipt',
                icon: Icons.mail_outline_rounded,
                onPressed: onEmailReceipt,
              ),
              _OutlinedAction(
                label: 'New Sale',
                icon: Icons.add_shopping_cart_outlined,
                onPressed: onNewSale,
              ),
              _PrimaryAction(
                label: 'View Sales',
                icon: Icons.receipt_long_outlined,
                onPressed: onViewSales,
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: _OutlinedAction(
                label: 'Print Receipt',
                icon: Icons.print_outlined,
                onPressed: onPrintReceipt,
              ),
            ),
            const SizedBox(width: TenantAdminSpacing.sm),
            Expanded(
              child: _OutlinedAction(
                label: 'Email Receipt',
                icon: Icons.mail_outline_rounded,
                onPressed: onEmailReceipt,
              ),
            ),
            const SizedBox(width: TenantAdminSpacing.sm),
            Expanded(
              child: _OutlinedAction(
                label: 'New Sale',
                icon: Icons.add_shopping_cart_outlined,
                onPressed: onNewSale,
              ),
            ),
            const SizedBox(width: TenantAdminSpacing.sm),
            Expanded(
              child: _PrimaryAction(
                label: 'View Sales',
                icon: Icons.receipt_long_outlined,
                onPressed: onViewSales,
              ),
            ),
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
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return PosBottomOutlinedButton(
      label: label,
      icon: icon,
      onPressed: onPressed,
    );
  }
}

class _PrimaryAction extends StatelessWidget {
  const _PrimaryAction({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return PosBottomFilledButton(
      label: label,
      icon: icon,
      onPressed: onPressed,
    );
  }
}
