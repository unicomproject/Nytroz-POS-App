import 'package:flutter/material.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

/// Touch-friendly sizing for POS payment bottom action bars.
class PosBottomActionSizes {
  const PosBottomActionSizes._();

  static const minHeight = 56.0;
  static const horizontalPadding = 20.0;
  static const verticalPadding = 14.0;
  static const iconSize = 18.0;
}

ButtonStyle posBottomOutlinedButtonStyle() {
  return OutlinedButton.styleFrom(
    minimumSize: const Size(0, PosBottomActionSizes.minHeight),
    padding: const EdgeInsets.symmetric(
      horizontal: PosBottomActionSizes.horizontalPadding,
      vertical: PosBottomActionSizes.verticalPadding,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(TenantAdminRadius.md),
    ),
  );
}

class PosBottomOutlinedButton extends StatelessWidget {
  const PosBottomOutlinedButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final style = posBottomOutlinedButtonStyle();

    if (icon != null) {
      return OutlinedButton.icon(
        onPressed: onPressed,
        style: style,
        icon: Icon(icon, size: PosBottomActionSizes.iconSize),
        label: Text(label),
      );
    }

    return OutlinedButton(
      onPressed: onPressed,
      style: style,
      child: Text(label),
    );
  }
}

class PosBottomFilledButton extends StatelessWidget {
  const PosBottomFilledButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.backgroundColor,
    this.disabledBackgroundColor,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? disabledBackgroundColor;

  @override
  Widget build(BuildContext context) {
    return PosPrimaryActionButton(
      label: label,
      onPressed: onPressed,
      icon: icon,
      isLoading: isLoading,
      backgroundColor: backgroundColor,
      disabledBackgroundColor: disabledBackgroundColor,
    );
  }
}

class PosPrimaryActionButton extends StatelessWidget {
  const PosPrimaryActionButton({
    super.key,
    this.label,
    this.child,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.backgroundColor,
    this.disabledBackgroundColor,
    this.minimumHeight = PosBottomActionSizes.minHeight,
    this.horizontalPadding = PosBottomActionSizes.horizontalPadding,
    this.verticalPadding = PosBottomActionSizes.verticalPadding,
    this.borderRadius = TenantAdminRadius.md,
  }) : assert(label != null || child != null);

  final String? label;
  final Widget? child;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? disabledBackgroundColor;
  final double minimumHeight;
  final double horizontalPadding;
  final double verticalPadding;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final showActiveTheme = onPressed != null || isLoading;
    final radius = BorderRadius.circular(borderRadius);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: showActiveTheme
            ? backgroundColor
            : disabledBackgroundColor ?? TenantAdminColors.border,
        gradient: showActiveTheme && backgroundColor == null
            ? const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  TenantAdminColors.navySoft,
                  TenantAdminColors.primary,
                ],
              )
            : null,
        borderRadius: radius,
        boxShadow: showActiveTheme ? TenantAdminShadows.card : null,
      ),
      child: FilledButton(
        onPressed: isLoading ? null : onPressed,
        style: FilledButton.styleFrom(
          minimumSize: Size(0, minimumHeight),
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          backgroundColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white70,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: radius),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : child ??
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: PosBottomActionSizes.iconSize),
                      const SizedBox(width: TenantAdminSpacing.sm),
                    ],
                    Flexible(
                      child: Text(
                        label!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
}
