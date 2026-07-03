import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/providers/session_provider.dart';
import '../providers/tenant_admin_access_provider.dart';
import '../providers/tenant_admin_context_provider.dart';
import '../providers/tenant_admin_menu_provider.dart';
import '../../domain/errors/tenant_admin_context_exception.dart';
import '../screens/tenant_admin_error_screen.dart';
import '../screens/tenant_admin_loading_screen.dart';
import 'tenant_admin_bottom_nav.dart';
import 'tenant_admin_sidebar.dart';
import 'tenant_admin_top_bar.dart';

class TenantAdminLayout extends ConsumerWidget {
  const TenantAdminLayout({
    super.key,
    required this.currentPath,
    required this.child,
  });

  final String currentPath;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menuState = ref.watch(tenantAdminMenuProvider);
    final contextState = ref.watch(tenantAdminContextProvider);
    final accessState = ref.watch(tenantAdminAccessCheckerProvider);

    return menuState.when(
      loading: () => const TenantAdminLoadingScreen(),
      error: (error, stackTrace) {
        if (error is TenantAdminContextException &&
            error.code == TenantAdminContextErrorCodes.authRequired) {
          return TenantAdminErrorScreen(
            message: error.message,
            actionLabel: 'Sign in again',
            onRetry: () async {
              await ref.read(authSessionProvider.notifier).clear();
              if (context.mounted) {
                context.go('/tenant-login');
              }
            },
          );
        }

        if (error is TenantAdminContextException) {
          return TenantAdminErrorScreen(
            message: error.message,
            onRetry: () {
              ref.invalidate(tenantAdminContextProvider);
              ref.invalidate(tenantAdminMenuProvider);
            },
          );
        }

        return TenantAdminErrorScreen(
          onRetry: () {
            ref.invalidate(tenantAdminContextProvider);
            ref.invalidate(tenantAdminMenuProvider);
          },
        );
      },
      data: (items) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 900;

            if (isWide) {
              final showTopBar = currentPath != '/tenant-admin/dashboard' &&
                  !currentPath.startsWith('/tenant-admin/products');

              return Scaffold(
                body: Row(
                  children: [
                    TenantAdminSidebar(
                      items: items,
                      currentPath: currentPath,
                      tenantContext: contextState.asData?.value,
                      accessChecker: accessState.asData?.value,
                    ),
                    Expanded(
                      child: showTopBar
                          ? Column(
                              children: [
                                const TenantAdminTopBar(),
                                Expanded(child: child),
                              ],
                            )
                          : child,
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
