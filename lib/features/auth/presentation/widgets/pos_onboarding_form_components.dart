import 'package:flutter/material.dart';

import '../../../../shared/widgets/pos_action_buttons.dart';
import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

class PosOnboardingHeading extends StatelessWidget {
  const PosOnboardingHeading({
    super.key,
    required this.leadingText,
    required this.accentText,
    required this.isWide,
  });

  final String leadingText;
  final String accentText;
  final bool isWide;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: TenantAdminSpacing.xs,
            height: isWide ? 50 : 38,
            decoration: BoxDecoration(
              color: TenantAdminColors.posOnboardingAccent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(
              width: isWide ? TenantAdminSpacing.lg : TenantAdminSpacing.md),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: '$leadingText '),
                  TextSpan(
                    text: accentText,
                    style: const TextStyle(
                      color: TenantAdminColors.posOnboardingAccent,
                    ),
                  ),
                ],
              ),
              style: TextStyle(
                color: TenantAdminColors.posOnboardingHeading,
                fontWeight: FontWeight.w800,
                fontSize: isWide ? 44 : 32,
                height: 1.1,
              ),
            ),
          ),
        ],
      );
}

class PosOnboardingField extends StatelessWidget {
  const PosOnboardingField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    required this.icon,
    required this.validator,
    required this.isWide,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.suffix,
    this.onFieldSubmitted,
    this.semanticLabel,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final IconData icon;
  final String? Function(String?) validator;
  final bool isWide;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Widget? suffix;
  final ValueChanged<String>? onFieldSubmitted;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: TenantAdminColors.posOnboardingHeading,
              fontSize: isWide ? 19 : 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: isWide ? TenantAdminSpacing.md : 10),
          Semantics(
            textField: true,
            label: semanticLabel ?? label,
            child: TextFormField(
              controller: controller,
              obscureText: obscureText,
              keyboardType: keyboardType,
              textInputAction: textInputAction,
              onFieldSubmitted: onFieldSubmitted,
              validator: validator,
              style: TextStyle(
                color: TenantAdminColors.posOnboardingFieldText,
                fontSize: isWide ? 21 : 17,
                fontWeight: FontWeight.w400,
                height: 1.2,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  color: TenantAdminColors.mutedText,
                  fontSize: isWide ? 21 : 17,
                  fontWeight: FontWeight.w400,
                ),
                prefixIcon: ExcludeSemantics(
                  child: Icon(
                    icon,
                    color: TenantAdminColors.posOnboardingAccent,
                  ),
                ),
                prefixIconConstraints: BoxConstraints(
                  minWidth: isWide ? 58 : 48,
                ),
                suffixIcon: suffix,
                filled: true,
                fillColor: TenantAdminColors.surface,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: isWide ? 22 : 17,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    isWide ? TenantAdminRadius.lg : TenantAdminRadius.md,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    isWide ? TenantAdminRadius.lg : TenantAdminRadius.md,
                  ),
                  borderSide: const BorderSide(
                    color: TenantAdminColors.posOnboardingAccent,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
}

class PosOnboardingPrimaryAction extends StatelessWidget {
  const PosOnboardingPrimaryAction({
    super.key,
    required this.label,
    required this.semanticLabel,
    required this.isWide,
    required this.isLoading,
    required this.onPressed,
  });

  final String label;
  final String semanticLabel;
  final bool isWide;
  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => PosPrimaryActionButton(
        semanticLabel: semanticLabel,
        onPressed: onPressed,
        isLoading: isLoading,
        fullWidth: true,
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            TenantAdminColors.posNewSaleAccent,
            TenantAdminColors.posNewSaleAccentEnd,
          ],
        ),
        minimumHeight: isWide ? 68 : 56,
        child: Row(
          children: [
            const Spacer(),
            Text(
              label,
              style: TextStyle(
                color: TenantAdminColors.surface,
                fontSize: isWide ? 23 : 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.arrow_forward,
              color: TenantAdminColors.surface,
              size: isWide ? 26 : 20,
            ),
          ],
        ),
      );
}
