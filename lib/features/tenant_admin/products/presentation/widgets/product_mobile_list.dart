import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/services/tenant_admin_access_checker.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_status_badge.dart';
import '../../domain/entities/product.dart';
import '../config/product_row_action_configs.dart';
import '../utils/product_api_errors.dart';
import 'product_thumbnail.dart';

class ProductMobileList extends StatelessWidget {
  const ProductMobileList({
    super.key,
    required this.products,
    required this.visibility,
  });

  final List<Product> products;
  final ProductListVisibility visibility;

  @override
  Widget build(BuildContext context) {
    final canEdit = visibility.visibleRowActions.any(
      (action) => action.actionId == ProductRowActionId.edit,
    );

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: products.length,
      separatorBuilder: (_, __) => const SizedBox(height: TenantAdminSpacing.md),
      itemBuilder: (context, index) {
        final product = products[index];
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: canEdit
                ? () => context.go(
                      '/tenant-admin/products/${product.id}/edit',
                    )
                : null,
            borderRadius: BorderRadius.circular(16),
            hoverColor: TenantAdminColors.primary.withValues(alpha: 0.03),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: TenantAdminColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: TenantAdminColors.border),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x06000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ProductThumbnail(
                        productId: product.id,
                        imageStorageKey: product.imageStorageKey,
                        size: 48,
                      ),
                      const SizedBox(width: TenantAdminSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: TenantAdminColors.bodyText,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'SKU: ${product.sku}',
                              style: const TextStyle(
                                color: TenantAdminColors.mutedText,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TenantAdminStatusBadge(
                        label: displayProductStatus(product.status),
                        status: productStatusType(product.status),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: TenantAdminColors.background,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        _DetailItem(
                          label: 'Category',
                          value: product.categoryName ?? '-',
                        ),
                        const SizedBox(width: 16),
                        _DetailItem(
                          label: 'Price',
                          value: formatProductPrice(product.sellingPrice),
                          isBold: true,
                        ),
                        if (canEdit) ...[
                          const Spacer(),
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: TenantAdminColors.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: TenantAdminColors.border),
                            ),
                            child: const Icon(
                              Icons.chevron_right,
                              size: 18,
                              color: TenantAdminColors.mutedText,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DetailItem extends StatelessWidget {
  const _DetailItem({
    required this.label,
    required this.value,
    this.isBold = false,
  });

  final String label;
  final String value;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: TenantAdminColors.mutedText,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: TenantAdminColors.bodyText,
            fontSize: 12,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
