import 'package:flutter/material.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

class PosDashboardCardContainer extends StatelessWidget {
  const PosDashboardCardContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(TenantAdminSpacing.xl),
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  /// When provided, the whole card behaves like a button (ripple + pointer).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(TenantAdminRadius.lg);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: TenantAdminShadows.card,
      ),
      child: Material(
        color: TenantAdminColors.surface,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: TenantAdminColors.border),
            ),
            child: Padding(
              padding: padding,
              child: SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
