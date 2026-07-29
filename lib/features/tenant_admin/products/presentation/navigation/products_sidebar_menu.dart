import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'products_permission_wrapper.dart';
import 'products_sidebar_child_item.dart';
import 'products_sidebar_parent_item.dart';
import 'products_sidebar_provider.dart';
import 'products_sidebar_routes.dart';
import 'products_sidebar_visibility.dart';

class ProductsSidebarMenu extends ConsumerWidget {
  const ProductsSidebarMenu({
    super.key,
    required this.currentPath,
    this.collapsed = false,
    this.compact = false,
    this.onNavigate,
  });

  final String currentPath;
  final bool collapsed;
  final bool compact;
  final VoidCallback? onNavigate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visibilityState = ref.watch(productsSidebarVisibilityProvider);
    final expanded = ref.watch(productsSidebarExpandedProvider);

    return visibilityState.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (visibility) {
        if (!visibility.showParent || !visibility.hasVisibleChildren) {
          return const SizedBox.shrink();
        }

        final parentSelected =
            ProductsSidebarRoutes.isParentActive(currentPath);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ProductsSidebarParentItem(
              label: 'Products',
              icon: Icons.inventory_2_outlined,
              selected: parentSelected,
              expanded: expanded,
              collapsed: collapsed,
              compact: compact,
              onToggle: () {
                if (collapsed) {
                  _showCollapsedSubmenu(context, ref, visibility);
                  return;
                }

                toggleProductsSidebarExpanded(ref);
              },
            ),
            if (!collapsed)
              AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                alignment: Alignment.topCenter,
                child: expanded
                    ? Column(
                        children: [
                          for (final child in visibility.visibleChildren)
                            ProductsPermissionWrapper(
                              isVisible: child.isVisible,
                              child: ProductsSidebarChildItem(
                                label: child.label,
                                selected: ProductsSidebarRoutes.isChildActive(
                                  currentPath: currentPath,
                                  route: child.route,
                                ),
                                compact: compact,
                                dense: compact,
                                onTap: () => _navigate(context, child.route),
                              ),
                            ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
          ],
        );
      },
    );
  }

  void _navigate(BuildContext context, String route) {
    context.go(route);
    onNavigate?.call();
  }

  Future<void> _showCollapsedSubmenu(
    BuildContext context,
    WidgetRef ref,
    ProductsSidebarVisibility visibility,
  ) async {
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    final button = context.findRenderObject() as RenderBox?;
    if (overlay == null || button == null) {
      return;
    }

    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset(button.size.width + 8, 0),
            ancestor: overlay),
        button.localToGlobal(
          Offset(button.size.width + 240, button.size.height),
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );

    final selectedRoute = await showMenu<String>(
      context: context,
      position: position,
      items: [
        for (final child in visibility.visibleChildren)
          PopupMenuItem<String>(
            value: child.route,
            child: Text(
              child.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );

    if (!context.mounted || selectedRoute == null) {
      return;
    }

    _navigate(context, selectedRoute);
  }
}
