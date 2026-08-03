import 'package:flutter/material.dart';

import '../../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

class PosQuantityStepper extends StatelessWidget {
  const PosQuantityStepper({
    required this.quantity,
    this.onIncrement,
    this.onDecrement,
    super.key,
  });

  final int quantity;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFF2563EB);
    const disabledColor = TenantAdminColors.offline;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox.square(
          dimension: 24,
          child: IconButton(
            padding: EdgeInsets.zero,
            onPressed: onDecrement,
            icon: Icon(
              Icons.remove,
              size: 16,
              color: onDecrement != null ? activeColor : disabledColor,
            ),
          ),
        ),
        const SizedBox(width: TenantAdminSpacing.xs),
        Text(
          '$quantity',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: TenantAdminColors.bodyText,
          ),
        ),
        const SizedBox(width: TenantAdminSpacing.xs),
        SizedBox.square(
          dimension: 24,
          child: IconButton(
            padding: EdgeInsets.zero,
            onPressed: onIncrement,
            icon: Icon(
              Icons.add,
              size: 16,
              color: onIncrement != null ? activeColor : disabledColor,
            ),
          ),
        ),
      ],
    );
  }
}
