import 'package:flutter/material.dart';

import 'pos_cashier_bottom_navigation.dart';
import 'pos_desktop_top_bar.dart';
import 'pos_mobile_top_bar.dart';
import '../sidebar/pos_sidebar.dart';

const double _posShellMobileBreakpoint = 900;

class PosShellScaffold extends StatelessWidget {
  const PosShellScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.showTopBar = true,
    this.showTopBarSearch = true,
    this.showSidebar = true,
    this.showBottomNavigation = false,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final bool showTopBar;
  final bool showTopBarSearch;
  final bool showSidebar;
  final bool showBottomNavigation;

  @override
  Widget build(BuildContext context) {
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
                      showTopBar: showTopBar,
                      showTopBarSearch: showTopBarSearch,
                      showBottomNavigation: showBottomNavigation,
                      child: child,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          appBar: showTopBar ? const PosMobileTopBar() : null,
          body: _PosShellContent(
            title: title,
            subtitle: subtitle,
            showTopBar: false,
            showTopBarSearch: showTopBarSearch,
            showBottomNavigation: showBottomNavigation,
            applyTopSafeArea: !showTopBar,
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
    required this.child,
    this.applyTopSafeArea = false,
  });

  final String title;
  final String subtitle;
  final bool showTopBar;
  final bool showTopBarSearch;
  final bool showBottomNavigation;
  final Widget child;
  final bool applyTopSafeArea;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (showTopBar)
          PosDesktopTopBar(
            title: title,
            subtitle: subtitle,
            showSearch: showTopBarSearch,
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
