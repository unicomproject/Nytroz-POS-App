import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nytroz_pos/shared/presentation/app_modal.dart';

import '../../domain/entities/tenant_admin_menu_item.dart';

class TenantAdminBottomNav extends StatelessWidget {
  const TenantAdminBottomNav({
    super.key,
    required this.items,
    required this.currentPath,
  });

  final List<TenantAdminMenuItem> items;
  final String currentPath;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    if (items.length == 1) {
      final item = items.first;

      return BottomAppBar(
        child: SafeArea(
          child: ListTile(
            leading: Icon(_iconFor(item.iconKey)),
            title: Text(item.label),
            selected: currentPath == item.route,
            onTap: () => context.go(item.route),
          ),
        ),
      );
    }

    final primaryItems = items.take(4).toList(growable: false);
    final moreItems = items.skip(4).toList(growable: false);
    final navItems = [
      ...primaryItems,
      if (moreItems.isNotEmpty)
        const TenantAdminMenuItem(
          key: 'more',
          label: 'More',
          route: '',
          iconKey: 'more',
          featureCode: '',
          permissionCode: '',
          visible: true,
          order: 999,
        ),
    ];
    final selectedIndex =
        navItems.indexWhere((item) => item.route == currentPath);
    final currentPathIsInMore =
        moreItems.any((item) => item.route == currentPath);

    return BottomNavigationBar(
      currentIndex: selectedIndex < 0
          ? currentPathIsInMore
              ? navItems.length - 1
              : 0
          : selectedIndex,
      type: BottomNavigationBarType.fixed,
      onTap: (index) {
        final item = navItems[index];

        if (item.key == 'more') {
          _showMoreMenu(context, moreItems);
          return;
        }

        context.go(item.route);
      },
      items: [
        for (final item in navItems)
          BottomNavigationBarItem(
            icon: Icon(_iconFor(item.iconKey)),
            label: item.label,
          ),
      ],
    );
  }
}

void _showMoreMenu(BuildContext context, List<TenantAdminMenuItem> items) {
  showAppModalBottomSheet<void>(
    context: context,
    builder: (context) {
      return SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final item in items)
              ListTile(
                leading: Icon(_iconFor(item.iconKey)),
                title: Text(item.label),
                onTap: () {
                  Navigator.of(context).pop();
                  context.go(item.route);
                },
              ),
          ],
        ),
      );
    },
  );
}

IconData _iconFor(String iconKey) {
  switch (iconKey) {
    case 'dashboard':
      return Icons.dashboard;
    case 'store':
      return Icons.store;
    case 'till':
      return Icons.payment;
    case 'users':
      return Icons.people;
    case 'shield':
      return Icons.security;
    case 'products':
      return Icons.list;
    case 'inventory':
      return Icons.storage;
    case 'reports':
      return Icons.insert_chart;
    case 'billing':
      return Icons.receipt;
    case 'settings':
      return Icons.settings;
    case 'activity':
      return Icons.history;
    case 'more':
      return Icons.more_horiz;
    default:
      return Icons.fiber_manual_record;
  }
}
