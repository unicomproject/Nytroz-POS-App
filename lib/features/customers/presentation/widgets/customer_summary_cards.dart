import 'package:flutter/material.dart';

import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../providers/customers_provider.dart';
import 'customer_summary_card.dart';

class CustomerSummaryCards extends StatelessWidget {
  const CustomerSummaryCards({
    super.key,
    required this.summary,
  });

  final CustomersSummaryState summary;

  @override
  Widget build(BuildContext context) {
    final hasError = summary.errorMessage != null;
    final cards = [
      CustomerSummaryCard(
        label: 'Total Customers',
        icon: Icons.people_alt_rounded,
        iconColor: TenantAdminColors.info,
        iconBackground: const Color(0xFFE8F1FF),
        value: summary.totalCustomers?.toString(),
        isLoading: summary.isLoading,
        error: hasError,
      ),
      CustomerSummaryCard(
        label: 'Active Customers',
        icon: Icons.person_add_alt_1_rounded,
        iconColor: TenantAdminColors.success,
        iconBackground: const Color(0xFFE8F8EF),
        value: summary.activeCustomers?.toString(),
        isLoading: summary.isLoading,
        error: hasError,
      ),
      CustomerSummaryCard(
        label: 'Customers With Orders',
        icon: Icons.shopping_bag_outlined,
        iconColor: TenantAdminColors.pending,
        iconBackground: const Color(0xFFF3E8FF),
        value: summary.customersWithOrders?.toString(),
        isUnavailable: !summary.customersWithOrdersAvailable,
        isLoading: summary.isLoading,
        error: hasError,
      ),
      CustomerSummaryCard(
        label: 'New Customers This Month',
        icon: Icons.auto_awesome_rounded,
        iconColor: TenantAdminColors.warning,
        iconBackground: const Color(0xFFFFF4E5),
        value: summary.newCustomersThisMonth?.toString(),
        isUnavailable: !summary.newCustomersThisMonthAvailable,
        isLoading: summary.isLoading,
        error: hasError,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        const gap = TenantAdminSpacing.md;
        final columns = width >= 1050
            ? 4
            : width >= 700
                ? 2
                : 1;
        final itemWidth = (width - (gap * (columns - 1))) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final card in cards)
              SizedBox(width: itemWidth, child: card),
          ],
        );
      },
    );
  }
}
