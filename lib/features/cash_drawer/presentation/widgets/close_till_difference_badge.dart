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
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: TenantAdminColors.mutedText,
              fontSize: 13,
            ),
      );
    }

    final colors = closeTillDifferenceColors(difference!);
    final label = formatCloseTillDifferenceLabel(difference!);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Difference',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: TenantAdminColors.mutedText,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colors.foreground,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
          ),
        ],
      ),
    );
  }
}
