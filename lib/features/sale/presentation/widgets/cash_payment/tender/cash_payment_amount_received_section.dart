import 'package:flutter/material.dart';
import '../../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../../../cart/presentation/providers/pos_new_sale_cart_provider.dart';
import '../../../../domain/entities/pos_cash_payment_observability.dart';
import 'cash_payment_numeric_keypad.dart';

class CashPaymentAmountReceivedSection extends StatelessWidget {
  const CashPaymentAmountReceivedSection({
    super.key,
    required this.cashReceived,
    required this.inputBuffer,
    required this.onDigitPressed,
    required this.onDoubleZeroPressed,
    required this.onBackspacePressed,
    required this.onClearPressed,
    this.failure,
    this.onDismissFailure,
  });

  final int cashReceived;
  final String inputBuffer;
  final ValueChanged<String> onDigitPressed;
  final VoidCallback onDoubleZeroPressed;
  final VoidCallback onBackspacePressed;
  final VoidCallback onClearPressed;
  final CashPaymentFailure? failure;
  final VoidCallback? onDismissFailure;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
        border: Border.all(color: TenantAdminColors.border),
        boxShadow: TenantAdminShadows.card,
      ),
      child: Padding(
        padding: const EdgeInsets.all(TenantAdminSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'AMOUNT RECEIVED',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: TenantAdminColors.bodyText,
                  ),
            ),
            const SizedBox(height: TenantAdminSpacing.md),
            Container(
              padding: const EdgeInsets.all(TenantAdminSpacing.lg),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(TenantAdminRadius.md),
                border: Border.all(color: TenantAdminColors.border),
              ),
              child: Center(
                child: Text(
                  _formatInputDisplay(inputBuffer, cashReceived),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: TenantAdminColors.bodyText,
                      ),
                ),
              ),
            ),
            if (failure != null) ...[
              const SizedBox(height: TenantAdminSpacing.md),
              _PersistentCashError(
                failure: failure!,
                onDismiss: onDismissFailure,
              ),
            ],
            const SizedBox(height: TenantAdminSpacing.lg),
            Expanded(
              child: CashPaymentNumericKeypad(
                onDigitPressed: onDigitPressed,
                onDoubleZeroPressed: onDoubleZeroPressed,
                onBackspacePressed: onBackspacePressed,
                onClearPressed: onClearPressed,
              ),
            ),
          ],
        ),
      ),
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
          padding: const EdgeInsets.all(TenantAdminSpacing.md),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(TenantAdminRadius.md),
            border: Border.all(color: const Color(0xFFFCA5A5)),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.error_outline, color: TenantAdminColors.danger),
            const SizedBox(width: TenantAdminSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    failure.unknownOutcome
                        ? 'Payment result could not be confirmed.'
                        : 'Payment could not be completed.',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  Text(failure.message),
                  Text('Reference: ${failure.correlation.toUpperCase()}'),
                  if (failure.code != null) Text('Code: ${failure.code}'),
                  Text(failure.unknownOutcome
                      ? 'Do not retry until the transaction status has been checked.'
                      : 'Check the details or contact support before retrying.'),
                ],
              ),
            ),
            if (onDismiss != null)
              IconButton(
                tooltip: 'Dismiss payment error',
                onPressed: onDismiss,
                icon: const Icon(Icons.close),
              ),
          ]),
        ),
      );
}
