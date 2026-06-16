import 'package:flutter/material.dart';

import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import 'pos_mobile_top_bar.dart';
import 'pos_sidebar.dart';

class PosShellScaffold extends StatelessWidget {
  const PosShellScaffold({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final showSidebar =
            constraints.maxWidth >= TenantAdminBreakpoints.mobile;

        if (showSidebar) {
          return Scaffold(
            body: Row(
              children: [
                const PosSidebar(),
                Expanded(
                  child: SafeArea(
                    left: false,
                    child: child,
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          appBar: const PosMobileTopBar(),
          body: SafeArea(
            top: false,
            child: child,
          ),
        );
      },
    );
  }
}
