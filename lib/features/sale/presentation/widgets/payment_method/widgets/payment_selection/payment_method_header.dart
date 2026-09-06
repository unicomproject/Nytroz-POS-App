import 'package:flutter/material.dart';

import '../../payment_method_style.dart';

class PaymentMethodHeader extends StatelessWidget {
  const PaymentMethodHeader({
    super.key,
    required this.onBackToSale,
  });

  final VoidCallback onBackToSale;

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.credit_card_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                'SELECT PAYMENT METHOD',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: PaymentMethodStyle.navy,
                  letterSpacing: -0.2,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Choose how you would like to receive payment.',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        OutlinedButton.icon(
          key: const ValueKey('payment-back-to-sale-button'),
          onPressed: onBackToSale,
          icon: Icon(
            Icons.arrow_back_rounded,
            size: 16,
            color: primaryColor,
          ),
          label: Text(
            'Back to Sale',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: primaryColor,
            ),
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            side: BorderSide(color: primaryColor.withValues(alpha: 0.5)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ],
    );
  }
}
