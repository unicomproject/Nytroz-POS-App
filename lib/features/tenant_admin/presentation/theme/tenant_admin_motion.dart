import 'package:flutter/material.dart';

class TenantAdminMotion {
  const TenantAdminMotion._();

  static const fast = Duration(milliseconds: 160);
  static const normal = Duration(milliseconds: 240);
  static const slow = Duration(milliseconds: 320);
  static const standard = Curves.easeOutCubic;
  static const emphasized = Curves.easeOutQuart;
}

class TenantAdminPressScale extends StatefulWidget {
  const TenantAdminPressScale({
    super.key,
    required this.child,
    this.enabled = true,
  });

  final Widget child;
  final bool enabled;

  @override
  State<TenantAdminPressScale> createState() => _TenantAdminPressScaleState();
}

class _TenantAdminPressScaleState extends State<TenantAdminPressScale> {
  var _pressed = false;

  @override
  Widget build(BuildContext context) => Listener(
        onPointerDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
        onPointerUp: widget.enabled ? (_) => setState(() => _pressed = false) : null,
        onPointerCancel: widget.enabled ? (_) => setState(() => _pressed = false) : null,
        child: AnimatedScale(
          scale: _pressed ? 0.985 : 1,
          duration: TenantAdminMotion.fast,
          curve: TenantAdminMotion.standard,
          child: widget.child,
        ),
      );
}

class TenantAdminAnimatedStatus extends StatelessWidget {
  const TenantAdminAnimatedStatus({
    super.key,
    required this.statusKey,
    required this.child,
  });

  final Object statusKey;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
        duration: TenantAdminMotion.fast,
        switchInCurve: TenantAdminMotion.standard,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (currentChild, animation) => FadeTransition(
          opacity: animation,
          child: ScaleTransition(scale: animation, child: currentChild),
        ),
        child: KeyedSubtree(key: ValueKey(statusKey), child: child),
      );
}
