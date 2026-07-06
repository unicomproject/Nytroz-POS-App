import 'package:flutter/material.dart';

import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../providers/close_till_provider.dart';

class CloseTillDifferenceBadge extends StatelessWidget {
  const CloseTillDifferenceBadge({
    super.key,
    required this.difference,
  });

  final double? difference;

  @override
  Widget build(BuildContext context) {
    if (difference == null) {
      return Text(
        'Enter counted cash to calculate the difference.',
        style: TenantAdminTextStyles.muted(context),
      );
    }

    final colors = closeTillDifferenceColors(difference!);
    final label = formatCloseTillDifferenceLabel(difference!);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: TenantAdminSpacing.lg,
        vertical: TenantAdminSpacing.md,
      ),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Difference',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: TenantAdminColors.mutedText,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: TenantAdminSpacing.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colors.foreground,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}
