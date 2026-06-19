import 'package:flutter/material.dart';

import 'pos_desktop_top_bar.dart';
import 'pos_mobile_top_bar.dart';
import '../sidebar/pos_sidebar.dart';

const double _posShellMobileBreakpoint = 700;

class PosShellScaffold extends StatelessWidget {
  const PosShellScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.showTopBar = true,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final bool showTopBar;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final showSidebar = constraints.maxWidth >= _posShellMobileBreakpoint;

        if (showSidebar) {
          return Scaffold(
            body: Row(
              children: [
                const PosSidebar(),
                Expanded(
                  child: SafeArea(
                    left: false,
                    bottom: false,
                    child: Column(
                      children: [
                        if (showTopBar)
                          PosDesktopTopBar(
                            title: title,
                            subtitle: subtitle,
                          ),
                        Expanded(child: child),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          appBar: showTopBar ? const PosMobileTopBar() : null,
          body: SafeArea(
            top: !showTopBar,
            child: child,
          ),
        );
      },
    );
  }
}
