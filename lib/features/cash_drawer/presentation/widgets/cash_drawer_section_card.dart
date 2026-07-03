import 'package:flutter/material.dart';

import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

/// Section card for scrollable Cash Drawer content.
///
/// Unlike [PosDashboardCardContainer], this does not force infinite height,
/// which breaks layout inside [SingleChildScrollView].
class CashDrawerSectionCard extends StatelessWidget {
  const CashDrawerSectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(TenantAdminSpacing.xl),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
        border: Border.all(color: TenantAdminColors.border),
        boxShadow: TenantAdminShadows.card,
      ),
      child: child,
    );
  }
}
