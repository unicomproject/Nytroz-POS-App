import 'package:flutter/material.dart';

import '../../../../core/access/pos_access_codes.dart';
import '../../../../core/access/pos_permission_access.dart';
import '../../domain/entities/pos_shell_nav_destination.dart';

const posShellNavDestinations = <PosShellNavDestination>[
  PosShellNavDestination(
    key: 'home',
    label: 'Home',
    icon: Icons.home_rounded,
    routePath: '/pos/home',
    anyOfPermissionKeys: PosPermissionAccess.homeAccessCodes,
    routeExists: true,
  ),
  PosShellNavDestination(
    key: 'new-sale',
    label: 'New Sale',
    icon: Icons.add_shopping_cart_rounded,
    routePath: '/pos/new-sale',
    anyOfPermissionKeys: PosPermissionAccess.newSaleAccessCodes,
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
    anyOfPermissionKeys: PosPermissionAccess.customerViewAccessCodes,
    routeExists: true,
  ),
  PosShellNavDestination(
    key: 'returns-refunds',
    label: 'Returns & Exchanges',
    icon: Icons.assignment_return_outlined,
    routePath: '/pos/returns-refunds',
    permissionKey: PosPermissionCodes.viewReturns,
    routeExists: true,
  ),
  PosShellNavDestination(
    key: 'cash-drawer',
    label: 'Cash Drawer',
    icon: Icons.point_of_sale_outlined,
    routePath: '/pos/cash-drawer',
    anyOfPermissionKeys: PosPermissionAccess.cashDrawerViewAccessCodes,
    routeExists: true,
  ),
  PosShellNavDestination(
    key: 'reports',
    label: 'Reports',
    icon: Icons.bar_chart_rounded,
    anyOfPermissionKeys: [
      'report.view',
      'reports.view',
      'report.sales.view',
      'reports.sales.view',
    ],
    unavailableMessage: 'Reports screen is not available yet.',
  ),
];
