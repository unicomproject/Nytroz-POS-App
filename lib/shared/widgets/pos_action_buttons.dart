import 'package:flutter/material.dart';

import '../../features/tenant_admin/presentation/theme/tenant_admin_theme.dart';

abstract final class PosPrimaryActionTokens {
  static const gradientStart = TenantAdminColors.navySoft;
  static const gradientEnd = TenantAdminColors.primary;
  static const foreground = Colors.white;
  static const disabledBackground = TenantAdminColors.border;
  static const disabledForeground = TenantAdminColors.mutedText;
  static const height = 56.0;
  static const compactHeight = 48.0;
  static const radius = TenantAdminRadius.md;
  static const horizontalPadding = 20.0;
  static const verticalPadding = 14.0;
  static const iconSize = 18.0;
  static const animationDuration = Duration(milliseconds: 140);

  static const gradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [gradientStart, gradientEnd],
  );
}

/// Backward-compatible sizing alias for existing POS action bars.
@Deprecated('Use PosPrimaryActionTokens instead.')
abstract final class PosBottomActionSizes {
  static const minHeight = PosPrimaryActionTokens.height;
  static const horizontalPadding = PosPrimaryActionTokens.horizontalPadding;
  static const verticalPadding = PosPrimaryActionTokens.verticalPadding;
  static const iconSize = PosPrimaryActionTokens.iconSize;
}

class PosPrimaryActionButton extends StatefulWidget {
  const PosPrimaryActionButton({
    super.key,
    this.label,
    this.child,
    required this.onPressed,
    this.icon,
    this.leadingIcon,
    this.trailingIcon,
    this.isLoading = false,
    this.fullWidth = false,
    this.compact = false,
    this.semanticLabel,
    this.backgroundColor,
    this.gradient,
    this.disabledBackgroundColor,
    this.minimumHeight,
    this.horizontalPadding = PosPrimaryActionTokens.horizontalPadding,
    this.verticalPadding = PosPrimaryActionTokens.verticalPadding,
    this.borderRadius = PosPrimaryActionTokens.radius,
  }) : assert(label != null || child != null);

  final String? label;
  final Widget? child;
  final VoidCallback? onPressed;
  final IconData? icon;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final bool isLoading;
  final bool fullWidth;
  final bool compact;
  final String? semanticLabel;
  final Color? backgroundColor;
  final Gradient? gradient;
  final Color? disabledBackgroundColor;
  final double? minimumHeight;
  final double horizontalPadding;
  final double verticalPadding;
  final double borderRadius;

  @override
  State<PosPrimaryActionButton> createState() => _PosPrimaryActionButtonState();
}

class _PosPrimaryActionButtonState extends State<PosPrimaryActionButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.isLoading;
    final showActiveTheme = widget.onPressed != null || widget.isLoading;
    final height = widget.minimumHeight ??
        (widget.compact
            ? PosPrimaryActionTokens.compactHeight
            : PosPrimaryActionTokens.height);
    final radius = BorderRadius.circular(widget.borderRadius);
    final opacity = _pressed ? 0.86 : (_hovered ? 0.94 : 1.0);

    final button = AnimatedOpacity(
      opacity: showActiveTheme ? opacity : 1,
      duration: PosPrimaryActionTokens.animationDuration,
      child: AnimatedContainer(
        duration: PosPrimaryActionTokens.animationDuration,
        decoration: BoxDecoration(
          color: showActiveTheme
              ? widget.backgroundColor
              : widget.disabledBackgroundColor ??
                  PosPrimaryActionTokens.disabledBackground,
          gradient: showActiveTheme && widget.backgroundColor == null
              ? widget.gradient ?? PosPrimaryActionTokens.gradient
              : null,
          borderRadius: radius,
          border: _focused ? Border.all(color: Colors.white, width: 2) : null,
          boxShadow: showActiveTheme ? TenantAdminShadows.card : null,
        ),
        child: Semantics(
          button: true,
          enabled: enabled,
          label: widget.semanticLabel ?? widget.label,
          child: FilledButton(
            onPressed: enabled ? widget.onPressed : null,
            onHover: (value) => setState(() => _hovered = value),
            onFocusChange: (value) => setState(() => _focused = value),
            style: FilledButton.styleFrom(
              minimumSize: Size(widget.fullWidth ? double.infinity : 0, height),
              padding: EdgeInsets.symmetric(
                horizontal: widget.horizontalPadding,
                vertical: widget.verticalPadding,
              ),
              backgroundColor: Colors.transparent,
              disabledBackgroundColor: Colors.transparent,
              foregroundColor: PosPrimaryActionTokens.foreground,
              disabledForegroundColor:
                  PosPrimaryActionTokens.disabledForeground,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: radius),
            ).copyWith(
              overlayColor: const WidgetStatePropertyAll(Colors.transparent),
            ),
            child: widget.isLoading
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : widget.child ?? _buildLabel(),
          ),
        ),
      ),
    );

    return Listener(
      onPointerDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onPointerUp: enabled ? (_) => setState(() => _pressed = false) : null,
      onPointerCancel: enabled ? (_) => setState(() => _pressed = false) : null,
      child: widget.fullWidth
          ? SizedBox(width: double.infinity, child: button)
          : button,
    );
  }

  Widget _buildLabel() {
    final leading = widget.leadingIcon ?? widget.icon;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
      children: [
        if (leading != null) ...[
          Icon(leading, size: PosPrimaryActionTokens.iconSize),
          const SizedBox(width: TenantAdminSpacing.sm),
        ],
        Flexible(
          child: Text(
            widget.label!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        if (widget.trailingIcon != null) ...[
          const SizedBox(width: TenantAdminSpacing.sm),
          Icon(widget.trailingIcon, size: PosPrimaryActionTokens.iconSize),
        ],
      ],
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
  Widget build(BuildContext context) => PosPrimaryActionButton(
        label: label,
        onPressed: onPressed,
        icon: icon,
        isLoading: isLoading,
        backgroundColor: backgroundColor,
        disabledBackgroundColor: disabledBackgroundColor,
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
    final style = OutlinedButton.styleFrom(
      minimumSize: const Size(0, PosPrimaryActionTokens.height),
      padding: const EdgeInsets.symmetric(
        horizontal: PosPrimaryActionTokens.horizontalPadding,
        vertical: PosPrimaryActionTokens.verticalPadding,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(PosPrimaryActionTokens.radius),
      ),
    );
    if (icon == null) {
      return OutlinedButton(
        onPressed: onPressed,
        style: style,
        child: Text(label),
      );
    }
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: PosPrimaryActionTokens.iconSize),
      label: Text(label),
      style: style,
    );
  }
}
