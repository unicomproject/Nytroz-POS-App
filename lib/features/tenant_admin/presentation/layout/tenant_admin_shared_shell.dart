import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/tenant_admin_context.dart';
import '../../domain/entities/tenant_admin_menu_item.dart';
import '../../domain/errors/tenant_admin_context_exception.dart';
import '../../domain/services/tenant_admin_access_checker.dart';
import '../../products/presentation/navigation/products_sidebar_provider.dart';
import '../providers/tenant_admin_access_provider.dart';
import '../providers/tenant_admin_context_provider.dart';
import '../providers/tenant_admin_menu_provider.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../../pos_shell/presentation/providers/pos_home_dashboard_provider.dart';
import '../../../pos_shell/presentation/widgets/common/pos_top_bar.dart';
import '../../../pos_shell/presentation/widgets/home/pos_operational_context_card.dart';
import '../../../pos_shell/presentation/widgets/home/pos_session_status_chip.dart';
import '../screens/tenant_admin_error_screen.dart';
import '../screens/tenant_admin_loading_screen.dart';
import '../theme/tenant_admin_theme.dart';
import '../widgets/tenant_admin_shared_cards.dart';
import 'tenant_admin_breadcrumb.dart';
import 'tenant_admin_navigation_drawer.dart';
import 'tenant_admin_responsive_content_area.dart';
import 'tenant_admin_sidebar.dart';

/// Shared reusable shell for every Tenant Admin page.
///
/// ```text
/// TenantAdminSharedShell
/// ├── TenantAdminHeader
/// ├── TenantAdminSidebar / drawer
/// └── TenantAdminResponsiveContentArea
/// ```
class TenantAdminSharedShell extends ConsumerWidget {
  const TenantAdminSharedShell({
    super.key,
    required this.currentRoute,
    required this.child,
    this.selectedSidebarKey,
    this.breadcrumbs = const [],
    this.optionalSidePanel,
    this.requiredPermission,
    this.requiredFeature,
  });

  final String currentRoute;
  final Widget child;
  final String? selectedSidebarKey;
  final List<TenantAdminBreadcrumbItem> breadcrumbs;
  final Widget? optionalSidePanel;
  final String? requiredPermission;
  final String? requiredFeature;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      syncProductsSidebarPath(ref, currentRoute);
    });

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
        final access = accessState.asData?.value;
        final gatedChild = _applyShellAccessGate(
          access: access,
          child: child,
        );

        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final isMobile = TenantAdminBreakpoints.isMobile(width);
            final isSmallTablet = TenantAdminBreakpoints.isSmallTablet(width);
            final isTablet = TenantAdminBreakpoints.isTablet(width);
            final showInlineSidebar = !isMobile;
            final content = TenantAdminResponsiveContentArea(
              breadcrumbs: breadcrumbs,
              optionalSidePanel: optionalSidePanel,
              child: gatedChild,
            );

            if (showInlineSidebar) {
              return Scaffold(
                body: Column(
                  children: [
                    PosTopBar(
                      brandName: contextState.asData?.value.tenantName,
                      brandLogoUrl: contextState.asData?.value.tenantLogoUrl,
                      content: _TenantAdminCashierTopBarContent(
                        tenantContext: contextState.asData?.value,
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          TenantAdminSidebar(
                            items: items,
                            currentPath: currentRoute,
                            selectedSidebarKey: selectedSidebarKey,
                            tenantContext: contextState.asData?.value,
                            accessChecker: access,
                            compact: isSmallTablet || isTablet,
                          ),
                          Expanded(child: content),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }

            return _TenantAdminMobileShell(
              currentPath: currentRoute,
              selectedSidebarKey: selectedSidebarKey,
              items: items,
              tenantContext: contextState.asData?.value,
              accessChecker: access,
              child: content,
            );
          },
        );
      },
    );
  }

  Widget _applyShellAccessGate({
    required TenantAdminAccessChecker? access,
    required Widget child,
  }) {
    if (access == null) {
      return child;
    }

    if (requiredFeature != null &&
        requiredFeature!.trim().isNotEmpty &&
        !access.hasFeature(requiredFeature!)) {
      return const TenantAdminPermissionDeniedCard(
        title: 'Feature not available',
        message: 'Your plan does not include this Tenant Admin feature.',
      );
    }

    if (requiredPermission != null &&
        requiredPermission!.trim().isNotEmpty &&
        !access.can(requiredPermission!)) {
      return TenantAdminPermissionDeniedCard(
        title: 'Permission required',
        message: 'You need `$requiredPermission` to view this page.',
      );
    }

    return child;
  }
}

