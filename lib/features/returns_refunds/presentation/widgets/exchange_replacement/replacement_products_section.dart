import 'package:flutter/material.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../domain/entities/return_exchange.dart';
import 'replacement_product_row.dart';

class ReplacementProductsSection extends StatelessWidget {
  const ReplacementProductsSection({
    super.key,
    required this.products,
    required this.isLoading,
    required this.errorMessage,
    required this.selectedKey,
    required this.currencyCode,
    required this.onRetry,
    required this.onProductSelected,
  });

  final List<ReturnExchangeProduct> products;
  final bool isLoading;
  final String? errorMessage;
  final String? selectedKey;
  final String currencyCode;
  final VoidCallback onRetry;
  final Future<void> Function(ReturnExchangeProduct product) onProductSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
        border: Border.all(color: TenantAdminColors.border),
        boxShadow: TenantAdminShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(
              horizontal: TenantAdminSpacing.lg,
              vertical: TenantAdminSpacing.md,
            ),
            child: Row(
              children: [
                Expanded(flex: 4, child: _HeaderCell('Product')),
                Expanded(flex: 3, child: _HeaderCell('Variant')),
                Expanded(flex: 2, child: _HeaderCell('Stock')),
                Expanded(flex: 2, child: _HeaderCell('Price', alignEnd: true)),
              ],
            ),
          ),
          const Divider(height: 1, color: TenantAdminColors.border),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(TenantAdminSpacing.xl),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (errorMessage != null)
            Padding(
              padding: const EdgeInsets.all(TenantAdminSpacing.lg),
              child: Column(
                children: [
                  Text(
                    errorMessage!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: TenantAdminSpacing.md),
                  OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
                ],
              ),
            )
          else if (products.isEmpty)
            Padding(
              padding: const EdgeInsets.all(TenantAdminSpacing.lg),
              child: Text(
                'No replacement products found.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: TenantAdminColors.mutedText,
                    ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: products.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: TenantAdminColors.border),
              itemBuilder: (context, index) {
                final product = products[index];
                final rowKey = product.variantId != null
                    ? '${product.productId}::${product.variantId}'
                    : product.productId;
                final isSelected = selectedKey == rowKey ||
                    (product.hasVariants &&
                        selectedKey != null &&
                        selectedKey!.startsWith('${product.productId}::'));
                return ReplacementProductRow(
                  product: product,
                  currencyCode: currencyCode,
                  selected: isSelected,
                  onTap: product.isOutOfStock
                      ? null
                      : () => onProductSelected(product),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.label, {this.alignEnd = false});

  final String label;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      textAlign: alignEnd ? TextAlign.end : TextAlign.start,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: TenantAdminColors.mutedText,
            fontWeight: FontWeight.w800,
          ),
    );
  }
}
