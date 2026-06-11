import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../tenant_admin/presentation/widgets/tenant_admin_buttons.dart';
import '../widgets/auth_page_shell.dart';

class SetupSuccessScreen extends StatelessWidget {
  const SetupSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthPageShell(
      title: 'Setup completed',
      subtitle: 'Your password has been saved. Continue to login.',
      child: Column(
        children: [
          const Icon(Icons.check_circle,
              size: 72, color: TenantAdminColors.success),
          const SizedBox(height: TenantAdminSpacing.xl),
          TenantAdminPrimaryButton(
            label: 'Continue to login',
            onPressed: () => context.go('/tenant-admin/login'),
          ),
        ],
      ),
    );
  }
}
