import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nytroz_pos/core/access/permission_access_providers.dart';
import 'package:nytroz_pos/core/access/pos_customers_orders_returns_visibility.dart';

import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

class CustomerTableHeader extends ConsumerWidget {
  const CustomerTableHeader({
    super.key,
    this.showSecondaryColumns = true,
  });

  final bool showSecondaryColumns;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(effectivePermissionSetProvider);
    final cells = <Widget>[];

    void add(String label, int flex, {bool sortable = false}) {
      cells.add(_HeaderCell(label, flex: flex, sortable: sortable));
    }

    if (showSecondaryColumns) {
      if (PosCustomersOrdersReturnsVisibility.canShowCustomerId(p)) {
        add('Customer ID', 14);
      }
      if (PosCustomersOrdersReturnsVisibility.canShowCustomerName(p)) {
        add('Customer', 18, sortable: true);
      }
      if (PosCustomersOrdersReturnsVisibility.canShowCustomerPhone(p)) {
        add('Phone', 12);
      }
      if (PosCustomersOrdersReturnsVisibility.canShowCustomerEmail(p)) {
        add('Email', 18);
      }
      if (PosCustomersOrdersReturnsVisibility.canShowCustomerSource(p)) {
        add('Source', 10);
      }
      if (PosCustomersOrdersReturnsVisibility.canShowCustomerStatus(p)) {
        add('Status', 10);
      }
      if (PosCustomersOrdersReturnsVisibility.canShowCustomerOrderCount(p)) {
        add('Orders', 10);
      }
      if (PosCustomersOrdersReturnsVisibility.canShowCustomerTotalSpend(p)) {
        add('Total Spend', 12);
      }
    } else {
      if (PosCustomersOrdersReturnsVisibility.canShowCustomerName(p)) {
        add('Customer', 22, sortable: true);
      }
      if (PosCustomersOrdersReturnsVisibility.canShowCustomerPhone(p)) {
        add('Phone', 15);
      }
      if (PosCustomersOrdersReturnsVisibility.canShowCustomerEmail(p)) {
        add('Email', 22);
      }
      if (PosCustomersOrdersReturnsVisibility.canShowRecentPurchases(p)) {
        add('Last Purchase', 16);
      }
      if (PosCustomersOrdersReturnsVisibility.canShowCustomerTotalSpend(p)) {
        add('Total Spend', 15);
      }
      cells.add(const SizedBox(width: 48));
    }

    if (cells.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2E6ED)),
        ),
      ),
      child: Row(children: cells),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(
    this.label, {
    required this.flex,
    this.sortable = false,
  });

  final String label;
  final int flex;
  final bool sortable;

  @override
  Widget build(BuildContext context) {
    const headerStyle = TextStyle(
      color: TenantAdminColors.posHomeAccentOrange,
      fontWeight: FontWeight.w800,
      fontSize: 13,
    );

    return Expanded(
      flex: flex,
      child: Row(
        children: [
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: headerStyle,
            ),
          ),
          if (sortable) ...[
            const SizedBox(width: 4),
            const Icon(
              Icons.unfold_more_rounded,
              size: 14,
              color: TenantAdminColors.posHomeAccentOrange,
            ),
          ],
        ],
      ),
    );
  }
}
