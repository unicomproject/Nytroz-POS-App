import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_page_scaffold.dart';
import '../providers/role_setup_wizard_provider.dart';
import '../widgets/role_setup_components.dart';

class RoleSetupShell extends ConsumerWidget {
  const RoleSetupShell({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wizard = ref.watch(roleSetupWizardProvider);
    return TenantAdminPageScaffold(
      title: 'Roles & Access',
      subtitle: 'Configure existing system role access',
      scrollable: false,
      child: Column(
        children: [
          RoleSetupProgressIndicator(
            currentStep: wizard.currentStep,
            totalSteps: 5,
          ),
          const SizedBox(height: TenantAdminSpacing.lg),
          Expanded(child: child),
        ],
      ),
    );
  }
}
