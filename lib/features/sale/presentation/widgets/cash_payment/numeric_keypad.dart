import 'package:flutter/material.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

class NumericKeypad extends StatelessWidget {
  const NumericKeypad({
    super.key,
    required this.onKeyTap,
  });

  final ValueChanged<String> onKeyTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: _buildStandardRow(['1', '2', '3', 'backspace'],
              isUtilityAtEnd: true),
        ),
        const SizedBox(height: TenantAdminSpacing.sm),
        Expanded(
          child:
              _buildStandardRow(['4', '5', '6', 'clear'], isUtilityAtEnd: true),
        ),
        const SizedBox(height: TenantAdminSpacing.sm),
        Expanded(
          child: _buildStandardRow(['7', '8', '9', '00'], isUtilityAtEnd: true),
        ),
        const SizedBox(height: TenantAdminSpacing.sm),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _KeypadButton(label: '.', onTap: () => onKeyTap('.')),
              ),
              const SizedBox(width: TenantAdminSpacing.sm),
              Expanded(
                child: _KeypadButton(label: '0', onTap: () => onKeyTap('0')),
              ),
              const SizedBox(width: TenantAdminSpacing.sm),
              const Expanded(child: SizedBox.shrink()),
              const SizedBox(width: TenantAdminSpacing.sm),
              const Expanded(child: SizedBox.shrink()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStandardRow(List<String> keys, {bool isUtilityAtEnd = false}) {
    return Row(
      children: List.generate(keys.length, (index) {
        final label = keys[index];
        final isUtility = isUtilityAtEnd && index == keys.length - 1;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: index == keys.length - 1 ? 0 : TenantAdminSpacing.sm,
            ),
            child: _KeypadButton(
              label: label,
              onTap: () => onKeyTap(label),
              variant: isUtility
                  ? _KeypadButtonVariant.utility
                  : _KeypadButtonVariant.standard,
            ),
          ),
        );
      }),
    );
  }
}

enum _KeypadButtonVariant { standard, utility }

class _KeypadButton extends StatelessWidget {
  const _KeypadButton({
    required this.label,
    required this.onTap,
    this.variant = _KeypadButtonVariant.standard,
  });

  final String label;
  final VoidCallback onTap;
  final _KeypadButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    final isBackspace = label == 'backspace';
    final isClear = label == 'clear';
    final isUtility = variant == _KeypadButtonVariant.utility;

    final backgroundColor = switch (variant) {
      _KeypadButtonVariant.standard => TenantAdminColors.surface,
      _KeypadButtonVariant.utility => TenantAdminColors.navySoft,
    };
    final foregroundColor =
        isUtility ? Colors.white : TenantAdminColors.bodyText;
    final borderColor =
        isUtility ? Colors.transparent : TenantAdminColors.border;

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(TenantAdminRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        child: Container(
          height: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(TenantAdminRadius.md),
            border: Border.all(color: borderColor),
          ),
          child: isBackspace
              ? Icon(Icons.backspace_outlined, size: 22, color: foregroundColor)
              : isClear
                  ? Text(
                      'C',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: foregroundColor,
                          ),
                    )
                  : Text(
                      label.toUpperCase(),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: foregroundColor,
                          ),
                    ),
        ),
      ),
    );
  }
}
