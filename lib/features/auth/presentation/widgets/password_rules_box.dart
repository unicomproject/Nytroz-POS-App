import 'package:flutter/material.dart';

import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

class PasswordRulesBox extends StatelessWidget {
  const PasswordRulesBox({super.key});

  @override
  Widget build(BuildContext context) {
    const rules = [
      'At least 8 characters',
      'One uppercase letter',
      'One lowercase letter',
      'One number',
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = constraints.maxWidth >= 340
            ? (constraints.maxWidth - TenantAdminSpacing.md) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: TenantAdminSpacing.md,
          runSpacing: TenantAdminSpacing.sm,
          children: [
            for (final rule in rules)
              SizedBox(
                width: itemWidth,
                child: Row(
                  children: [
                    const Icon(
                      Icons.radio_button_unchecked,
                      size: 16,
                      color: Color(0xFF94A3B8),
                    ),
                    const SizedBox(width: TenantAdminSpacing.sm),
                    Expanded(
                      child: Text(
                        rule,
                        style: const TextStyle(
                          color: TenantAdminColors.mutedText,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
