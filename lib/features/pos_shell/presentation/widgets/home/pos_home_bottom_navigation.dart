import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

class PosHomeBottomNavigation extends StatelessWidget {
  const PosHomeBottomNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    const destinations = [
      (Icons.home_outlined, 'Home', '/pos/home', true),
      (Icons.shopping_cart_outlined, 'New Sale', '/pos/new-sale', true),
      (Icons.receipt_long_outlined, 'Orders', null, false),
      (Icons.people_outline_rounded, 'Customers', '/pos/customers', true),
      (Icons.settings_outlined, 'Settings', null, false),
    ];
    return Container(
      height: 72,
      decoration: const BoxDecoration(
        color: TenantAdminColors.posHomeDarkBackground,
        border: Border(
          top: BorderSide(color: TenantAdminColors.posHomeDarkBorder),
        ),
      ),
      child: Row(
        children: [
          for (final destination in destinations)
            Expanded(
              child: Semantics(
                button: destination.$4,
                enabled: destination.$4,
                selected: destination.$2 == 'Home',
                label: destination.$2,
                child: InkWell(
                  onTap: destination.$4 && destination.$3 != null
                      ? () => context.go(destination.$3!)
                      : null,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        destination.$1,
                        color: destination.$2 == 'Home'
                            ? TenantAdminColors.posHomeOrangeStart
                            : TenantAdminColors.surface,
                      ),
                      const SizedBox(height: TenantAdminSpacing.xs),
                      Text(
                        destination.$2,
                        style: TextStyle(
                          color: destination.$2 == 'Home'
                              ? TenantAdminColors.posHomeOrangeStart
                              : TenantAdminColors.surface,
                          fontWeight: destination.$2 == 'Home'
                              ? FontWeight.w800
                              : FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: TenantAdminSpacing.sm),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: destination.$2 == 'Home' ? 56 : 0,
                        height: 3,
                        decoration: BoxDecoration(
                          color: TenantAdminColors.posHomeOrangeStart,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
