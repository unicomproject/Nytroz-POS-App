import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/tenant_admin_context_provider.dart';
import '../theme/tenant_admin_theme.dart';

// State provider for selected outlet name
final selectedOutletProvider = StateProvider<String>((ref) => 'All Outlets');

class TenantAdminTopBar extends ConsumerWidget implements PreferredSizeWidget {
  const TenantAdminTopBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contextState = ref.watch(tenantAdminContextProvider);
    final selectedOutlet = ref.watch(selectedOutletProvider);

    final outletList = contextState.maybeWhen(
      data: (tenantContext) => tenantContext.outletScope,
      orElse: () => const [],
    );

    return Container(
      height: preferredSize.height,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE2E8F0), // Slate-200 bottom border
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Hamburger Menu Icon
          IconButton(
            icon: const Icon(
              Icons.menu_rounded,
              color: Color(0xFF64748B), // Slate-500
              size: 22,
            ),
            onPressed: () {
              // Expand/collapse sidebar if needed, or drawer on mobile
            },
          ),
          const SizedBox(width: 4),
          // Vertical Divider
          Container(
            height: 20,
            width: 1,
            color: const Color(0xFFCBD5E1), // Slate-300
          ),
          const SizedBox(width: 16),
          // Outlets Dropdown Selector
          PopupMenuButton<String>(
            tooltip: 'Select Outlet',
            offset: const Offset(0, 44),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            elevation: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    selectedOutlet,
                    style: const TextStyle(
                      color: Color(0xFF0F172A), // Slate-900
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: Color(0xFF64748B), // Slate-500
                  ),
                ],
              ),
            ),
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'All Outlets',
                child: Text(
                  'All Outlets',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              for (final outlet in outletList)
                PopupMenuItem<String>(
                  value: outlet.outletName,
                  child: Text(
                    outlet.outletName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
            onSelected: (value) {
              ref.read(selectedOutletProvider.notifier).state = value;
            },
          ),
          const Spacer(),
          // Search Icon
          IconButton(
            icon: const Icon(
              Icons.search_rounded,
              color: Color(0xFF64748B),
              size: 22,
            ),
            onPressed: () {},
          ),
          const SizedBox(width: 4),
          // Notification Bell Icon with Badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_none_rounded,
                  color: Color(0xFF64748B),
                  size: 24,
                ),
                onPressed: () {},
              ),
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444), // Red notification badge
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    '5',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          // User Avatar Profile
          contextState.maybeWhen(
            data: (tenantContext) => Tooltip(
              message: '${tenantContext.userDisplayName}\n${tenantContext.roleNames.join(", ")}',
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                    width: 1.5,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0F000000),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  tenantContext.userDisplayName.trim().isNotEmpty
                      ? tenantContext.userDisplayName.trim()[0].toUpperCase()
                      : 'U',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            orElse: () => const CircleAvatar(
              radius: 17,
              backgroundColor: Color(0xFFE2E8F0),
              child: Icon(Icons.person_rounded, size: 20, color: Color(0xFF94A3B8)),
            ),
          ),
        ],
      ),
    );
  }
}
