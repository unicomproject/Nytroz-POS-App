import 'package:flutter/material.dart';

import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

/// Section card for Cash Drawer / Close Till content.
///
/// Unlike [PosDashboardCardContainer], this does not force infinite height by
/// default (which breaks layout inside [SingleChildScrollView]).
/// Pass [expand] when the card should fill a bounded [Expanded] parent.
class CashDrawerSectionCard extends StatelessWidget {
  const CashDrawerSectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(TenantAdminSpacing.xl),
    this.expand = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: expand ? double.infinity : null,
      padding: padding,
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        border: Border.all(color: TenantAdminColors.border),
        boxShadow: TenantAdminShadows.card,
      ),
      child: child,
    );
  }
}
