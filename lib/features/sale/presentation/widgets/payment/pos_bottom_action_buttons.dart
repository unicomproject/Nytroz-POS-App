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

ButtonStyle posBottomFilledButtonStyle({
  Color backgroundColor = TenantAdminColors.info,
  Color? disabledBackgroundColor,
}) {
  return FilledButton.styleFrom(
    minimumSize: const Size(0, PosBottomActionSizes.minHeight),
    padding: const EdgeInsets.symmetric(
      horizontal: PosBottomActionSizes.horizontalPadding,
      vertical: PosBottomActionSizes.verticalPadding,
    ),
    backgroundColor: backgroundColor,
    disabledBackgroundColor:
        disabledBackgroundColor ?? TenantAdminColors.border,
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
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final style = posBottomOutlinedButtonStyle();

    if (icon != null) {
      return SizedBox(
        width: expand ? double.infinity : null,
        child: OutlinedButton.icon(
          onPressed: onPressed,
          style: style,
          icon: Icon(icon, size: PosBottomActionSizes.iconSize),
          label: Text(label, overflow: TextOverflow.ellipsis),
        ),
      );
    }

    return SizedBox(
      width: expand ? double.infinity : null,
      child: OutlinedButton(
        onPressed: onPressed,
        style: style,
        child: Text(label, overflow: TextOverflow.ellipsis),
      ),
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
    this.backgroundColor = TenantAdminColors.info,
    this.disabledBackgroundColor,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final Color backgroundColor;
  final Color? disabledBackgroundColor;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final style = posBottomFilledButtonStyle(
      backgroundColor: backgroundColor,
      disabledBackgroundColor: disabledBackgroundColor,
    );

    if (isLoading) {
      return SizedBox(
        width: expand ? double.infinity : null,
        child: FilledButton(
          onPressed: null,
          style: style,
          child: const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          ),
        ),
      );
    }

    if (icon != null) {
      return SizedBox(
        width: expand ? double.infinity : null,
        child: FilledButton.icon(
          onPressed: onPressed,
          style: style,
          icon: Icon(icon, size: PosBottomActionSizes.iconSize),
          label: Text(label, overflow: TextOverflow.ellipsis),
        ),
      );
    }

    return SizedBox(
      width: expand ? double.infinity : null,
      child: FilledButton(
        onPressed: onPressed,
        style: style,
        child: Text(label, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}
