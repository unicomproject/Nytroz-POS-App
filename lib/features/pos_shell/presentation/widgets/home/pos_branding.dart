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
          _BrandName(name: name),
        ],
      ],
    );
  }
}

class _BrandName extends StatelessWidget {
  const _BrandName({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final baseStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
              color: TenantAdminColors.surface,
              fontWeight: FontWeight.w800,
            ) ??
        const TextStyle(
          fontSize: 22,
          color: TenantAdminColors.surface,
          fontWeight: FontWeight.w800,
        );
    final match = RegExp(r'^(.*?)(\s+POS)$', caseSensitive: false)
        .firstMatch(name.trim());
    if (match == null) {
      return Text(name, style: baseStyle);
    }

    return Text.rich(
      TextSpan(
        style: baseStyle,
        children: [
          TextSpan(text: match.group(1)),
          TextSpan(
            text: match.group(2),
            style: baseStyle.copyWith(
              color: TenantAdminColors.posHomeAccentOrange,
            ),
          ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
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
          color: TenantAdminColors.posHomeAccentOrange,
        ),
      );
}
