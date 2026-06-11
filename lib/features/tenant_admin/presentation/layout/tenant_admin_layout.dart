import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/tenant_admin_menu_provider.dart';
import '../screens/tenant_admin_error_screen.dart';
import '../screens/tenant_admin_loading_screen.dart';
import 'tenant_admin_bottom_nav.dart';
import 'tenant_admin_sidebar.dart';
import 'tenant_admin_top_bar.dart';

class TenantAdminLayout extends ConsumerWidget {
  const TenantAdminLayout({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menuState = ref.watch(tenantAdminMenuProvider);

    return menuState.when(
      loading: () => const TenantAdminLoadingScreen(),
      error: (error, stackTrace) => TenantAdminErrorScreen(
        onRetry: () => ref.refresh(tenantAdminMenuProvider),
      ),
      data: (items) {
        final currentPath = ModalRoute.of(context)?.settings.name ?? '';

        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 900;

            if (isWide) {
              return Scaffold(
                body: Row(
                  children: [
                    TenantAdminSidebar(
                      items: items,
                      currentPath: currentPath,
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          const TenantAdminTopBar(),
                          Expanded(child: child),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }

            return Scaffold(
              appBar: const TenantAdminTopBar(),
              body: child,
              bottomNavigationBar: TenantAdminBottomNav(
                items: items,
                currentPath: currentPath,
              ),
            );
          },
        );
      },
    );
  }
}
