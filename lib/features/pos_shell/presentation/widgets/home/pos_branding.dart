import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../application/state/pos_home_dashboard_state.dart';
import '../../providers/pos_home_dashboard_provider.dart';

class PosBranding extends ConsumerWidget {
  const PosBranding({
    super.key,
    this.dashboard,
    this.brandName,
    this.logoUrl,
  });

  final PosHomeDashboardState? dashboard;
  final String? brandName;
  final String? logoUrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state =
        dashboard ?? ref.watch(posHomeDashboardProvider).asData?.value;
    final resolvedName = brandName?.trim().isNotEmpty == true
        ? brandName!.trim()
        : state?.businessDisplayName.trim().isNotEmpty == true
            ? state!.businessDisplayName.trim()
            : 'OneVerz POS';
    final resolvedLogoUrl = logoUrl?.trim().isNotEmpty == true
        ? logoUrl!.trim()
        : state?.businessLogoUrl;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(TenantAdminRadius.md),
          child: SizedBox.square(
            dimension: 52,
            child: resolvedLogoUrl?.isNotEmpty == true
                ? Image.network(
                    resolvedLogoUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const _LogoFallback(),
                  )
                : const _LogoFallback(),
          ),
        ),
        if (resolvedName.isNotEmpty) ...[
          const SizedBox(width: TenantAdminSpacing.sm),
          Flexible(
            child: _BrandName(name: resolvedName),
          ),
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
