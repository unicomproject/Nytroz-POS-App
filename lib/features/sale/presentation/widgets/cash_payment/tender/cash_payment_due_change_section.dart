import 'package:flutter/material.dart';

import '../../../providers/pos_checkout_summary_provider.dart';

enum CashTenderStatus { under, exact, over }

class CashPaymentDueChangeSection extends StatelessWidget {
  const CashPaymentDueChangeSection({
    super.key,
    required this.status,
    required this.amount,
    required this.currency,
  });

  final CashTenderStatus status;
  final int amount;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final (:label, :detail, :icon, :accent) = switch (status) {
      CashTenderStatus.under => (
          label: 'AMOUNT REMAINING',
          detail: 'MORE CASH REQUIRED',
          icon: Icons.warning_amber_rounded,
          accent: colors.error,
        ),
      CashTenderStatus.exact => (
          label: 'EXACT CASH RECEIVED',
          detail: 'NO CHANGE REQUIRED',
          icon: Icons.check_rounded,
          accent: const Color(0xFF2E7D32),
        ),
      CashTenderStatus.over => (
          label: 'CHANGE DUE',
          detail: 'RETURN TO CUSTOMER',
          icon: Icons.payments_outlined,
          accent: const Color(0xFF2E7D32),
        ),
    };

    return Semantics(
      liveRegion: true,
      label: '$label ${formatCheckoutMoney(currency, amount)}. $detail',
      child: Container(
        key: ValueKey('cash-tender-status-${status.name}'),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: accent.withValues(alpha: 0.28),
            width: 1.0,
          ),
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, color: accent, size: 24),
                ),
                const SizedBox(height: 10),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: accent,
                        fontSize: 13,
                      ),
                ),
                const SizedBox(height: 3),
                Text(
                  detail,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                        color: accent.withValues(alpha: 0.9),
                        fontSize: 11,
                      ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: 140,
                  child: Divider(
                    height: 1,
                    thickness: 1,
                    color: accent.withValues(alpha: 0.2),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  formatCheckoutMoney(currency, amount),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: colors.onSurface,
                        letterSpacing: 0.2,
                        fontSize: 18,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
