import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/providers/session_provider.dart';
import '../../domain/entities/tenant_admin_context.dart';
import '../../domain/entities/tenant_admin_menu_item.dart';
import '../../domain/services/tenant_admin_access_checker.dart';

class TenantAdminSidebar extends ConsumerWidget {
  const TenantAdminSidebar({
    super.key,
    required this.items,
    required this.currentPath,
    this.tenantContext,
    this.accessChecker,
  });

  final List<TenantAdminMenuItem> items;
  final String currentPath;
  final TenantAdminContext? tenantContext;
  final TenantAdminAccessChecker? accessChecker;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: 230,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF06162D),
            Color(0xFF0B2142),
            Color(0xFF111A3F),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 18, 18),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF5A4BFF),
                          Color(0xFF0EA5E9),
                          Color(0xFF22C55E),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.14),
                      ),
                    ),
                    child: const Icon(
                      Icons.shopping_cart,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nytroz POS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.2,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Tenant Admin',
                          style: TextStyle(
                            color: Color(0xFF9FB0CA),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 2, 14, 14),
                children: [
                  for (final item in items)
                    _SidebarNavItem(
                      icon: _iconFor(item.iconKey),
                      label: item.label,
                      selected: currentPath == item.route ||
                          currentPath.startsWith('${item.route}/'),
                      onTap: () => context.go(item.route),
                    ),
                  const _SidebarNavItem(
                    icon: Icons.help_outline,
                    label: 'Help & Support',
                    selected: false,
                    enabled: false,
                  ),
                ],
              ),
            ),
            _SidebarFooter(
              tenantContext: tenantContext,
              accessChecker: accessChecker,
              onSignOut: () => _signOut(ref, context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _signOut(WidgetRef ref, BuildContext context) async {
    await ref.read(authSessionProvider.notifier).clear();
    if (context.mounted) {
      context.go('/tenant-login');
    }
  }
}

class _SidebarNavItem extends StatelessWidget {
  const _SidebarNavItem({
    required this.icon,
    required this.label,
    required this.selected,
    this.enabled = true,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final itemColor = selected
        ? Colors.white
        : enabled
            ? const Color(0xFFD8E0EE)
            : const Color(0xFF7D8BA3);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: enabled ? onTap : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFF3F2BFF) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: const Color(0xFF3F2BFF).withValues(alpha: 0.30),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: selected
                      ? Colors.white
                      : enabled
                          ? const Color(0xFFB8C4D8)
                          : const Color(0xFF708097),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: itemColor,
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarFooter extends StatelessWidget {
  const _SidebarFooter({
    required this.onSignOut,
    this.tenantContext,
    this.accessChecker,
  });

  final TenantAdminContext? tenantContext;
  final TenantAdminAccessChecker? accessChecker;
  final VoidCallback onSignOut;

  bool get _showTenantInfo {
    if (tenantContext == null || accessChecker == null) {
      return false;
    }

    return accessChecker!.canViewTenantContext() ||
        accessChecker!.canViewSubscription();
  }

  @override
  Widget build(BuildContext buildContext) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_showTenantInfo) ...[
              if (accessChecker!.canViewTenantContext()) ...[
                Text(
                  tenantContext!.tenantName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tenantContext!.userDisplayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFB8C4D8),
                    fontSize: 12,
                  ),
                ),
              ],
              if (accessChecker!.canViewSubscription() &&
                  tenantContext!.subscriptionStatus != null &&
                  tenantContext!.subscriptionStatus!.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                _FooterMetaRow(
                  label: 'Plan status',
                  value: tenantContext!.subscriptionStatus!,
                ),
              ],
              const SizedBox(height: 8),
              const _FooterMetaRow(label: 'Next billing', value: 'Pending'),
              const _FooterMetaRow(label: 'Version', value: 'Release 1'),
              const SizedBox(height: 12),
            ],
            InkWell(
              onTap: onSignOut,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.logout, color: Colors.white70, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Sign out',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FooterMetaRow extends StatelessWidget {
  const _FooterMetaRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF8FA2BF),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
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
    case 'help':
    case 'support':
      return Icons.help_outline;
    default:
      return Icons.fiber_manual_record;
  }
}
