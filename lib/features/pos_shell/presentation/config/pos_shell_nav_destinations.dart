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
    routePath: '/pos/new-sale',
    permissionKey: PosPermissionCodes.viewNewSale,
    routeExists: true,
  ),
  PosShellNavDestination(
    key: 'orders',
    label: 'Orders',
    icon: Icons.receipt_long_outlined,
    permissionKey: PosPermissionCodes.viewOrders,
    unavailableMessage: 'Orders screen is not available yet.',
  ),
  PosShellNavDestination(
    key: 'customers',
    label: 'Customers',
    icon: Icons.people_outline_rounded,
    routePath: '/pos/customers',
    anyOfPermissionKeys: [
      PosPermissionCodes.viewNewSaleCustomers,
      PosPermissionCodes.createNewSaleCustomer,
    ],
    routeExists: true,
  ),
  PosShellNavDestination(
    key: 'returns-refunds',
    label: 'Return & Refund',
    icon: Icons.assignment_return_outlined,
    routePath: '/pos/returns-refunds',
    anyOfPermissionKeys: [
      PosPermissionCodes.viewReturns,
      PosPermissionCodes.viewRefunds,
    ],
    routeExists: true,
  ),
  PosShellNavDestination(
    key: 'cash-drawer',
    label: 'Cash Drawer',
    icon: Icons.point_of_sale_outlined,
    routePath: '/pos/cash-drawer',
    permissionKey: PosPermissionCodes.viewCashDrawer,
    routeExists: true,
  ),
];
