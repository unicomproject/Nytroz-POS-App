import 'package:flutter/material.dart';
import '../theme/tenant_admin_theme.dart';

/// Toast types supported by [showAppToast].
enum AppToastType {
  /// Orange accent popup card (default for product actions and highlights).
  orange,

  /// Success green popup card.
  success,

  /// Error red popup card.
  error,

  /// Warning amber popup card.
  warning,

  /// Info blue popup card.
  info,
}

/// Central general top-right corner popup card toast notification helper.
///
/// Usage:
/// ```dart
/// showAppToast(context, message: 'Draft saved successfully', title: 'Draft Saved');
/// ```
void showAppToast(
  BuildContext context, {
  required String message,
  String? title,
  AppToastType type = AppToastType.orange,
  IconData? icon,
  Duration duration = const Duration(seconds: 4),
  Color? backgroundColor,
}) {
  final overlayState = Overlay.maybeOf(context);
  if (overlayState == null) return;

  final toastStyle = _getToastStyle(type, backgroundColor, icon);

  late OverlayEntry overlayEntry;

  overlayEntry = OverlayEntry(
    builder: (context) => _TopRightToastWidget(
      title: title ?? toastStyle.defaultTitle,
      message: message,
      icon: toastStyle.icon,
      backgroundColor: toastStyle.backgroundColor,
      onDismiss: () {
        if (overlayEntry.mounted) {
          overlayEntry.remove();
        }
      },
    ),
  );

  overlayState.insert(overlayEntry);

  Future.delayed(duration, () {
    if (overlayEntry.mounted) {
      overlayEntry.remove();
    }
  });
}

/// Helper shortcut for product save notifications (Orange card).
void showProductSaveToast(
  BuildContext context, {
  required String message,
  String title = 'Product Saved',
  IconData? icon,
  Duration duration = const Duration(seconds: 4),
}) {
  showAppToast(
    context,
    message: message,
    title: title,
    type: AppToastType.orange,
    icon: icon,
    duration: duration,
  );
}

class _ToastStyle {
  final Color backgroundColor;
  final IconData icon;
  final String defaultTitle;

  const _ToastStyle({
    required this.backgroundColor,
    required this.icon,
    required this.defaultTitle,
  });
}

_ToastStyle _getToastStyle(
  AppToastType type,
  Color? overrideColor,
  IconData? overrideIcon,
) {
  switch (type) {
    case AppToastType.orange:
      return _ToastStyle(
        backgroundColor: overrideColor ?? TenantAdminColors.posHomeAccentOrange,
        icon: overrideIcon ?? Icons.check_circle_outline_rounded,
        defaultTitle: 'Success',
      );
    case AppToastType.success:
      return _ToastStyle(
        backgroundColor: overrideColor ?? TenantAdminColors.success,
        icon: overrideIcon ?? Icons.check_circle_rounded,
        defaultTitle: 'Success',
      );
    case AppToastType.error:
      return _ToastStyle(
        backgroundColor: overrideColor ?? TenantAdminColors.danger,
        icon: overrideIcon ?? Icons.error_outline_rounded,
        defaultTitle: 'Error',
      );
    case AppToastType.warning:
      return _ToastStyle(
        backgroundColor: overrideColor ?? TenantAdminColors.warning,
        icon: overrideIcon ?? Icons.warning_amber_rounded,
        defaultTitle: 'Warning',
      );
    case AppToastType.info:
      return _ToastStyle(
        backgroundColor: overrideColor ?? TenantAdminColors.info,
        icon: overrideIcon ?? Icons.info_outline_rounded,
        defaultTitle: 'Info',
      );
  }
}

class _TopRightToastWidget extends StatefulWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color backgroundColor;
  final VoidCallback onDismiss;

  const _TopRightToastWidget({
    required this.title,
    required this.message,
    required this.icon,
    required this.backgroundColor,
    required this.onDismiss,
  });

  @override
  State<_TopRightToastWidget> createState() => _TopRightToastWidgetState();
}

class _TopRightToastWidgetState extends State<_TopRightToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.35, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleDismiss() async {
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: const EdgeInsets.only(top: 24, right: 24),
          child: Material(
            color: Colors.transparent,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 380, minWidth: 280),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: widget.backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: widget.backgroundColor.withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          widget.icon,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.message,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: _handleDismiss,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
