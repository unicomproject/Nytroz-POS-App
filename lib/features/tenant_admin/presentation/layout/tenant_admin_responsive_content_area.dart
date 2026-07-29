import 'package:flutter/material.dart';

import '../theme/tenant_admin_theme.dart';
import 'tenant_admin_breadcrumb.dart';

/// Scrollable content host with correct page padding and footer inset.
class TenantAdminResponsiveContentArea extends StatelessWidget {
  const TenantAdminResponsiveContentArea({
    super.key,
    required this.child,
    this.breadcrumbs = const [],
    this.optionalSidePanel,
    this.padding,
  });

  final Widget child;
  final List<TenantAdminBreadcrumbItem> breadcrumbs;
  final Widget? optionalSidePanel;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final pagePadding = padding ?? TenantAdminInsets.pageForWidth(width);
        final showInlinePanel = optionalSidePanel != null &&
            width >= TenantAdminBreakpoints.tablet;

        final content = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (breadcrumbs.isNotEmpty) ...[
              TenantAdminBreadcrumb(items: breadcrumbs),
              const SizedBox(height: TenantAdminSpacing.md),
            ],
            Expanded(child: child),
          ],
        );

        return ColoredBox(
          color: TenantAdminColors.background,
          child: Padding(
            padding: pagePadding,
            child: showInlinePanel
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: content),
                      const SizedBox(width: TenantAdminContentTokens.contentGap),
                      SizedBox(
                        width: TenantAdminContentTokens.sidePanelWidth,
                        child: optionalSidePanel,
                      ),
                    ],
                  )
                : content,
          ),
        );
      },
    );
  }
}
