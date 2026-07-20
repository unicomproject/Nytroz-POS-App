import 'package:flutter/material.dart';

import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

class CustomerSummaryCard extends StatelessWidget {
  const CustomerSummaryCard({
    super.key,
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    this.value,
    this.isLoading = false,
    this.isUnavailable = false,
    this.error = false,
  });

  final String label;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String? value;
  final bool isLoading;
  final bool isUnavailable;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final displayValue = isLoading
        ? '…'
        : error
            ? '—'
            : isUnavailable
                ? 'N/A'
                : (value ?? '—');

    return Container(
      constraints: const BoxConstraints(minHeight: 88),
      padding: const EdgeInsets.all(TenantAdminSpacing.lg),
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        border: Border.all(color: TenantAdminColors.border),
        boxShadow: TenantAdminShadows.card,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: TenantAdminSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: TenantAdminColors.mutedText,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: TenantAdminSpacing.xs),
                Text(
                  displayValue,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: error || isUnavailable
                            ? TenantAdminColors.mutedText
                            : TenantAdminColors.bodyText,
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
