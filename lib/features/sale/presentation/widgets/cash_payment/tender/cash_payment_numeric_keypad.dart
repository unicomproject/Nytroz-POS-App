import 'package:flutter/material.dart';

import 'package:nytroz_pos/core/access/effective_permission_set.dart';
import 'package:nytroz_pos/core/access/pos_payment_permission_visibility.dart';
import '../../payment_method/payment_method_style.dart';

class CashPaymentNumericKeypad extends StatelessWidget {
  const CashPaymentNumericKeypad({
    super.key,
    required this.permissions,
    required this.onDigitPressed,
    required this.onDoubleZeroPressed,
    required this.onBackspacePressed,
    required this.onClearPressed,
    this.enabled = true,
  });

  final EffectivePermissionSet permissions;
  final ValueChanged<String> onDigitPressed;
  final VoidCallback onDoubleZeroPressed;
  final VoidCallback onBackspacePressed;
  final VoidCallback onClearPressed;
  final bool enabled;

  static const double _gap = 8.0;

  /// Canonical digit order for reflow (denied keys omitted — no blank slots).
  static const _digitOrder = [
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '00',
    '0',
    '.',
  ];

  @override
  Widget build(BuildContext context) {
    final digits = _digitOrder
        .where(
          (d) =>
              PosPaymentPermissionVisibility.canShowNumpadDigit(permissions, d),
        )
        .toList(growable: false);
    final showBackspace =
        PosPaymentPermissionVisibility.canShowNumpadBackspace(permissions);
    final showClear =
        PosPaymentPermissionVisibility.canShowNumpadClear(permissions);

    if (digits.isEmpty && !showBackspace && !showClear) {
      return const SizedBox.shrink();
    }

    final digitRows = <List<String>>[];
    for (var i = 0; i < digits.length; i += 3) {
      digitRows.add(digits.sublist(i, (i + 3).clamp(0, digits.length)));
    }

    final sideKeys = <Widget>[
      if (showBackspace) Expanded(child: _backspaceKey(context)),
      if (showBackspace && showClear) const SizedBox(height: _gap),
      if (showClear) Expanded(child: _clearKey(context)),
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 3,
          child: digitRows.isEmpty
              ? const SizedBox.shrink()
              : Column(
                  children: [
                    for (var r = 0; r < digitRows.length; r++) ...[
                      if (r > 0) const SizedBox(height: _gap),
                      Expanded(
                        child: Row(
                          children: [
                            for (var c = 0; c < digitRows[r].length; c++) ...[
                              if (c > 0) const SizedBox(width: _gap),
                              _digitOrSpecial(digitRows[r][c], context),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
        ),
        if (sideKeys.isNotEmpty) ...[
          const SizedBox(width: _gap),
          Expanded(
            flex: 1,
            child: Column(children: sideKeys),
          ),
        ],
      ],
    );
  }

  Widget _digitOrSpecial(String label, BuildContext context) {
    if (label == '00') {
      return _key(
        key: const ValueKey('cash-key-00'),
        label: '00',
        onTap: enabled ? onDoubleZeroPressed : null,
        context: context,
      );
    }
    if (label == '.') {
      return _key(
        key: const ValueKey('cash-key-dot'),
        label: '.',
        onTap: enabled ? () => onDigitPressed('.') : null,
        context: context,
      );
    }
    return _digit(label, context);
  }

  Widget _digit(String digit, BuildContext context) => _key(
        key: ValueKey('cash-key-$digit'),
        label: digit,
        onTap: enabled ? () => onDigitPressed(digit) : null,
        context: context,
      );

  Widget _key({
    required Key key,
    required String label,
    required VoidCallback? onTap,
    required BuildContext context,
  }) {
    return Expanded(
      child: Material(
        key: key,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: PaymentMethodStyle.border),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: PaymentMethodStyle.navy,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _backspaceKey(BuildContext context) {
    return Material(
      key: const ValueKey('cash-key-backspace'),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: PaymentMethodStyle.border),
      ),
      child: InkWell(
        onTap: enabled ? onBackspacePressed : null,
        borderRadius: BorderRadius.circular(10),
        child: Semantics(
          button: true,
          label: 'Backspace',
          child: const Center(
            child: Icon(
              Icons.backspace_outlined,
              size: 22,
              color: Color(0xFF475569),
            ),
          ),
        ),
      ),
    );
  }

  Widget _clearKey(BuildContext context) {
    return Material(
      key: const ValueKey('cash-key-clear'),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: PaymentMethodStyle.border),
      ),
      child: InkWell(
        onTap: enabled ? onClearPressed : null,
        borderRadius: BorderRadius.circular(10),
        child: Semantics(
          button: true,
          label: 'Clear',
          child: const Center(
            child: Text(
              'C',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Color(0xFFDC2626),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
