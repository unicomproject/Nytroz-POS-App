import 'package:flutter/material.dart';

import '../../../../cart/presentation/providers/pos_new_sale_cart_provider.dart';
import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../providers/pos_cash_payment_provider.dart';

class CashReceivedSection extends StatelessWidget {
  const CashReceivedSection({
    super.key,
    required this.total,
    required this.cashReceived,
    required this.inputBuffer,
    required this.onClear,
  });

  final int total;
  final int cashReceived;
  final String inputBuffer;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final changeDue = cashPaymentChangeDue(cashReceived, total);
    final isSufficient = changeDue >= 0;

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
              'Cash Received',
              style: TenantAdminTextStyles.sectionTitle(context),
            ),
            const SizedBox(height: TenantAdminSpacing.lg),
            _CashAmountField(
              displayValue: _formatInputDisplay(inputBuffer, cashReceived),
              onClear: onClear,
            ),
            const SizedBox(height: TenantAdminSpacing.lg),
            _ChangeDueBanner(
              changeDue: changeDue,
              isSufficient: isSufficient,
            ),
            const SizedBox(height: TenantAdminSpacing.md),
            _HelperMessage(
              changeDue: changeDue,
              isSufficient: isSufficient,
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

class _CashAmountField extends StatelessWidget {
  const _CashAmountField({
    required this.displayValue,
    required this.onClear,
  });

  final String displayValue;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: TenantAdminColors.background,
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        border: Border.all(color: TenantAdminColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: TenantAdminSpacing.lg,
          vertical: TenantAdminSpacing.md,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                displayValue,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: TenantAdminColors.bodyText,
                    ),
              ),
            ),
            TextButton(
              onPressed: onClear,
              child: const Text('Clear'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChangeDueBanner extends StatelessWidget {
  const _ChangeDueBanner({
    required this.changeDue,
    required this.isSufficient,
  });

  final int changeDue;
  final bool isSufficient;

  @override
  Widget build(BuildContext context) {
    final label = isSufficient
        ? 'Change Due: ${formatLkr(changeDue.clamp(0, changeDue))}'
        : 'Remaining: ${formatLkr(changeDue.abs())}';

    return Text(
      label,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: isSufficient
                ? TenantAdminColors.success
                : TenantAdminColors.danger,
          ),
    );
  }
}

class _HelperMessage extends StatelessWidget {
  const _HelperMessage({
    required this.changeDue,
    required this.isSufficient,
  });

  final int changeDue;
  final bool isSufficient;

  @override
  Widget build(BuildContext context) {
    final message = switch (changeDue) {
      < 0 =>
        'Add ${formatLkr(changeDue.abs())} more before confirming cash payment.',
      0 => 'Exact amount received. No change is due.',
      _ => 'Return ${formatLkr(changeDue)} change to the customer.',
    };

    final color = isSufficient
        ? TenantAdminColors.success
        : TenantAdminColors.warning;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(TenantAdminSpacing.md),
      decoration: BoxDecoration(
        color: isSufficient
            ? const Color(0xFFF0FDF4)
            : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        border: Border.all(
          color: isSufficient
              ? const Color(0xFFBBF7D0)
              : const Color(0xFFFDE68A),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isSufficient ? Icons.check_circle_outline : Icons.info_outline,
            color: color,
            size: 20,
          ),
          const SizedBox(width: TenantAdminSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: TenantAdminColors.bodyText,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
