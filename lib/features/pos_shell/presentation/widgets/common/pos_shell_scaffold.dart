import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../pos/presentation/widgets/new_sale/navigation/pos_cashier_bottom_navigation.dart';
import '../../../../../core/access/permission_access_providers.dart';
import 'pos_desktop_top_bar.dart';
import 'pos_mobile_top_bar.dart';
import 'pos_shell_bottom_nav_destinations.dart';
import 'pos_shell_top_bar_visibility.dart';
import 'pos_top_bar.dart';
import '../sidebar/pos_sidebar.dart';
import '../home/pos_dashboard_top_bar_content.dart';
import 'package:nytroz_pos/features/pos/presentation/widgets/new_sale/pos_new_sale_top_bar_content.dart';

const double _posShellMobileBreakpoint = 900;

class PosShellScaffold extends ConsumerWidget {
  const PosShellScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.showTopBar = true,
    this.showTopBarSearch = true,
    this.showSidebar = true,
    this.showBottomNavigation = false,
    this.isNewSale = false,
    this.isDashboard = false,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final bool showTopBar;
  final bool showTopBarSearch;
  final bool showSidebar;
  final bool showBottomNavigation;
  final bool isNewSale;
  final bool isDashboard;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissions = ref.watch(effectivePermissionSetProvider);
    final topBarAllowed =
        showTopBar && PosShellTopBarVisibility.shouldRenderTopBar(permissions);
    final bottomNavAllowed = showBottomNavigation &&
        shouldShowPosCashierBottomNav(permissions);

    return LayoutBuilder(
      builder: (context, constraints) {
        final useDesktopShell =
            constraints.maxWidth >= _posShellMobileBreakpoint;
        final useSidebar = showSidebar && useDesktopShell;

        if (useDesktopShell) {
          return Scaffold(
            body: Row(
              children: [
                if (useSidebar) const PosSidebar(),
                Expanded(
                  child: SafeArea(
                    left: false,
                    bottom: false,
                    child: _PosShellContent(
                      title: title,
                      subtitle: subtitle,
                      showTopBar: topBarAllowed,
                      showTopBarSearch: showTopBarSearch,
                      showBottomNavigation: bottomNavAllowed,
                      isNewSale: isNewSale,
                      isDashboard: isDashboard,
                      child: child,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          appBar: topBarAllowed ? const PosMobileTopBar() : null,
          body: _PosShellContent(
            title: title,
            subtitle: subtitle,
            showTopBar: false,
            showTopBarSearch: showTopBarSearch,
            showBottomNavigation: bottomNavAllowed,
            isNewSale: isNewSale,
            isDashboard: isDashboard,
            applyTopSafeArea: !topBarAllowed,
            child: child,
          ),
        );
      },
    );
  }
}

class _PosShellContent extends StatelessWidget {
  const _PosShellContent({
    required this.title,
    required this.subtitle,
    required this.showTopBar,
    required this.showTopBarSearch,
    required this.showBottomNavigation,
    required this.isNewSale,
    required this.isDashboard,
    required this.child,
    this.applyTopSafeArea = false,
  });

  final String title;
  final String subtitle;
  final bool showTopBar;
  final bool showTopBarSearch;
  final bool showBottomNavigation;
  final bool isNewSale;
  final bool isDashboard;
  final Widget child;
  final bool applyTopSafeArea;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (showTopBar)
          isNewSale
              ? const PosTopBar(
                  content: PosNewSaleTopBarContent(),
                )
              : isDashboard
                  ? const PosTopBar(
                      content: PosDashboardTopBarContent(),
                    )
                  : PosDesktopTopBar(
                      title: title,
                      subtitle: subtitle,
                      showSearch: showTopBarSearch,
                      isNewSale: isNewSale,
                    ),
        Expanded(
          child: SafeArea(
            top: applyTopSafeArea,
            bottom: false,
            child: child,
          ),
        ),
        if (showBottomNavigation) const PosCashierBottomNavigation(),
      ],
    );
  }
}
