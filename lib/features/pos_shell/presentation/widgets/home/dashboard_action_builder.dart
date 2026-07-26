import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/access/pos_access_codes.dart';
import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../application/state/pos_home_dashboard_state.dart';
import '../../../domain/entities/pos_home_action.dart';
import 'dashboard_action_card.dart';

List<Widget> buildPosHomeActionCards({
  required BuildContext context,
  required PosHomeDashboardState dashboard,
}) {
  final cards = <Widget>[];

  void add({
    required String key,
    required String title,
    required IconData fallbackIcon,
    required String asset,
    required List<Color> colors,
    required Color accent,
    required String? route,
    String? unavailableReason,
  }) {
    final action = _findAction(dashboard, key);
    if (action == null && key != 'end-shift' && key != 'manage-online-orders') {
      return;
    }
    final access = action == null
        ? key == 'end-shift'
            ? _endShiftAccess(dashboard)
            : const PosHomeActionAccess(
                isVisible: true,
                isEnabled: false,
                disabledMessage: 'Online Orders is not available yet.',
              )
        : dashboard.accessFor(action);
    if (!access.isVisible) return;
    final enabled = access.isEnabled && route != null;
    cards.add(
      PosHomeActionTile(
        title: title,
        assetPath: asset,
        fallbackIcon: fallbackIcon,
        colors: colors,
        accent: accent,
        enabled: enabled,
        disabledReason: access.disabledMessage ?? unavailableReason,
        onPressed: enabled ? () => context.go(route) : null,
      ),
    );
  }

  add(
    key: 'start-new-sale',
    title: 'Start New Sale',
    fallbackIcon: Icons.shopping_cart_checkout_rounded,
    asset: 'assets/images/pos_home_start_new_sale.png',
    colors: const [
      TenantAdminColors.posHomeOrangeStart,
      TenantAdminColors.posHomeOrangeEnd,
    ],
    accent: TenantAdminColors.info,
    route: '/pos/new-sale',
  );
  add(
    key: 'returns-refunds',
    title: 'Returns & Exchanges',
    fallbackIcon: Icons.assignment_return_rounded,
    asset: 'assets/images/pos_home_returns_exchanges.png',
    colors: const [
      TenantAdminColors.posHomeTealStart,
      TenantAdminColors.posHomeTealEnd,
    ],
    accent: TenantAdminColors.warning,
    route: '/pos/returns-refunds',
  );
  add(
    key: 'cash-drawer',
    title: 'Cash Drawer',
    fallbackIcon: Icons.point_of_sale_rounded,
    asset: 'assets/images/pos_home_cash_drawer.png',
    colors: const [
      TenantAdminColors.posHomeGreenStart,
      TenantAdminColors.posHomeGreenEnd,
    ],
    accent: TenantAdminColors.success,
    route: '/pos/cash-drawer',
  );
  add(
    key: 'manage-online-orders',
    title: 'Online Orders',
    fallbackIcon: Icons.phone_android_rounded,
    asset: 'assets/images/pos_home_online_orders.png',
    colors: const [
      TenantAdminColors.posHomeBlueStart,
      TenantAdminColors.posHomeBlueEnd,
    ],
    accent: TenantAdminColors.pending,
    route: null,
    unavailableReason: 'Online Orders is not available yet.',
  );
  add(
    key: 'parked-sales',
    title: 'Resume Held Sales',
    fallbackIcon: Icons.pause_circle_outline_rounded,
    asset: 'assets/images/pos_home_resume_held_sales.png',
    colors: const [
      TenantAdminColors.posHomePurpleStart,
      TenantAdminColors.posHomePurpleEnd,
    ],
    accent: TenantAdminColors.warning,
    route: null,
    unavailableReason: 'Held-sale recall screen is not available yet.',
  );
  add(
    key: 'end-shift',
    title: 'End Shift',
    fallbackIcon: Icons.logout_rounded,
    asset: 'assets/images/pos_home_end_shift.png',
    colors: const [
      TenantAdminColors.posHomeRedStart,
      TenantAdminColors.posHomeRedEnd,
    ],
    accent: TenantAdminColors.danger,
    route: '/pos/cash-drawer/close-till?endShift=true',
  );
  return cards;
}

PosHomeAction? _findAction(PosHomeDashboardState dashboard, String key) {
  for (final action in dashboard.actions) {
    if (action.key == key) return action;
  }
  return null;
}

PosHomeActionAccess _endShiftAccess(PosHomeDashboardState dashboard) {
  final permissions = dashboard.grantedPermissionKeys;
  if (permissions != null &&
      !permissions.contains(PosPermissionCodes.closeTill)) {
    return const PosHomeActionAccess(isVisible: false, isEnabled: false);
  }
  if (dashboard.hasOpenTillSession == false) {
    return const PosHomeActionAccess(
      isVisible: true,
      isEnabled: false,
      disabledMessage: 'An open till is required.',
    );
  }
  return const PosHomeActionAccess(isVisible: true, isEnabled: true);
}
