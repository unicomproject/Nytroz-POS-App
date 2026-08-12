import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_cached_network_image.dart';
import '../../../cart/presentation/providers/pos_new_sale_cart_provider.dart';
import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

class DiscountItemPicker extends StatelessWidget {
  const DiscountItemPicker({
    super.key,
    required this.items,
    required this.selectedItemKey,
    required this.onChanged,
  });

  final List<PosNewSaleCartItem> items;
  final String? selectedItemKey;
  final ValueChanged<PosNewSaleCartItem> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionLabel('SELECT PRODUCT'),
        const SizedBox(height: 8),
        if (items.isEmpty)
          Container(
            key: const Key('discount-empty-cart-lines'),
            padding: const EdgeInsets.all(20),
            decoration: _cardDecoration(),
            child: const Column(
              children: [
                Icon(Icons.remove_shopping_cart_outlined,
                    color: TenantAdminColors.mutedText),
                SizedBox(height: 8),
                Text('No cart items available for an item discount.'),
              ],
            ),
          )
        else
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 190),
            child: DecoratedBox(
              decoration: _cardDecoration(),
              child: ListView.separated(
                key: const Key('discount-cart-line-list'),
                shrinkWrap: true,
                itemCount: items.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: TenantAdminColors.border),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final key = item.product.cartLineKey;
                  final selected = key == selectedItemKey;
                  return Material(
                    color:
                        selected ? const Color(0xFFF7F0FF) : Colors.transparent,
                    child: InkWell(
                      key: Key('discount-cart-line-$key'),
                      onTap: () => onChanged(item),
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 54),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          border: selected
                              ? Border.all(
                                  color: const Color(0xFF7C3AED), width: 1.5)
                              : null,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              selected
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_off,
                              color: selected
                                  ? const Color(0xFF7C3AED)
                                  : TenantAdminColors.mutedText,
                            ),
                            const SizedBox(width: 8),
                            _Thumbnail(url: item.product.imageUrl),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.product.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: TenantAdminColors.bodyText,
                                    ),
                                  ),
                                  if (item.product.variantSummary.isNotEmpty)
                                    Text(
                                      item.product.variantSummary,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          color: TenantAdminColors.mutedText,
                                          fontSize: 12),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text('Qty ${item.quantity}',
                                style: const TextStyle(
                                    color: TenantAdminColors.mutedText)),
                            const SizedBox(width: 16),
                            Text(
                              formatLkr(item.lineTotal),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: TenantAdminColors.bodyText),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({this.url});
  final String? url;

  @override
  Widget build(BuildContext context) {
    final imageUrl = url?.trim();
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl == null || imageUrl.isEmpty
          ? const Icon(Icons.inventory_2_outlined,
              color: TenantAdminColors.mutedText, size: 20)
          : AppCachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.contain,
              errorWidget: const Icon(Icons.inventory_2_outlined,
                  color: TenantAdminColors.mutedText, size: 20),
            ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          color: TenantAdminColors.bodyText,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      );
}

BoxDecoration _cardDecoration() => BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: TenantAdminColors.border),
    );
