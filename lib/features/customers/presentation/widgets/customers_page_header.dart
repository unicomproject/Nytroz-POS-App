import 'package:flutter/material.dart';

import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../tenant_admin/presentation/widgets/tenant_admin_buttons.dart';

class CustomersPageHeader extends StatelessWidget {
  const CustomersPageHeader({
    super.key,
    required this.canCreateCustomer,
    required this.onNewCustomer,
  });

  final bool canCreateCustomer;
  final VoidCallback onNewCustomer;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 720;
        final title = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Customers',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: TenantAdminColors.bodyText,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ) ??
                  const TextStyle(
                    color: TenantAdminColors.bodyText,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: TenantAdminSpacing.sm),
            Text(
              'Search, select, and manage customers during checkout',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: TenantAdminColors.mutedText,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        );

        final action = TenantAdminPrimaryButton(
          label: 'New Customer',
          icon: Icons.add_rounded,
          onPressed: canCreateCustomer ? onNewCustomer : null,
        );

        if (stacked) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              title,
              const SizedBox(height: TenantAdminSpacing.lg),
              Align(alignment: Alignment.centerLeft, child: action),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: title),
            const SizedBox(width: TenantAdminSpacing.lg),
            action,
          ],
        );
      },
    );
  }
}
