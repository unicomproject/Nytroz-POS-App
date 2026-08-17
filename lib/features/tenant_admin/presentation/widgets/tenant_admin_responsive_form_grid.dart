import 'package:flutter/material.dart';

import '../theme/tenant_admin_theme.dart';

/// A responsive grid that displays children in a two-column layout on wide screens
/// (>= [breakpoint]) and reflows them into a single column on narrow screens.
class TenantAdminResponsiveFormGrid extends StatelessWidget {
  const TenantAdminResponsiveFormGrid({
    super.key,
    required this.children,
    this.crossAxisSpacing = TenantAdminSpacing.xl,
    this.mainAxisSpacing = TenantAdminSpacing.lg,
    this.breakpoint = 720.0,
  });

  final List<Widget> children;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final double breakpoint;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < breakpoint;

        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) SizedBox(height: mainAxisSpacing),
                children[i],
              ],
            ],
          );
        }

        final rows = <Widget>[];
        for (var i = 0; i < children.length; i += 2) {
          final first = children[i];
          final second = (i + 1 < children.length) ? children[i + 1] : null;

          rows.add(
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: first),
                if (second != null) ...[
                  SizedBox(width: crossAxisSpacing),
                  Expanded(child: second),
                ] else ...[
                  SizedBox(width: crossAxisSpacing),
                  const Spacer(),
                ],
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) SizedBox(height: mainAxisSpacing),
              rows[i],
            ],
          ],
        );
      },
    );
  }
}
