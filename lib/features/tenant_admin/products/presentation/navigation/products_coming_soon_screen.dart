import 'package:flutter/material.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_page_scaffold.dart';
import 'products_route_guard.dart';

class ProductsComingSoonScreen extends StatelessWidget {
  const ProductsComingSoonScreen({
    super.key,
    required this.title,
    required this.permissionCode,
  });

  final String title;
  final String permissionCode;

  @override
  Widget build(BuildContext context) {
    return TenantAdminPageScaffold(
      title: title,
      subtitle: 'This screen is not implemented yet.',
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.construction_outlined,
                size: 56,
                color: TenantAdminColors.mutedText,
              ),
              const SizedBox(height: TenantAdminSpacing.lg),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: TenantAdminSpacing.md),
              Text(
                ProductsRouteGuard.permissionLabel(permissionCode),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: TenantAdminColors.mutedText,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: TenantAdminSpacing.lg),
              Text(
                'Coming Soon',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: TenantAdminColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
