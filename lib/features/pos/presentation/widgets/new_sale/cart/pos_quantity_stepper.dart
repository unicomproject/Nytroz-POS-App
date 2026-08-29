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
        _QuantityButton(
          icon: Icons.remove,
          onPressed: onDecrement,
          activeColor: activeColor,
          disabledColor: disabledColor,
          tooltip: 'Decrease quantity',
        ),
        const SizedBox(width: TenantAdminSpacing.xs),
        SizedBox(
          width: 18,
          child: Text(
            '$quantity',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: TenantAdminColors.bodyText,
            ),
          ),
        ),
        const SizedBox(width: TenantAdminSpacing.xs),
        _QuantityButton(
          icon: Icons.add,
          onPressed: onIncrement,
          activeColor: activeColor,
          disabledColor: disabledColor,
          tooltip: 'Increase quantity',
        ),
      ],
    );
  }
}

class _QuantityButton extends StatelessWidget {
  const _QuantityButton({
    required this.icon,
    required this.activeColor,
    required this.disabledColor,
    required this.tooltip,
    this.onPressed,
  });

  final IconData icon;
  final Color activeColor;
  final Color disabledColor;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null;
    final color = isEnabled ? activeColor : disabledColor;

    return SizedBox.square(
      dimension: 26,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isEnabled
              ? activeColor.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color.withValues(alpha: isEnabled ? 0.35 : 0.2),
          ),
        ),
        child: IconButton(
          tooltip: tooltip,
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          onPressed: onPressed,
          icon: Icon(
            icon,
            size: 16,
            color: color,
          ),
        ),
      ),
    );
  }
}
