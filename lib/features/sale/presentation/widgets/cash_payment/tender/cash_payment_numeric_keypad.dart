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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 3,
          child: Column(
            children: [
              Expanded(
                child: Row(
                  children: [
                    _buildDigitKey('7', context),
                    _buildDigitKey('8', context),
                    _buildDigitKey('9', context),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: Row(
                  children: [
                    _buildDigitKey('4', context),
                    _buildDigitKey('5', context),
                    _buildDigitKey('6', context),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: Row(
                  children: [
                    _buildDigitKey('1', context),
                    _buildDigitKey('2', context),
                    _buildDigitKey('3', context),
                  ],
                ),
              ),
              const SizedBox(height: 6),
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
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            children: [
              Expanded(
                flex: 2,
                child: _buildActionKey(
                  icon: Icons.backspace_outlined,
                  onTap: onBackspacePressed,
                  context: context,
                ),
              ),
              const SizedBox(height: 6),
              Expanded(
                flex: 2,
                child: _buildActionKey(
                  label: 'C',
                  color: TenantAdminColors.danger,
                  onTap: onClearPressed,
                  context: context,
                ),
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
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
                border: Border.all(color: TenantAdminColors.border),
              ),
              child: icon != null
                  ? Icon(
                      icon,
                      size: 18,
                      color: color ?? TenantAdminColors.bodyText,
                    )
                  : Text(
                      label ?? '',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
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
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: TenantAdminColors.subtleBackground,
            borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
            border: Border.all(color: TenantAdminColors.border),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: TenantAdminColors.mutedText.withValues(alpha: 0.45),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
              border: Border.all(color: TenantAdminColors.border),
            ),
            child: icon != null
                ? Icon(
                    icon,
                    size: 18,
                    color: color ?? TenantAdminColors.bodyText,
                  )
                : Text(
                    label ?? '',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: color ?? TenantAdminColors.bodyText,
                        ),
                  ),
          ),
        ),
      ),
    );
  }
}
