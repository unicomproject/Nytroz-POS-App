import 'package:flutter/material.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

class NumericKeypad extends StatelessWidget {
  const NumericKeypad({
    super.key,
    required this.onKeyTap,
  });

  final ValueChanged<String> onKeyTap;

  static const _keys = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['.', '0', 'backspace'],
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _keys.map((row) {
        return Padding(
          padding: const EdgeInsets.only(bottom: TenantAdminSpacing.sm),
          child: Row(
            children: row.map((key) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: TenantAdminSpacing.xs,
                  ),
                  child: _KeypadButton(
                    label: key,
                    onTap: () => onKeyTap(key),
                  ),
                ),
              );
            }).toList(growable: false),
          ),
        );
      }).toList(growable: false),
    );
  }
}

class _KeypadButton extends StatelessWidget {
  const _KeypadButton({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isBackspace = label == 'backspace';

    return Material(
      color: TenantAdminColors.surface,
      borderRadius: BorderRadius.circular(TenantAdminRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        child: Container(
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(TenantAdminRadius.md),
            border: Border.all(color: TenantAdminColors.border),
          ),
          child: isBackspace
              ? const Icon(Icons.backspace_outlined, size: 22)
              : Text(
                  label,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: TenantAdminColors.bodyText,
                      ),
                ),
        ),
      ),
    );
  }
}
