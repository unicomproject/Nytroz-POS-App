import 'package:flutter/material.dart';

import '../../payment_method_style.dart';

class ContinuePaymentButton extends StatelessWidget {
  const ContinuePaymentButton(
      {super.key, required this.onPressed, required this.isLoading});
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) => SizedBox(
        key: const ValueKey('continue-payment-button'),
        width: double.infinity,
        height: 60,
        child: FilledButton(
          onPressed: isLoading ? null : onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: PaymentMethodStyle.orange,
            disabledBackgroundColor: const Color(0xFFFF9B8D),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Row(children: [
            const Expanded(
                child: Text('Continue Payment',
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                  color: Colors.white, shape: BoxShape.circle),
              child: isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.arrow_forward_rounded,
                      color: PaymentMethodStyle.orange),
            ),
          ]),
        ),
      );
}
