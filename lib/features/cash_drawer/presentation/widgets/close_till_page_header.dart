import 'package:flutter/material.dart';

import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

class CloseTillPageHeader extends StatelessWidget {
  const CloseTillPageHeader({
    super.key,
    required this.onBack,
  });

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 42,
          height: 42,
          child: IconButton(
            onPressed: onBack,
            tooltip: 'Back to Cash Drawer',
            padding: EdgeInsets.zero,
            iconSize: 21,
            icon: const Icon(Icons.arrow_back_rounded),
            style: IconButton.styleFrom(
              backgroundColor: TenantAdminColors.surface,
              side: const BorderSide(color: TenantAdminColors.border),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Close Till',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: TenantAdminColors.bodyText,
                      fontSize: 22,
                      height: 1.1,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                'Count the cash in the drawer and close the till.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: TenantAdminColors.mutedText,
                      fontSize: 13,
                      height: 1.2,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
