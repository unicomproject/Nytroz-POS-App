import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../../core/access/permission_access_providers.dart';
import '../../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../../../pos_shell/presentation/widgets/common/pos_shell_bottom_nav_destinations.dart';

class PosCashierBottomNavigation extends ConsumerWidget {
  const PosCashierBottomNavigation({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissions = ref.watch(effectivePermissionSetProvider);
    if (!shouldShowPosCashierBottomNav(permissions)) {
      return const SizedBox.shrink();
    }

    final destinations = filterPosCashierNavDestinations(permissions);
    final currentPath = GoRouterState.of(context).uri.path;

    return Material(
      color: TenantAdminColors.posHomeDarkBackground,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Row(
            children: [
              for (final destination in destinations)
                Expanded(
                  child: _DestinationButton(
                    destination: destination,
                    selected: destination.matches(currentPath),
                    onTap: () => context.go(destination.route),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DestinationButton extends StatelessWidget {
  const _DestinationButton({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final PosCashierNavDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? TenantAdminColors.posHomeAccentOrange
        : TenantAdminColors.surface;

    return Semantics(
      button: true,
      enabled: true,
      selected: selected,
      label: destination.label,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 6,
              ),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        selected ? destination.selectedIcon : destination.icon,
                        size: 24,
                        color: color,
                      ),
                      const SizedBox(width: 7),
                      Text(
                        destination.label,
                        maxLines: 1,
                        softWrap: false,
                        style: TextStyle(
                          color: color,
                          fontSize: 14,
                          fontWeight:
                              selected ? FontWeight.w900 : FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (selected)
              const Positioned(
                left: 28,
                right: 28,
                bottom: 0,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: TenantAdminColors.posHomeAccentOrange,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(3),
                    ),
                  ),
                  child: SizedBox(height: 5),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
