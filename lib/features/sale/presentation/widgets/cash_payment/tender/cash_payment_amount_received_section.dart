import 'package:flutter/material.dart';
import '../../../../domain/entities/pos_cash_payment_observability.dart';
import '../../../providers/pos_checkout_summary_provider.dart';
import '../../payment_method/payment_method_style.dart';

class CashPaymentAmountReceivedSection extends StatelessWidget {
  const CashPaymentAmountReceivedSection({
    super.key,
    required this.cashReceived,
    required this.inputBuffer,
    required this.totalDue,
    this.currency = 'LKR',
    this.showAmountView = true,
    this.showDueAmount = true,
    this.onClear,
    this.failure,
    this.onDismissFailure,
  });

  final int cashReceived;
  final String inputBuffer;
  final int totalDue;
  final String currency;
  final bool showAmountView;
  final bool showDueAmount;
  final VoidCallback? onClear;
  final CashPaymentFailure? failure;
  final VoidCallback? onDismissFailure;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final currencyLabel = currency.trim().isNotEmpty ? currency.trim() : 'LKR';

    if (!showAmountView && !showDueAmount) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (showAmountView)
              const Text(
                'AMOUNT RECEIVED',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF64748B),
                  fontSize: 12,
                  letterSpacing: 0.3,
                ),
              )
            else
              const SizedBox.shrink(),
            if (showDueAmount)
              Text.rich(
                TextSpan(
                  text: 'Due: ',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  children: [
                    TextSpan(
                      text: formatCheckoutMoney(currency, totalDue),
                      style: TextStyle(
                        color: colors.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        if (showAmountView) ...[
        const SizedBox(height: 8),
        Container(
          key: const ValueKey('cash-amount-received-field'),
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: PaymentMethodStyle.border),
          ),
          child: Row(
            children: [
              Text(
                currencyLabel,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  _formatAmountOnly(inputBuffer, cashReceived),
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    color: PaymentMethodStyle.navy,
                    letterSpacing: -0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (onClear != null)
                IconButton(
                  key: const ValueKey('cash-amount-reset'),
                  onPressed: onClear,
                  tooltip: 'Reset cash amount',
                  icon: const Icon(
                    Icons.cancel_outlined,
                    size: 24,
                    color: Color(0xFF94A3B8),
                  ),
                ),
            ],
          ),
        ),
        ],
        if (failure != null) ...[
          const SizedBox(height: 6),
          _PersistentCashError(
            failure: failure!,
            onDismiss: onDismissFailure,
          ),
        ],
      ],
    );
  }

  String _formatAmountOnly(String buffer, int parsedAmount) {
    final formattedWithPrefix =
        formatCheckoutMoney('', buffer.isEmpty ? 0 : parsedAmount);
    return formattedWithPrefix.replaceFirst('LKR ', '').trim();
  }
}

class _PersistentCashError extends StatelessWidget {
  const _PersistentCashError({required this.failure, this.onDismiss});

  final CashPaymentFailure failure;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      label:
          '${failure.unknownOutcome ? 'Payment result could not be confirmed' : 'Payment could not be completed'}. Reference ${failure.correlation}.',
      child: Container(
        key: const ValueKey('cash-payment-persistent-error'),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colors.errorContainer,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colors.error.withValues(alpha: 0.4)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.error_outline,
              color: colors.error,
              size: 16,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    failure.unknownOutcome
                        ? 'Payment result could not be confirmed.'
                        : 'Payment could not be completed.',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    failure.message,
                    style: const TextStyle(fontSize: 10),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Reference: ${failure.correlation.toUpperCase()}',
                    style: const TextStyle(fontSize: 10),
                  ),
                  if (failure.code != null)
                    Text(
                      'Code: ${failure.code}',
                      style: const TextStyle(fontSize: 10),
                    ),
                  Text(
                    failure.unknownOutcome
                        ? 'Do not retry until the transaction status has been checked.'
                        : 'Check the details or contact support before retrying.',
                    style: const TextStyle(fontSize: 10),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (onDismiss != null)
              IconButton(
                tooltip: 'Dismiss payment error',
                onPressed: onDismiss,
                iconSize: 16,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 24,
                  minHeight: 24,
                ),
                icon: const Icon(Icons.close),
              ),
          ],
        ),
      ),
    );
  }
}
