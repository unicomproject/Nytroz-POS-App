import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nytroz_pos/core/access/effective_permission_set.dart';
import 'package:nytroz_pos/core/access/permission_access_providers.dart';
import 'package:nytroz_pos/core/access/pos_payment_permission_visibility.dart';
import '../../../../domain/entities/pos_cash_payment_observability.dart';
import '../../../providers/pos_cash_payment_provider.dart';
import '../../payment_method/payment_method_style.dart';
import '../actions/cash_payment_action_button.dart';
import 'cash_payment_amount_received_section.dart';
import 'cash_payment_due_change_section.dart';
import 'cash_payment_info_card.dart';
import 'cash_payment_numeric_keypad.dart';
import 'cash_payment_quick_amounts_section.dart';

class CashPaymentTenderPanel extends ConsumerWidget {
  const CashPaymentTenderPanel({
    super.key,
    required this.totalDue,
    required this.currency,
    required this.cashReceived,
    required this.inputBuffer,
    required this.quickAmounts,
    required this.selectedQuickAmount,
    required this.onBack,
    required this.onQuickAmountSelected,
    required this.onDigitPressed,
    required this.onDoubleZeroPressed,
    required this.onBackspacePressed,
    required this.onClearPressed,
    required this.isSubmitting,
    required this.canCompleteSale,
    required this.onCompleteSalePressed,
    this.failure,
    this.onDismissFailure,
  });

  final int totalDue;
  final String currency;
  final int cashReceived;
  final String inputBuffer;
  final List<int> quickAmounts;
  final int? selectedQuickAmount;
  final VoidCallback onBack;
  final ValueChanged<int> onQuickAmountSelected;
  final ValueChanged<String> onDigitPressed;
  final VoidCallback onDoubleZeroPressed;
  final VoidCallback onBackspacePressed;
  final VoidCallback onClearPressed;
  final bool isSubmitting;
  final bool canCompleteSale;
  final VoidCallback onCompleteSalePressed;
  final CashPaymentFailure? failure;
  final VoidCallback? onDismissFailure;

