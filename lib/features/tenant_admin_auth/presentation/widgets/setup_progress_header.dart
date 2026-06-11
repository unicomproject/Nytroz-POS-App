import 'package:flutter/material.dart';

import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

class SetupProgressHeader extends StatelessWidget {
  const SetupProgressHeader({
    super.key,
    required this.currentStep,
  });

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    const labels = ['Validate link', 'Set password', 'Login'];

    return Row(
      children: [
        for (var index = 0; index < labels.length; index++) ...[
          Expanded(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: index <= currentStep
                      ? TenantAdminColors.primary
                      : TenantAdminColors.border,
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: index <= currentStep
                          ? Colors.white
                          : TenantAdminColors.mutedText,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: TenantAdminSpacing.xs),
                Text(
                  labels[index],
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          if (index < labels.length - 1)
            Container(
              width: 32,
              height: 1,
              color: index < currentStep
                  ? TenantAdminColors.primary
                  : TenantAdminColors.border,
            ),
        ],
      ],
    );
  }
}
