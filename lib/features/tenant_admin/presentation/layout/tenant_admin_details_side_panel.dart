import 'package:flutter/material.dart';

import '../theme/tenant_admin_theme.dart';

/// Optional right-side details panel for desktop/tablet.
/// On narrow widths, prefer [showAsSheet].
class TenantAdminDetailsSidePanel extends StatelessWidget {
  const TenantAdminDetailsSidePanel({
    super.key,
    required this.child,
    this.title,
    this.onClose,
    this.width = TenantAdminContentTokens.sidePanelWidth,
  });

  final Widget child;
  final String? title;
  final VoidCallback? onClose;
  final double width;

  static Future<T?> showAsSheet<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    String? title,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: TenantAdminColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.92,
          minChildSize: 0.5,
          maxChildSize: 0.98,
          builder: (context, controller) {
            return Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: TenantAdminColors.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                if (title != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TenantAdminTextStyles.sectionTitle(context),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: controller,
                    padding: const EdgeInsets.all(16),
                    child: builder(context),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: TenantAdminColors.surface,
      elevation: 0,
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: TenantAdminColors.surface,
          borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
          border: Border.all(color: TenantAdminColors.border),
          boxShadow: TenantAdminShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null || onClose != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title ?? '',
                        style: TenantAdminTextStyles.sectionTitle(context),
                      ),
                    ),
                    if (onClose != null)
                      IconButton(
                        onPressed: onClose,
                        icon: const Icon(Icons.close),
                      ),
                  ],
                ),
              ),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}
