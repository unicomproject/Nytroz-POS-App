import 'package:flutter/material.dart';
import '../../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../../../cart/presentation/providers/pos_new_sale_cart_provider.dart';
import '../../../../domain/entities/pos_cash_payment_observability.dart';

class CashPaymentAmountReceivedSection extends StatelessWidget {
  const CashPaymentAmountReceivedSection({
    super.key,
    required this.cashReceived,
    required this.inputBuffer,
    required this.totalDue,
    this.failure,
    this.onDismissFailure,
  });

  final int cashReceived;
  final String inputBuffer;
  final int totalDue;
  final CashPaymentFailure? failure;
  final VoidCallback? onDismissFailure;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Amount Received',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: TenantAdminColors.mutedText,
                    fontSize: 11,
                  ),
            ),
            const Spacer(),
            Icon(
              Icons.info_outline,
              size: 12,
              color: TenantAdminColors.mutedText.withValues(alpha: 0.8),
            ),
            const SizedBox(width: 4),
            Text(
              'Due: ${formatLkr(totalDue)}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: TenantAdminColors.mutedText,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          _formatInputDisplay(inputBuffer, cashReceived),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: TenantAdminColors.bodyText,
                fontSize: 26,
                height: 1.1,
              ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
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

  String _formatInputDisplay(String buffer, int parsedAmount) {
    if (buffer.isEmpty) {
      return formatLkr(0);
    }

    if (buffer.contains('.')) {
      final parts = buffer.split('.');
      final whole = int.tryParse(parts.first) ?? parsedAmount;
      final fraction = parts.length > 1 ? parts[1] : '';
      final paddedFraction = '${fraction}00'.substring(0, 2);
      return 'LKR ${_formatNumber(whole)}.$paddedFraction';
    }

    return formatLkr(parsedAmount);
  }

  String _formatNumber(int value) {
    final raw = value.toString();
    final buffer = StringBuffer();

    for (var index = 0; index < raw.length; index += 1) {
      final digitsFromEnd = raw.length - index;
      buffer.write(raw[index]);
      if (digitsFromEnd > 1 && digitsFromEnd % 3 == 1) {
        buffer.write(',');
      }
    }

    return buffer.toString();
  }
}

class _PersistentCashError extends StatelessWidget {
  const _PersistentCashError({required this.failure, this.onDismiss});

  final CashPaymentFailure failure;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) => Semantics(
        liveRegion: true,
        label:
            '${failure.unknownOutcome ? 'Payment result could not be confirmed' : 'Payment could not be completed'}. Reference ${failure.correlation}.',
        child: Container(
          key: const ValueKey('cash-payment-persistent-error'),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
            border: Border.all(color: const Color(0xFFFCA5A5)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.error_outline,
                color: TenantAdminColors.danger,
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
