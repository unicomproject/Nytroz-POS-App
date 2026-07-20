import 'package:flutter/material.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

class ChooseOptionInformationMessage extends StatelessWidget {
  const ChooseOptionInformationMessage({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.info_outline_rounded,
          color: TenantAdminColors.info,
          size: 18,
        ),
        const SizedBox(width: TenantAdminSpacing.sm),
        Flexible(
          child: Text(
            'This choice determines the next step in the returns process.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: TenantAdminColors.mutedText,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }
}
