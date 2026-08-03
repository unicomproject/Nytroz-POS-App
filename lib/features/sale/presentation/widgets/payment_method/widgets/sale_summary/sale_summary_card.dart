import 'package:flutter/material.dart';

import '../../../../../../cart/presentation/providers/pos_new_sale_cart_provider.dart';
import '../../payment_method_style.dart';

class SaleSummaryCard extends StatelessWidget {
  const SaleSummaryCard({super.key, required this.cart});
  final PosNewSaleCartState cart;

  @override
  Widget build(BuildContext context) {
    final items =
        cart.itemList.fold<int>(0, (sum, line) => sum + line.quantity);
    return Container(
      key: const ValueKey('sale-summary-card'),
      padding: const EdgeInsets.all(PaymentMethodStyle.padding),
      decoration: _decoration,
      child: Column(children: [
        Row(children: [
          const Icon(Icons.shopping_cart_outlined,
              color: PaymentMethodStyle.orange, size: 27),
          const SizedBox(width: 11),
          const Expanded(
              child: Text('SALE SUMMARY',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900))),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
              decoration: BoxDecoration(
                  border: Border.all(color: PaymentMethodStyle.border),
                  borderRadius: BorderRadius.circular(8)),
              child: Text('$items Items • ${cart.itemList.length} Lines',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: PaymentMethodStyle.navy,
                      fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        const ProductTableHeader(),
        const Divider(height: 1, color: PaymentMethodStyle.border),
        Expanded(
          child: ListView.separated(
            key: const ValueKey('payment-product-list'),
            itemCount: cart.itemList.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: PaymentMethodStyle.border),
            itemBuilder: (_, index) => PaymentProductRow(
              key: ValueKey('payment-product-row-$index'),
              item: cart.itemList[index],
            ),
          ),
        ),
      ]),
    );
  }
}

class ProductTableHeader extends StatelessWidget {
  const ProductTableHeader({super.key});
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 9),
        child: Row(children: [
          Expanded(flex: 5, child: _Header('Item')),
          SizedBox(width: 52, child: _Header('Qty', center: true)),
          SizedBox(width: 106, child: _Header('Price', right: true)),
          SizedBox(width: 112, child: _Header('Total', right: true)),
        ]),
      );
}

class PaymentProductRow extends StatelessWidget {
  const PaymentProductRow({super.key, required this.item});
  final PosNewSaleCartItem item;

  @override
  Widget build(BuildContext context) {
    final image = item.product.imageUrl;
    return SizedBox(
      height: 62,
      child: Row(children: [
        Expanded(
          flex: 5,
          child: Row(children: [
            SizedBox.square(
              dimension: 42,
              child: image?.isNotEmpty == true
                  ? Image.network(image!,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const _ImageFallback())
                  : const _ImageFallback(),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  if (item.product.variantSummary.isNotEmpty)
                    Text(item.product.variantSummary,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF63718A))),
                ],
              ),
            ),
          ]),
        ),
        SizedBox(
            width: 52,
            child: Center(child: QuantityPill(value: item.quantity))),
        SizedBox(
            width: 106,
            child: Text(paymentMoney(item.product.price),
                textAlign: TextAlign.right,
                maxLines: 1,
                style: const TextStyle(color: PaymentMethodStyle.navy))),
        SizedBox(
            width: 112,
            child: Text(paymentMoney(item.lineTotal),
                textAlign: TextAlign.right,
                maxLines: 1,
                style: const TextStyle(fontWeight: FontWeight.w700))),
      ]),
    );
  }
}

class QuantityPill extends StatelessWidget {
  const QuantityPill({super.key, required this.value});
  final int value;
  @override
  Widget build(BuildContext context) => Container(
        width: 40,
        padding: const EdgeInsets.symmetric(vertical: 5),
        decoration: BoxDecoration(
            border: Border.all(color: PaymentMethodStyle.border),
            borderRadius: BorderRadius.circular(20)),
        child: Text('$value',
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: PaymentMethodStyle.navy, fontWeight: FontWeight.w700)),
      );
}

class _Header extends StatelessWidget {
  const _Header(this.text, {this.center = false, this.right = false});
  final String text;
  final bool center;
  final bool right;
  @override
  Widget build(BuildContext context) => Text(text,
      textAlign: right
          ? TextAlign.right
          : center
              ? TextAlign.center
              : TextAlign.left,
      style: const TextStyle(
          color: PaymentMethodStyle.navy, fontWeight: FontWeight.w700));
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();
  @override
  Widget build(BuildContext context) => const ColoredBox(
        color: Color(0xFFF4F6F9),
        child:
            Icon(Icons.image_not_supported_outlined, color: Color(0xFF7B8798)),
      );
}

const _decoration = BoxDecoration(
  color: Colors.white,
  border: Border.fromBorderSide(BorderSide(color: PaymentMethodStyle.border)),
  borderRadius:
      BorderRadius.all(Radius.circular(PaymentMethodStyle.panelRadius)),
);