  KeyEventResult _onKeyEvent(
    EffectivePermissionSet permissions,
    KeyEvent event,
  ) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    final canEnter =
        PosPaymentPermissionVisibility.canEnterCashAmountReceived(permissions);
    if (!canEnter) {
      // Swallow digit-like keys so denied entry cannot mutate tender.
      if (_isTenderMutatingKey(event.logicalKey)) {
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.backspace ||
        key == LogicalKeyboardKey.delete) {
      if (PosPaymentPermissionVisibility.canShowNumpadBackspace(permissions)) {
        onBackspacePressed();
        return KeyEventResult.handled;
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.escape) {
      if (PosPaymentPermissionVisibility.canShowNumpadClear(permissions)) {
        onClearPressed();
        return KeyEventResult.handled;
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      if (PosPaymentPermissionVisibility.canCompleteCashSale(permissions) &&
          canCompleteSale &&
          !isSubmitting) {
        onCompleteSalePressed();
      }
      return KeyEventResult.handled;
    }

    final digit = _digitFromKey(key);
    if (digit == null) {
      return KeyEventResult.ignored;
    }
    if (!PosPaymentPermissionVisibility.canShowNumpadContainer(permissions) ||
        !PosPaymentPermissionVisibility.canShowNumpadDigit(
          permissions,
          digit,
        )) {
      return KeyEventResult.handled;
    }
    if (digit == '00') {
      onDoubleZeroPressed();
    } else {
      onDigitPressed(digit);
    }
    return KeyEventResult.handled;
  }

  static bool _isTenderMutatingKey(LogicalKeyboardKey key) {
    return _digitFromKey(key) != null ||
        key == LogicalKeyboardKey.backspace ||
        key == LogicalKeyboardKey.delete ||
        key == LogicalKeyboardKey.escape ||
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter;
  }

  static String? _digitFromKey(LogicalKeyboardKey key) {
    final map = <LogicalKeyboardKey, String>{
      LogicalKeyboardKey.digit0: '0',
      LogicalKeyboardKey.digit1: '1',
      LogicalKeyboardKey.digit2: '2',
      LogicalKeyboardKey.digit3: '3',
      LogicalKeyboardKey.digit4: '4',
      LogicalKeyboardKey.digit5: '5',
      LogicalKeyboardKey.digit6: '6',
      LogicalKeyboardKey.digit7: '7',
      LogicalKeyboardKey.digit8: '8',
      LogicalKeyboardKey.digit9: '9',
      LogicalKeyboardKey.numpad0: '0',
      LogicalKeyboardKey.numpad1: '1',
      LogicalKeyboardKey.numpad2: '2',
      LogicalKeyboardKey.numpad3: '3',
      LogicalKeyboardKey.numpad4: '4',
      LogicalKeyboardKey.numpad5: '5',
      LogicalKeyboardKey.numpad6: '6',
      LogicalKeyboardKey.numpad7: '7',
      LogicalKeyboardKey.numpad8: '8',
      LogicalKeyboardKey.numpad9: '9',
      LogicalKeyboardKey.period: '.',
      LogicalKeyboardKey.numpadDecimal: '.',
    };
    return map[key];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissions = ref.watch(effectivePermissionSetProvider);
    final changeDue = cashPaymentChangeDue(cashReceived, totalDue);
    final remaining = (totalDue - cashReceived).clamp(0, totalDue);
    final status = cashReceived < totalDue
        ? CashTenderStatus.under
        : cashReceived == totalDue
            ? CashTenderStatus.exact
            : CashTenderStatus.over;
    final colors = Theme.of(context).colorScheme;

    final showAmountView =
        PosPaymentPermissionVisibility.canShowCashAmountReceivedView(
      permissions,
    );
    final showDue =
        PosPaymentPermissionVisibility.canShowCashDueAmount(permissions);
    final showChange =
        PosPaymentPermissionVisibility.canShowCashChangeDue(permissions);
    final showNumpad =
        PosPaymentPermissionVisibility.canShowNumpadContainer(permissions);
    final canEnter =
        PosPaymentPermissionVisibility.canEnterCashAmountReceived(permissions);
    final canCompleteUi =
        PosPaymentPermissionVisibility.canCompleteCashSale(permissions);
    final filteredQuick = PosPaymentPermissionVisibility.filterQuickAmounts(
      permissions,
      amounts: quickAmounts,
      exactAmount: totalDue,
    );

    return Focus(
      autofocus: true,
      onKeyEvent: (_, event) => _onKeyEvent(permissions, event),
      child: Container(
        key: const ValueKey('cash-payment-tender-panel'),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(PaymentMethodStyle.panelRadius),
          border: Border.all(color: colors.outlineVariant),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _CashPaymentPanelHeader(onBack: onBack),
            if (showAmountView || showDue) ...[
              const SizedBox(height: 12),
              CashPaymentAmountReceivedSection(
                cashReceived: cashReceived,
                inputBuffer: inputBuffer,
                totalDue: totalDue,
                currency: currency,
                showAmountView: showAmountView,
                showDueAmount: showDue,
                onClear: canEnter &&
                        PosPaymentPermissionVisibility.canShowNumpadClear(
                          permissions,
                        )
                    ? onClearPressed
                    : null,
                failure: failure,
                onDismissFailure: onDismissFailure,
              ),
            ],
            if (filteredQuick.isNotEmpty) ...[
              const SizedBox(height: 10),
              CashPaymentQuickAmountsSection(
                amounts: filteredQuick,
                selectedAmount: selectedQuickAmount,
                onAmountSelected: canEnter ? onQuickAmountSelected : (_) {},
                exactAmount: totalDue,
                currency: currency,
              ),
            ],
            const SizedBox(height: 10),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (showNumpad)
                    Expanded(
                      flex: 62,
                      child: CashPaymentNumericKeypad(
                        permissions: permissions,
                        enabled: canEnter,
                        onDigitPressed: onDigitPressed,
                        onDoubleZeroPressed: onDoubleZeroPressed,
                        onBackspacePressed: onBackspacePressed,
                        onClearPressed: onClearPressed,
                      ),
                    ),
                  if (showNumpad) const SizedBox(width: 12),
                  Expanded(
                    flex: showNumpad ? 38 : 100,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (showChange)
                          Expanded(
                            child: CashPaymentDueChangeSection(
                              status: status,
                              amount: status == CashTenderStatus.under
                                  ? remaining
                                  : changeDue,
                              currency: currency,
                            ),
                          )
                        else
                          const Spacer(),
                        if (showChange) const SizedBox(height: 10),
                        CashPaymentInfoCard(status: status),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (canCompleteUi) ...[
              const SizedBox(height: 12),
              CashPaymentActionButton(
                label: 'COMPLETE SALE',
                subtitle: 'Complete payment and proceed',
                icon: Icons.check_rounded,
                isPrimary: true,
                isLoading: isSubmitting,
                onPressed: canCompleteSale && !isSubmitting
                    ? onCompleteSalePressed
                    : null,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CashPaymentPanelHeader extends StatelessWidget {
  const _CashPaymentPanelHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: colors.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child:
              Icon(Icons.payments_outlined, color: colors.onPrimary, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CASH PAYMENT',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                'Enter the amount received from customer.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontSize: 12,
                    ),
              ),
            ],
          ),
        ),
        OutlinedButton.icon(
          key: const ValueKey('cash-back-to-payment-methods'),
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded, size: 17),
          label: const Text('Back to Payment Methods'),
          style: OutlinedButton.styleFrom(
            foregroundColor: colors.primary,
            side: BorderSide(
              color: colors.primary.withValues(alpha: 0.5),
              width: 1.2,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
        ),
      ],
    );
  }
}
