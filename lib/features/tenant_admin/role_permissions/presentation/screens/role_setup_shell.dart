import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_page_scaffold.dart';


class RoleSetupShell extends ConsumerWidget {
  const RoleSetupShell({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TenantAdminPageScaffold(
      title: 'Roles & Access',
      subtitle: 'Configure role permissions across modules',
      scrollable: false,
      child: Container(
        decoration: BoxDecoration(
          color: TenantAdminColors.surface,
          borderRadius: BorderRadius.circular(TenantAdminRadius.md),
          boxShadow: TenantAdminShadows.card,
        ),
        child: child,
      ),
    );
  }
}
