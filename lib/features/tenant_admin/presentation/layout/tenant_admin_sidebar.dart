import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/tenant_admin_menu_item.dart';
import '../theme/tenant_admin_theme.dart';

class TenantAdminSidebar extends StatelessWidget {
  const TenantAdminSidebar({
    super.key,
    required this.items,
    required this.currentPath,
  });

  final List<TenantAdminMenuItem> items;
  final String currentPath;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      color: TenantAdminColors.navy,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Nytroz POS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final selected = currentPath == item.route;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: ListTile(
                      selected: selected,
                      selectedTileColor: Colors.white.withValues(alpha: 0.12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      leading: Icon(
                        _iconFor(item.iconKey),
                        color: selected ? Colors.white : Colors.white70,
                      ),
                      title: Text(
                        item.label,
                        style: TextStyle(
                          color: selected ? Colors.white : Colors.white70,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      onTap: () => context.go(item.route),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
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
    default:
      return Icons.fiber_manual_record;
  }
}
