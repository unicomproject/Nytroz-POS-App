import 'package:flutter/material.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../domain/entities/return_sale_eligibility.dart';

class EligibilityCheckItem extends StatelessWidget {
  const EligibilityCheckItem({
    super.key,
    required this.check,
  });

  final ReturnPolicyCheck check;

  @override
  Widget build(BuildContext context) {
    final status = _resolveStatusPresentation(check);
    final description = check.description.trim().isNotEmpty
        ? check.description.trim()
        : check.value.trim();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: TenantAdminColors.background,
            borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
            border: Border.all(color: TenantAdminColors.border),
          ),
          child: Icon(
            _iconForCode(check.code),
            color: TenantAdminColors.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: TenantAdminSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                check.label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: TenantAdminColors.bodyText,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              if (description.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: TenantAdminColors.mutedText,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
              if (check.reason?.trim().isNotEmpty == true) ...[
                const SizedBox(height: 3),
                Text(
                  check.reason!.trim(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: status.color,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: TenantAdminSpacing.sm),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(status.icon, color: status.color, size: 18),
            const SizedBox(width: 4),
            Text(
              status.label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: status.color,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ),
      ],
    );
  }

  _StatusPresentation _resolveStatusPresentation(ReturnPolicyCheck check) {
    switch (check.displayStatus) {
      case 'PASSED':
        return const _StatusPresentation(
          label: 'Passed',
          color: TenantAdminColors.success,
          icon: Icons.check_circle_rounded,
        );
      case 'REQUIRES_REVIEW':
      case 'UNDER_REVIEW':
        return const _StatusPresentation(
          label: 'Requires Review',
          color: TenantAdminColors.warning,
          icon: Icons.schedule_rounded,
        );
      case 'WARNING':
        return const _StatusPresentation(
          label: 'Warning',
          color: TenantAdminColors.warning,
          icon: Icons.warning_amber_rounded,
        );
      case 'NOT_APPLICABLE':
        return const _StatusPresentation(
          label: 'N/A',
          color: TenantAdminColors.mutedText,
          icon: Icons.remove_circle_outline_rounded,
        );
      case 'UNKNOWN':
        return const _StatusPresentation(
          label: 'Unknown',
          color: TenantAdminColors.mutedText,
          icon: Icons.help_outline_rounded,
        );
      case 'FAILED':
      default:
        return const _StatusPresentation(
          label: 'Failed',
          color: TenantAdminColors.danger,
          icon: Icons.cancel_rounded,
        );
    }
  }

  IconData _iconForCode(String code) {
    switch (code) {
      case 'RETURN_WINDOW':
        return Icons.calendar_today_outlined;
      case 'ORIGINAL_RECEIPT':
        return Icons.receipt_long_outlined;
      case 'PAYMENT_VERIFICATION':
        return Icons.payments_outlined;
      case 'PRODUCT_RETURN_POLICY':
      case 'PRODUCT_CATEGORY':
        return Icons.local_offer_outlined;
      case 'INSPECTION_REQUIRED':
        return Icons.fact_check_outlined;
      case 'MANAGER_APPROVAL_REQUIRED':
        return Icons.verified_user_outlined;
      case 'ITEM_CONDITION':
        return Icons.fact_check_outlined;
      default:
        return Icons.rule_folder_outlined;
    }
  }
}

class _StatusPresentation {
  const _StatusPresentation({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;
}
