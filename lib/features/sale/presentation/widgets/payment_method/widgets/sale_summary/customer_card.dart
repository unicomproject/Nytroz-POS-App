import 'package:flutter/material.dart';

import '../../../../../../cart/presentation/providers/pos_new_sale_cart_provider.dart';
import '../../payment_method_style.dart';

class CustomerCard extends StatelessWidget {
  const CustomerCard({super.key, required this.cart, this.onTap});
  final PosNewSaleCartState cart;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final customer = cart.selectedCustomer;
    return _InfoCard(
      key: const ValueKey('payment-customer-card'),
      icon: Icons.person_outline_rounded,
      title: 'Customer',
      subtitle: customer?.displayName ?? 'Walk-in Customer',
      trailing: customer == null ? 'Guest' : customer.statusLabel,
      onTap: onTap,
    );
  }
}

class PaymentInfoCard extends StatelessWidget {
  const PaymentInfoCard(
      {super.key,
      required this.icon,
      required this.title,
      required this.subtitle,
      required this.trailing,
      this.success = false});
  final IconData icon;
  final String title;
  final String subtitle;
  final String trailing;
  final bool success;
  @override
  Widget build(BuildContext context) => _InfoCard(
      icon: icon,
      title: title,
      subtitle: subtitle,
      trailing: trailing,
      success: success);
}

class _InfoCard extends StatelessWidget {
  const _InfoCard(
      {super.key,
      required this.icon,
      required this.title,
      required this.subtitle,
      required this.trailing,
      this.onTap,
      this.success = false});
  final IconData icon;
  final String title;
  final String subtitle;
  final String trailing;
  final bool success;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            constraints: const BoxConstraints(minHeight: 70),
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            decoration: BoxDecoration(
              color:
                  success ? const Color(0xFFF6FCF7) : const Color(0xFFF8FAFC),
              border: Border.all(
                color: success
                    ? const Color(0xFFC8E6C9)
                    : PaymentMethodStyle.border,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(children: [
              CircleAvatar(
                backgroundColor:
                    success ? const Color(0xFFE8FAED) : const Color(0xFFEAF1FF),
                child: Icon(icon,
                    color: success
                        ? const Color(0xFF079529)
                        : const Color(0xFF1464F4)),
              ),
              const SizedBox(width: 11),
              Expanded(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomLeft,
                        child: Text(title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: success
                                    ? const Color(0xFF079529)
                                    : Colors.black87,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                    Expanded(
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: Text(subtitle,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ])),
              Flexible(
                child: Text(trailing,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                        color: success
                            ? const Color(0xFF079529)
                            : PaymentMethodStyle.navy,
                        fontWeight: FontWeight.w700)),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right_rounded),
              ],
            ]),
          ),
        ),
      );
}
