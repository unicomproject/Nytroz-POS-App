import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      subtitle: 'Configure existing system role access',
      scrollable: false,
      child: child,
    );
  }
}
