import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../widgets/pos_shell_scaffold.dart';

class PosPlaceholderScreen extends StatelessWidget {
  const PosPlaceholderScreen({
    super.key,
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return PosShellScaffold(
      child: Padding(
        padding: TenantAdminInsets.pageForWidth(
          MediaQuery.sizeOf(context).width,
        ),
        child: Align(
          alignment: Alignment.center,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TenantAdminTextStyles.pageTitle(context),
                ),
                const SizedBox(height: TenantAdminSpacing.sm),
                Text(
                  'Coming soon',
                  textAlign: TextAlign.center,
                  style: TenantAdminTextStyles.muted(context),
                ),
                const SizedBox(height: TenantAdminSpacing.xl),
                FilledButton.icon(
                  onPressed: () => context.go('/pos/home'),
                  icon: const Icon(Icons.home_rounded),
                  label: const Text('Back Home'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
