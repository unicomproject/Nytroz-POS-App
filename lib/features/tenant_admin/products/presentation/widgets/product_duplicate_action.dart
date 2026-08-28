import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';

class ProductDuplicateAction extends StatelessWidget {
  const ProductDuplicateAction({
    super.key,
    required this.productId,
    this.compact = true,
  });

  final String productId;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Duplicate product',
      child: compact
          ? OutlinedButton.icon(
              onPressed: () => _openDuplicateWizard(context),
              icon: const Icon(Icons.copy_outlined, size: 18),
              label: const Text(
                'Duplicate',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                foregroundColor: TenantAdminColors.bodyText,
                side: const BorderSide(color: TenantAdminColors.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(TenantAdminRadius.md),
                ),
              ),
            )
          : OutlinedButton.icon(
              onPressed: () => _openDuplicateWizard(context),
              icon: const Icon(Icons.copy_outlined, size: 18),
              label: const Text(
                'Duplicate',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                foregroundColor: TenantAdminColors.bodyText,
                side: const BorderSide(color: TenantAdminColors.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(TenantAdminRadius.md),
                ),
              ),
            ),
    );
  }

  void _openDuplicateWizard(BuildContext context) {
    final encodedProductId = Uri.encodeComponent(productId);
    context.go('/tenant-admin/products/add?duplicateFrom=$encodedProductId');
  }
}