class _TenantAdminMobileShell extends StatefulWidget {
  const _TenantAdminMobileShell({
    required this.currentPath,
    required this.items,
    required this.child,
    this.selectedSidebarKey,
    this.tenantContext,
    this.accessChecker,
  });

  final String currentPath;
  final String? selectedSidebarKey;
  final List<TenantAdminMenuItem> items;
  final Widget child;
  final TenantAdminContext? tenantContext;
  final TenantAdminAccessChecker? accessChecker;

  @override
  State<_TenantAdminMobileShell> createState() =>
      _TenantAdminMobileShellState();
}

class _TenantAdminMobileShellState extends State<_TenantAdminMobileShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: TenantAdminSidebarMobileDrawer(
        items: widget.items,
        currentPath: widget.currentPath,
        selectedSidebarKey: widget.selectedSidebarKey,
        tenantContext: widget.tenantContext,
        accessChecker: widget.accessChecker,
      ),
      body: Column(
        children: [
          PosTopBar(
            brandName: widget.tenantContext?.tenantName,
            brandLogoUrl: widget.tenantContext?.tenantLogoUrl,
            content: _TenantAdminCashierTopBarContent(
              tenantContext: widget.tenantContext,
            ),
            trailing: IconButton(
              tooltip: 'Open navigation',
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              icon: const Icon(
                Icons.menu_rounded,
                color: Colors.white,
              ),
            ),
          ),
          Expanded(child: widget.child),
        ],
      ),
    );
  }
}

class _TenantAdminCashierTopBarContent extends ConsumerWidget {
  const _TenantAdminCashierTopBarContent({this.tenantContext});

  final TenantAdminContext? tenantContext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider);
    final dashboard = buildPosHomeShellState(
      userDisplayName: session?.userDisplayName ?? '',
      isTrustedDevice: false,
      hasOpenTillSession: false,
      permissionCodes: session?.permissionCodes.toSet() ?? const {},
    );
    final outletScope = tenantContext?.outletScope ?? const [];
    final defaultOutlet = outletScope.where((outlet) => outlet.isDefault);
    final outletName = defaultOutlet.isNotEmpty
        ? defaultOutlet.first.outletName
        : outletScope.isNotEmpty
            ? outletScope.first.outletName
            : 'Outlet pending';

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: PosSessionStatusChip(dashboard: dashboard),
          );
        }

        return Row(
          children: [
            PosSessionStatusChip(dashboard: dashboard),
            const Spacer(),
            Flexible(
              child: PosOperationalContextCard(
                icon: Icons.location_on_outlined,
                label: 'Outlet',
                value: outletName,
              ),
            ),
            const SizedBox(width: TenantAdminSpacing.lg),
            Flexible(
              child: PosOperationalContextCard(
                icon: Icons.point_of_sale_outlined,
                label: 'Till',
                value: dashboard.tillLabel,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Backward-compatible alias used by existing GoRouter shell wiring.
class TenantAdminLayout extends ConsumerWidget {
  const TenantAdminLayout({
    super.key,
    required this.currentPath,
    required this.child,
    this.selectedSidebarKey,
    this.breadcrumbs = const [],
    this.optionalSidePanel,
    this.requiredPermission,
    this.requiredFeature,
  });

  final String currentPath;
  final Widget child;
  final String? selectedSidebarKey;
  final List<TenantAdminBreadcrumbItem> breadcrumbs;
  final Widget? optionalSidePanel;
  final String? requiredPermission;
  final String? requiredFeature;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TenantAdminSharedShell(
      currentRoute: currentPath,
      selectedSidebarKey: selectedSidebarKey,
      breadcrumbs: breadcrumbs,
      optionalSidePanel: optionalSidePanel,
      requiredPermission: requiredPermission,
      requiredFeature: requiredFeature,
      child: child,
    );
  }
}
