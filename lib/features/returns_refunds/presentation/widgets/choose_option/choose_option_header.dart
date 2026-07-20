import 'package:flutter/material.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

class ChooseOptionHeader extends StatelessWidget {
  const ChooseOptionHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose Option',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: TenantAdminColors.bodyText,
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: TenantAdminSpacing.xs),
        Text(
          'Choose whether the customer wants a Refund or Exchange.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: TenantAdminColors.primary,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}
