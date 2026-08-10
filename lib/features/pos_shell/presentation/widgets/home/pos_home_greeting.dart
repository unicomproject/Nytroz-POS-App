import 'package:flutter/material.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

class PosHomeGreeting extends StatelessWidget {
  const PosHomeGreeting({
    super.key,
    required this.userDisplayName,
    required this.statusMessage,
  });

  final String userDisplayName;
  final String statusMessage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hello, $userDisplayName 👋',
          style: TenantAdminTextStyles.pageTitle(context),
        ),
        const SizedBox(height: TenantAdminSpacing.xs),
        Text(
          statusMessage,
          style: TenantAdminTextStyles.muted(context),
        ),
      ],
    );
  }
}
