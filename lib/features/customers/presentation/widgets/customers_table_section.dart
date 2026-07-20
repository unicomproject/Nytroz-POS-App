import 'package:flutter/material.dart';

import '../../../sale/domain/entities/pos_customer.dart';
import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import 'customer_table_header.dart';
import 'customer_table_row.dart';
import 'customers_pagination.dart';

class CustomersTableSection extends StatelessWidget {
  const CustomersTableSection({
    super.key,
    required this.customers,
    required this.selectedCustomerId,
    required this.isLoading,
    required this.errorMessage,
    required this.query,
    required this.page,
    required this.totalPages,
    required this.rangeStart,
    required this.rangeEnd,
    required this.totalCount,
    required this.useCardLayout,
    required this.showSecondaryColumns,
    required this.onSelect,
    required this.onRetry,
    required this.onPageChanged,
  });

  final List<PosCustomer> customers;
  final String? selectedCustomerId;
  final bool isLoading;
  final String? errorMessage;
  final String query;
  final int page;
  final int totalPages;
  final int rangeStart;
  final int rangeEnd;
  final int totalCount;
  final bool useCardLayout;
  final bool showSecondaryColumns;
  final ValueChanged<String> onSelect;
  final VoidCallback onRetry;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        border: Border.all(color: TenantAdminColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Expanded(child: _buildBody(context)),
          const Divider(height: 1, color: TenantAdminColors.border),
          CustomersPagination(
            page: page,
            totalPages: totalPages,
            rangeStart: rangeStart,
            rangeEnd: rangeEnd,
            totalCount: totalCount,
            isLoading: isLoading,
            onPageChanged: onPageChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (isLoading && customers.isEmpty) {
      return CustomersTableBodyStates.loading();
    }

    if (errorMessage != null && customers.isEmpty) {
      return CustomersTableBodyStates.error(
        message: errorMessage!,
        onRetry: onRetry,
      );
    }

    if (customers.isEmpty) {
      final searching = query.trim().isNotEmpty;
      return CustomersTableBodyStates.empty(
        title: searching ? 'No matching customers' : 'No customers found',
        message: searching
            ? 'Try a different search or clear filters.'
            : 'Create a customer to get started.',
      );
    }

    if (useCardLayout) {
      return ListView.separated(
        padding: const EdgeInsets.all(TenantAdminSpacing.md),
        itemCount: customers.length,
        separatorBuilder: (_, __) =>
            const SizedBox(height: TenantAdminSpacing.sm),
        itemBuilder: (context, index) {
          final customer = customers[index];
          return CustomerListCard(
            customer: customer,
            selected: customer.customerId == selectedCustomerId,
            onSelect: () => onSelect(customer.customerId),
          );
        },
      );
    }

    return Column(
      children: [
        CustomerTableHeader(showSecondaryColumns: showSecondaryColumns),
        Expanded(
          child: ListView.builder(
            itemCount: customers.length,
            itemBuilder: (context, index) {
              final customer = customers[index];
              return CustomerTableRow(
                customer: customer,
                selected: customer.customerId == selectedCustomerId,
                showSecondaryColumns: showSecondaryColumns,
                onSelect: () => onSelect(customer.customerId),
              );
            },
          ),
        ),
      ],
    );
  }
}
