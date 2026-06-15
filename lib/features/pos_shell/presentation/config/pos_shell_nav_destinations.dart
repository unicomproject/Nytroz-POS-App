import 'package:flutter/material.dart';

import '../../../../core/access/pos_access_codes.dart';
import '../../domain/entities/pos_shell_nav_destination.dart';

const posShellNavDestinations = <PosShellNavDestination>[
  PosShellNavDestination(
    key: 'home',
    label: 'Home',
    icon: Icons.home_rounded,
    routePath: '/pos/home',
    permissionKey: PosPermissionCodes.viewHome,
    routeExists: true,
  ),
  PosShellNavDestination(
    key: 'new-sale',
    label: 'New Sale',
    icon: Icons.add_shopping_cart_rounded,
    permissionKey: PosPermissionCodes.startSale,
    unavailableMessage: 'New Sale screen is not available yet.',
  ),
  PosShellNavDestination(
    key: 'orders',
    label: 'Orders',
    icon: Icons.receipt_long_outlined,
    permissionKey: PosPermissionCodes.manageOnlineOrders,
    unavailableMessage: 'Orders screen is not available yet.',
  ),
  PosShellNavDestination(
    key: 'customers',
    label: 'Customers',
    icon: Icons.people_outline_rounded,
    anyOfPermissionKeys: [
      PosPermissionCodes.viewCustomers,
      PosPermissionCodes.createCustomer,
    ],
    unavailableMessage: 'Customers screen is not available yet.',
  ),
  PosShellNavDestination(
    key: 'returns-refunds',
    label: 'Return & Refund',
    icon: Icons.assignment_return_outlined,
    permissionKey: PosPermissionCodes.processRefund,
    unavailableMessage: 'Return & Refund screen is not available yet.',
  ),
  PosShellNavDestination(
    key: 'cash-drawer',
    label: 'Cash Drawer',
    icon: Icons.point_of_sale_outlined,
    anyOfPermissionKeys: [
      PosPermissionCodes.viewTill,
      PosPermissionCodes.cashMovement,
    ],
    unavailableMessage: 'Cash Drawer screen is not available yet.',
  ),
];
