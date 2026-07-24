import 'package:flutter/material.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../application/state/pos_home_dashboard_state.dart';

class PosBranding extends StatelessWidget {
  const PosBranding({super.key, required this.dashboard});

  final PosHomeDashboardState dashboard;

  @override
  Widget build(BuildContext context) {
    final name = dashboard.businessDisplayName.trim();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(TenantAdminRadius.md),
          child: SizedBox.square(
            dimension: 52,
            child: dashboard.businessLogoUrl?.isNotEmpty == true
                ? Image.network(
                    dashboard.businessLogoUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const _LogoFallback(),
                  )
                : const _LogoFallback(),
          ),
        ),
        if (name.isNotEmpty) ...[
          const SizedBox(width: TenantAdminSpacing.sm),
          Text(
            name,
            style: TenantAdminTextStyles.sectionTitle(context).copyWith(
              color: TenantAdminColors.surface,
            ),
          ),
        ],
      ],
    );
  }
}

class _LogoFallback extends StatelessWidget {
  const _LogoFallback();

  @override
  Widget build(BuildContext context) => const ColoredBox(
        color: TenantAdminColors.posHomeDarkBackground,
        child: Icon(
          Icons.shopping_bag_rounded,
          color: TenantAdminColors.posHomeOrangeStart,
        ),
      );
}
