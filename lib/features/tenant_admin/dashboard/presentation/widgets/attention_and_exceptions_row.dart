import 'package:flutter/material.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';

class AttentionAndExceptionsRow extends StatelessWidget {
  const AttentionAndExceptionsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 800;

        final needsAttention = _NeedsAttentionSection();
        final storeExceptions = _StoreExceptionsSection();

        if (isMobile) {
          return Column(
            children: [
              needsAttention,
              const SizedBox(height: 24),
              storeExceptions,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: needsAttention),
            const SizedBox(width: 24),
            Expanded(child: storeExceptions),
          ],
        );
      },
    );
  }
}

class _NeedsAttentionSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TenantAdminColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Needs Attention Today',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: TenantAdminColors.navy,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '3',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFFF7A00),
                  ),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  foregroundColor: TenantAdminColors.primary,
                  textStyle: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13),
                ),
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildCard(
                  icon: Icons.receipt_long,
                  iconColor: TenantAdminColors.danger,
                  iconBg: const Color(0xFFFEE2E2),
                  title: '3 failed payments',
                  subtitle: 'Total LKR 6,750.00',
                  actionText: 'View Transactions',
                  actionColor: TenantAdminColors.danger,
                ),
                const SizedBox(width: 16),
                _buildCard(
                  icon: Icons.local_shipping_outlined,
                  iconColor: const Color(0xFFFF7A00),
                  iconBg: const Color(0xFFFFF7ED),
                  title: '1 delayed supplier delivery',
                  subtitle: 'Expected today',
                  actionText: 'Track Delivery',
                  actionColor: const Color(0xFFFF7A00),
                ),
                const SizedBox(width: 16),
                _buildCard(
                  icon: Icons.description_outlined,
                  iconColor: const Color(0xFF3B82F6),
                  iconBg: const Color(0xFFEFF6FF),
                  title: 'VAT summary pending',
                  subtitle: 'May 2025',
                  actionText: 'Complete Now',
                  actionColor: const Color(0xFF3B82F6),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required String actionText,
    required Color actionColor,
  }) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TenantAdminColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: TenantAdminColors.navy,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: TenantAdminColors.mutedText,
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () {},
            child: Text(
              actionText,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: actionColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StoreExceptionsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TenantAdminColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Store Exceptions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: TenantAdminColors.navy,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  foregroundColor: TenantAdminColors.primary,
                  textStyle: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13),
                ),
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildCard(
                  icon: Icons.trending_down,
                  iconColor: TenantAdminColors.danger,
                  iconBg: const Color(0xFFFEE2E2),
                  title: 'Outlet Lake Road',
                  subtitle: 'Sales down 22%',
                  statText: 'vs Yesterday',
                  statColor: TenantAdminColors.danger,
                  actionText: 'Investigate',
                  actionColor: TenantAdminColors.danger,
                ),
                const SizedBox(width: 16),
                _buildCard(
                  icon: Icons.schedule,
                  iconColor: const Color(0xFFFF7A00),
                  iconBg: const Color(0xFFFFF7ED),
                  title: 'Outlet City Center',
                  subtitle: 'High voids 8.7%',
                  statText: 'vs Target 3%',
                  statColor: const Color(0xFFFF7A00),
                  actionText: 'Review Now',
                  actionColor: const Color(0xFFFF7A00),
                ),
                const SizedBox(width: 16),
                _buildCard(
                  icon: Icons.shopping_cart_outlined,
                  iconColor: const Color(0xFF3B82F6),
                  iconBg: const Color(0xFFEFF6FF),
                  title: 'Outlet Negombo',
                  subtitle: 'Low sales items',
                  statText: '18 items',
                  statColor: TenantAdminColors.navy,
                  actionText: 'View Items',
                  actionColor: const Color(0xFF3B82F6),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required String statText,
    required Color statColor,
    required String actionText,
    required Color actionColor,
  }) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TenantAdminColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: TenantAdminColors.mutedText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: TenantAdminColors.navy,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            statText,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: statColor,
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () {},
            child: Text(
              actionText,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: actionColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
