import 'package:flutter/material.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

class CustomerNumericKeypad extends StatelessWidget {
  const CustomerNumericKeypad({
    super.key,
    required this.enabled,
    required this.onDigit,
    required this.onBackspace,
    required this.onClear,
    this.onDialCode,
  });

  final bool enabled;
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final VoidCallback onClear;
  final ValueChanged<String>? onDialCode;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      key: const ValueKey('checkout-customer-numeric-keypad'),
      builder: (context, constraints) {
        const headerHeight = 40.0;
        const headerGap = TenantAdminSpacing.md;
        const keyGap = 10.0;
        const verticalSafetyMargin = 8.0;
        const preferredKeyHeight = 72.0;
        final keyHeight = constraints.maxHeight.isFinite
            ? ((constraints.maxHeight -
                        headerHeight -
                        headerGap -
                        keyGap * 3 -
                        verticalSafetyMargin) /
                    4)
                .clamp(44.0, preferredKeyHeight)
                .toDouble()
            : preferredKeyHeight;

        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            key: const ValueKey('checkout-customer-numeric-keypad-content'),
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: TenantAdminColors.subtleBackground,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.apps_rounded,
                        color: TenantAdminColors.navy,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: TenantAdminSpacing.md),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Enter Mobile Number',
                            style: TextStyle(
                              color: TenantAdminColors.navy,
                              fontWeight: FontWeight.w700,
                              fontSize: 17,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Use the keypad to enter mobile number',
                            style: TextStyle(
                              color: TenantAdminColors.mutedText,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: headerGap),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Column 1: 1, 4 / GHI, 7 / PQRS, +94
                    Expanded(
                      child: Column(
                        children: [
                          _digitKey(
                            '1',
                            null,
                            enabled ? () => onDigit('1') : null,
                            keyHeight,
                          ),
                          const SizedBox(height: keyGap),
                          _digitKey(
                            '4',
                            'GHI',
                            enabled ? () => onDigit('4') : null,
                            keyHeight,
                          ),
                          const SizedBox(height: keyGap),
                          _digitKey(
                            '7',
                            'PQRS',
                            enabled ? () => onDigit('7') : null,
                            keyHeight,
                          ),
                          const SizedBox(height: keyGap),
                          _dialCodeKey(
                            enabled ? () => onDialCode?.call('+94') : null,
                            keyHeight,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: keyGap),
                    // Column 2: 2 / ABC, 5 / JKL, 8 / TUV, 0 / +
                    Expanded(
                      child: Column(
                        children: [
                          _digitKey(
                            '2',
                            'ABC',
                            enabled ? () => onDigit('2') : null,
                            keyHeight,
                          ),
                          const SizedBox(height: keyGap),
                          _digitKey(
                            '5',
                            'JKL',
                            enabled ? () => onDigit('5') : null,
                            keyHeight,
                          ),
                          const SizedBox(height: keyGap),
                          _digitKey(
                            '8',
                            'TUV',
                            enabled ? () => onDigit('8') : null,
                            keyHeight,
                          ),
                          const SizedBox(height: keyGap),
                          _digitKey(
                            '0',
                            '+',
                            enabled ? () => onDigit('0') : null,
                            keyHeight,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: keyGap),
                    // Column 3: 3 / DEF, 6 / MNO, 9 / WXYZ, empty
                    Expanded(
                      child: Column(
                        children: [
                          _digitKey(
                            '3',
                            'DEF',
                            enabled ? () => onDigit('3') : null,
                            keyHeight,
                          ),
                          const SizedBox(height: keyGap),
                          _digitKey(
                            '6',
                            'MNO',
                            enabled ? () => onDigit('6') : null,
                            keyHeight,
                          ),
                          const SizedBox(height: keyGap),
                          _digitKey(
                            '9',
                            'WXYZ',
                            enabled ? () => onDigit('9') : null,
                            keyHeight,
                          ),
                          const SizedBox(height: keyGap),
                          SizedBox(height: keyHeight),
                        ],
                      ),
                    ),
                    const SizedBox(width: keyGap),
                    // Column 4: Backspace, CLEAR (tall spanning rows 2 & 3), empty
                    Expanded(
                      child: Column(
                        children: [
                          _backspaceKey(
                            enabled ? onBackspace : null,
                            keyHeight,
                          ),
                          const SizedBox(height: keyGap),
                          _clearKey(
                            enabled ? onClear : null,
                            keyHeight * 2 + keyGap,
                          ),
                          const SizedBox(height: keyGap),
                          SizedBox(height: keyHeight),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _digitKey(
    String digit,
    String? letters,
    VoidCallback? onTap,
    double height,
  ) =>
      _KeypadButton(
        height: height,
        onPressed: onTap,
        semanticsLabel: 'Number $digit${letters != null ? ', $letters' : ''}',
        child: letters == null
            ? Text(
                digit,
                style: const TextStyle(
                  color: TenantAdminColors.navy,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    digit,
                    style: const TextStyle(
                      color: TenantAdminColors.navy,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    letters,
                    style: const TextStyle(
                      color: TenantAdminColors.mutedText,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
      );

  Widget _dialCodeKey(VoidCallback? onTap, double height) => _KeypadButton(
        height: height,
        onPressed: onTap,
        semanticsLabel: 'Dial code +94',
        child: const Text(
          '+94',
          style: TextStyle(
            color: TenantAdminColors.navy,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
      );

  Widget _backspaceKey(VoidCallback? onTap, double height) => _KeypadButton(
        height: height,
        onPressed: onTap,
        semanticsLabel: 'Backspace mobile number',
        child: const Icon(
          Icons.backspace_outlined,
          color: TenantAdminColors.navy,
          size: 26,
        ),
      );

  Widget _clearKey(VoidCallback? onTap, double height) => _KeypadButton(
        height: height,
        onPressed: onTap,
        semanticsLabel: 'Clear mobile number',
        child: const Text(
          'CLEAR',
          style: TextStyle(
            color: TenantAdminColors.danger,
            fontSize: 16.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
      );
}

class _KeypadButton extends StatelessWidget {
  const _KeypadButton({
    required this.onPressed,
    required this.child,
    this.semanticsLabel,
    this.height,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final String? semanticsLabel;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final content = Material(
      color: TenantAdminColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: TenantAdminColors.border, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: SizedBox(
          height: height ?? 58,
          child: Center(child: child),
        ),
      ),
    );

    if (semanticsLabel != null) {
      return Semantics(
        button: true,
        label: semanticsLabel,
        child: content,
      );
    }
    return content;
  }
}

class CustomerNameKeyboard extends StatelessWidget {
  const CustomerNameKeyboard({
    super.key,
    required this.enabled,
    required this.value,
    required this.onChanged,
  });

  final bool enabled;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const rows = ['QWERTYUIOP', 'ASDFGHJKL', 'ZXCVBNM'];
    return Column(
      key: const ValueKey('checkout-customer-name-keyboard'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: TenantAdminColors.subtleBackground,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.keyboard_rounded,
                color: TenantAdminColors.navy,
                size: 18,
              ),
            ),
            const SizedBox(width: TenantAdminSpacing.md),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Customer Name Keyboard',
                    style: TextStyle(
                      color: TenantAdminColors.navy,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Use the on-screen keyboard to enter customer name',
                    style: TextStyle(
                      color: TenantAdminColors.mutedText,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: TenantAdminSpacing.lg),
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: TenantAdminSpacing.xs),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: row
                  .split('')
                  .map(
                    (letter) => Flexible(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Semantics(
                          button: true,
                          label: 'Letter $letter',
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: const BorderSide(
                                color: TenantAdminColors.border,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: enabled && value.length < 150
                                ? () => onChanged('$value$letter')
                                : null,
                            child: Text(
                              letter,
                              style: const TextStyle(
                                color: TenantAdminColors.navy,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        const SizedBox(height: TenantAdminSpacing.xs),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: Semantics(
                button: true,
                label: 'Space',
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: TenantAdminColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: enabled && value.isNotEmpty && value.length < 150
                      ? () => onChanged('$value ')
                      : null,
                  child: const Text(
                    'SPACE',
                    style: TextStyle(
                      color: TenantAdminColors.navy,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: TenantAdminSpacing.sm),
            Expanded(
              child: Semantics(
                button: true,
                label: 'Backspace customer name',
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: TenantAdminColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: enabled && value.isNotEmpty
                      ? () => onChanged(value.substring(0, value.length - 1))
                      : null,
                  child: const Icon(
                    Icons.backspace_outlined,
                    color: TenantAdminColors.navy,
                  ),
                ),
              ),
            ),
            const SizedBox(width: TenantAdminSpacing.sm),
            Expanded(
              child: Semantics(
                button: true,
                label: 'Clear customer name',
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: TenantAdminColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed:
                      enabled && value.isNotEmpty ? () => onChanged('') : null,
                  child: const Text(
                    'CLEAR',
                    style: TextStyle(
                      color: TenantAdminColors.danger,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
