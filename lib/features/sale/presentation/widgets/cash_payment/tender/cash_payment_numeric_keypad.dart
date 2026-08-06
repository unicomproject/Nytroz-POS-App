import 'package:flutter/material.dart';
import '../../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

class CashPaymentNumericKeypad extends StatelessWidget {
  const CashPaymentNumericKeypad({
    super.key,
    required this.onDigitPressed,
    required this.onDoubleZeroPressed,
    required this.onBackspacePressed,
    required this.onClearPressed,
  });

  final ValueChanged<String> onDigitPressed;
  final VoidCallback onDoubleZeroPressed;
  final VoidCallback onBackspacePressed;
  final VoidCallback onClearPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              _buildDigitKey('7', context),
              _buildDigitKey('8', context),
              _buildDigitKey('9', context),
              _buildActionKey(
                icon: Icons.backspace_outlined,
                onTap: onBackspacePressed,
                context: context,
              ),
            ],
          ),
        ),
        const SizedBox(height: TenantAdminSpacing.sm),
        Expanded(
          child: Row(
            children: [
              _buildDigitKey('4', context),
              _buildDigitKey('5', context),
              _buildDigitKey('6', context),
              _buildDisabledKey('+', context),
            ],
          ),
        ),
        const SizedBox(height: TenantAdminSpacing.sm),
        Expanded(
          child: Row(
            children: [
              _buildDigitKey('1', context),
              _buildDigitKey('2', context),
              _buildDigitKey('3', context),
              _buildDisabledKey('-', context),
            ],
          ),
        ),
        const SizedBox(height: TenantAdminSpacing.sm),
        Expanded(
          child: Row(
            children: [
              _buildKey(
                label: '00',
                onTap: onDoubleZeroPressed,
                context: context,
              ),
              _buildDigitKey('0', context),
              _buildDisabledKey('.', context),
              _buildActionKey(
                label: 'C',
                color: TenantAdminColors.danger,
                onTap: onClearPressed,
                context: context,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDigitKey(String digit, BuildContext context) {
    return _buildKey(
      label: digit,
      onTap: () => onDigitPressed(digit),
      context: context,
    );
  }

  Widget _buildKey({
    String? label,
    IconData? icon,
    Color? color,
    required VoidCallback onTap,
    required BuildContext context,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(TenantAdminRadius.md),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(TenantAdminRadius.md),
            child: Container(
              height: double.infinity,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(TenantAdminRadius.md),
                border: Border.all(color: TenantAdminColors.border),
                boxShadow: TenantAdminShadows.card,
              ),
              child: icon != null
                  ? Icon(icon, color: color ?? TenantAdminColors.bodyText)
                  : Text(
                      label ?? '',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: color ?? TenantAdminColors.bodyText,
                          ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDisabledKey(String label, BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Container(
          height: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: TenantAdminColors.background,
            borderRadius: BorderRadius.circular(TenantAdminRadius.md),
            border: Border.all(color: TenantAdminColors.border),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: TenantAdminColors.mutedText.withValues(alpha: 0.5),
                ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionKey({
    String? label,
    IconData? icon,
    Color? color,
    required VoidCallback onTap,
    required BuildContext context,
  }) {
    return _buildKey(
      label: label,
      icon: icon,
      color: color,
      onTap: onTap,
      context: context,
    );
  }
}
