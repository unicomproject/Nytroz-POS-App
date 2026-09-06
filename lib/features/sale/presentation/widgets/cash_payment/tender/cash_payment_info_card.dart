import 'package:flutter/material.dart';

import 'cash_payment_due_change_section.dart';

class CashPaymentInfoCard extends StatelessWidget {
  const CashPaymentInfoCard({super.key, required this.status});

  final CashTenderStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final message = switch (status) {
      CashTenderStatus.under =>
        'Enter at least the full amount due to complete the sale.',
      CashTenderStatus.exact =>
        'Exact amount received.\nYou can now complete the sale.',
      CashTenderStatus.over =>
        'Return the displayed change after the sale is confirmed.',
    };
    return Semantics(
      liveRegion: true,
      child: Container(
        key: const ValueKey('cash-payment-info-card'),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: colors.surfaceContainerLowest,
          border: Border.all(
            color: colors.outlineVariant.withValues(alpha: 0.65),
            width: 1.0,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(
              Icons.info_outline_rounded,
              size: 20,
              color: Color(0xFF1976D2),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontSize: 11,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
