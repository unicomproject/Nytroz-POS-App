import 'package:flutter/material.dart';

import '../../payment_method_style.dart';

class PaymentChangeCustomerButton extends StatelessWidget {
  const PaymentChangeCustomerButton({
    super.key,
    required this.onTap,
  });

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const ValueKey('payment-change-customer-action'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: PaymentMethodStyle.border),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.person_outline_rounded,
                size: 20,
                color: PaymentMethodStyle.navy,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Change customer',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: PaymentMethodStyle.navy,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: Color(0xFF64748B),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
