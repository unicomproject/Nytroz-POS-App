import 'package:flutter/material.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

class PosStatusChip extends StatelessWidget {
  const PosStatusChip({
    super.key,
    required this.tillLabel,
    required this.statusLabel,
    required this.isOpen,
  });

  final String tillLabel;
  final String statusLabel;
  final bool isOpen;

  @override
  Widget build(BuildContext context) {
    final statusColor =
        isOpen ? TenantAdminColors.success : TenantAdminColors.warning;

    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.symmetric(
        horizontal: TenantAdminSpacing.lg,
        vertical: TenantAdminSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(TenantAdminRadius.xl),
        border: Border.all(color: statusColor.withValues(alpha: 0.2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: TenantAdminSpacing.sm),
          Text(
            '$tillLabel / $statusLabel',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: TenantAdminColors.bodyText,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
