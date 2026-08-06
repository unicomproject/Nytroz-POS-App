import 'package:flutter/material.dart';

import 'package:nytroz_pos/features/tenant_admin/presentation/theme/tenant_admin_theme.dart';

class AddTillQuickPairPanel extends StatelessWidget {
  const AddTillQuickPairPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.flash_on, color: TenantAdminColors.primary),
            const SizedBox(width: TenantAdminSpacing.sm),
            Text(
              'Quick Pair & Status',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Pair devices quickly and check status.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: TenantAdminColors.mutedText,
              ),
        ),
      ],
    );
  }
}
