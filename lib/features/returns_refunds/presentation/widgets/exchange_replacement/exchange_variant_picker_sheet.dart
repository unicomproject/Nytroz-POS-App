import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../cart/domain/entities/pos_catalog_models.dart';
import '../../../../cart/presentation/providers/pos_catalog_provider.dart';
import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../domain/entities/exchange_replacement_selection.dart';
import '../../providers/return_create_credit_provider.dart';

Future<ExchangeReplacementSelection?> showExchangeVariantPicker({
  required BuildContext context,
  required WidgetRef ref,
  required PosCatalogProductSummary product,
  required String currencyCode,
}) {
  return showModalBottomSheet<ExchangeReplacementSelection>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _VariantPickerSheet(
      product: product,
      currencyCode: currencyCode,
    ),
  );
}

class _VariantPickerSheet extends ConsumerWidget {
  const _VariantPickerSheet({
    required this.product,
    required this.currencyCode,
  });

  final PosCatalogProductSummary product;
  final String currencyCode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(posProductDetailProvider(product.productId));

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(TenantAdminSpacing.lg),
        child: detailAsync.when(
          loading: () => const SizedBox(
            height: 180,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(error.toString()),
              const SizedBox(height: TenantAdminSpacing.md),
              OutlinedButton(
                onPressed: () => ref.invalidate(
                  posProductDetailProvider(product.productId),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
          data: (detail) {
            final variants = detail.variants
                .where((variant) => !variant.isOutOfStock)
                .toList(growable: false);

            if (variants.isEmpty) {
              return const Text('No in-stock variants are available.');
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  product.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: TenantAdminSpacing.md),
                for (final variant in variants) ...[
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      variant.attributes.entries
                          .map((entry) => entry.value)
                          .join(' / '),
                    ),
                    subtitle: Text(
                      '${formatReturnCreditAmount(currency: currencyCode, amount: variant.price.toDouble())}'
                      '${variant.sku.isNotEmpty ? ' • ${variant.sku}' : ''}',
                    ),
                    onTap: () {
                      final label = variant.attributes.entries
                          .map((entry) => entry.value)
                          .join(' / ');
                      Navigator.of(context).pop(
                        ExchangeReplacementSelection(
                          productId: product.productId,
                          productVariantId: variant.variantId,
                          productName: product.name,
                          imageUrl: product.imageUrl,
                          variantDisplayName: label,
                          sku: variant.sku,
                          quantity: 1,
                          unitPrice: variant.price.toDouble(),
                          currencyCode: currencyCode,
                          stockStatus: variant.stockStatus,
                          availableQty: variant.stockQty,
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
