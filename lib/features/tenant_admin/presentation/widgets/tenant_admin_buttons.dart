import 'package:flutter/material.dart';

import '../theme/tenant_admin_theme.dart';

class TenantAdminPrimaryButton extends StatelessWidget {
  const TenantAdminPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.backgroundColor,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final child = _ButtonContent(
      label: label,
      icon: icon,
      loading: loading,
      iconSize: 22,
      fontSize: 16,
    );

    return ElevatedButton(
      onPressed: loading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? TenantAdminColors.primary,
        foregroundColor: Colors.white,
        disabledBackgroundColor: (backgroundColor ?? TenantAdminColors.primary)
            .withValues(alpha: 0.45),
        padding: const EdgeInsets.symmetric(
          horizontal: TenantAdminSpacing.xl,
          vertical: TenantAdminSpacing.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        ),
        minimumSize: const Size(44, TenantAdminContentTokens.buttonHeight),
        tapTargetSize: MaterialTapTargetSize.padded,
        elevation: 0,
      ),
      child: child,
    );
  }
}

class TenantAdminSecondaryButton extends StatelessWidget {
  const TenantAdminSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: loading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: TenantAdminColors.primary,
        side: const BorderSide(color: TenantAdminColors.border),
        padding: const EdgeInsets.symmetric(
          horizontal: TenantAdminSpacing.lg,
          vertical: TenantAdminSpacing.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        ),
        minimumSize: const Size(44, TenantAdminContentTokens.buttonHeight),
        tapTargetSize: MaterialTapTargetSize.padded,
      ),
      child: _ButtonContent(label: label, icon: icon, loading: loading),
    );
  }
}

class TenantAdminIconButton extends StatelessWidget {
  const TenantAdminIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.danger = false,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        child: Container(
          width: TenantAdminContentTokens.buttonHeight,
          height: TenantAdminContentTokens.buttonHeight,
          decoration: BoxDecoration(
            color: danger
                ? TenantAdminColors.danger.withValues(alpha: 0.08)
                : TenantAdminColors.surface,
            borderRadius: BorderRadius.circular(TenantAdminRadius.md),
            border: Border.all(color: TenantAdminColors.border),
          ),
          child: Icon(
            icon,
            size: 20,
            color:
                danger ? TenantAdminColors.danger : TenantAdminColors.bodyText,
          ),
        ),
      ),
    );
  }
}

class _ButtonContent extends StatelessWidget {
  const _ButtonContent({
    required this.label,
    required this.icon,
    required this.loading,
    this.iconSize = 18,
    this.fontSize,
  });

  final String label;
  final IconData? icon;
  final bool loading;
  final double iconSize;
  final double? fontSize;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: iconSize),
          const SizedBox(width: TenantAdminSpacing.sm),
        ],
        Text(
          label,
          style: TenantAdminTextStyles.buttonLabel(context).copyWith(
            fontSize: fontSize,
          ),
        ),
      ],
    );
  }
}
