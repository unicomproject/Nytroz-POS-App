import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/tenant_admin_context_provider.dart';
import '../theme/tenant_admin_theme.dart';

class TenantAdminTopBar extends ConsumerWidget implements PreferredSizeWidget {
  const TenantAdminTopBar({
    super.key,
    this.onMenuPressed,
  });

  final VoidCallback? onMenuPressed;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contextState = ref.watch(tenantAdminContextProvider);

    return AppBar(
      backgroundColor: TenantAdminColors.navy,
      foregroundColor: Colors.white,
      leading: onMenuPressed == null
          ? null
          : IconButton(
              icon: const Icon(Icons.menu),
              tooltip: 'Open navigation',
              onPressed: onMenuPressed,
            ),
      title: contextState.maybeWhen(
        data: (tenantContext) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              tenantContext.tenantName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            Text(
              tenantContext.userDisplayName,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        orElse: () => const Text('Tenant Admin'),
      ),
    );
  }
}
