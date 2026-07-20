import 'package:flutter/material.dart';

import '../../../sale/domain/entities/pos_customer.dart';
import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

class CustomerRecentOrdersSection extends StatelessWidget {
  const CustomerRecentOrdersSection({
    super.key,
    required this.orders,
    this.isLoading = false,
    this.errorMessage,
  });

  final List<PosCustomerOrder> orders;
  final bool isLoading;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Orders',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: TenantAdminColors.bodyText,
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: TenantAdminSpacing.md),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(TenantAdminSpacing.lg),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(TenantAdminRadius.md),
            border: Border.all(color: TenantAdminColors.border),
          ),
          child: _buildBody(context),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (errorMessage != null && errorMessage!.trim().isNotEmpty) {
      return Text(
        errorMessage!,
        style: const TextStyle(
          color: TenantAdminColors.mutedText,
          fontWeight: FontWeight.w600,
          height: 1.35,
        ),
      );
    }

    if (orders.isEmpty) {
      return const Text(
        'No recent orders for this customer.',
        style: TextStyle(
          color: TenantAdminColors.mutedText,
          fontWeight: FontWeight.w600,
          height: 1.35,
        ),
      );
    }

    return Column(
      children: [
        for (var i = 0; i < orders.length; i++) ...[
          if (i > 0) const SizedBox(height: TenantAdminSpacing.md),
          _OrderRow(order: orders[i]),
        ],
      ],
    );
  }
}

class _OrderRow extends StatelessWidget {
  const _OrderRow({required this.order});

  final PosCustomerOrder order;

  @override
  Widget build(BuildContext context) {
    final amount = order.currencyCode.trim().isEmpty
        ? order.totalAmount.toStringAsFixed(2)
        : '${order.currencyCode} ${order.totalAmount.toStringAsFixed(2)}';
    final date = order.orderDate == null
        ? '—'
        : '${order.orderDate!.year}-${order.orderDate!.month.toString().padLeft(2, '0')}-${order.orderDate!.day.toString().padLeft(2, '0')}';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                order.orderNumber,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: TenantAdminColors.bodyText,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$date · ${order.status}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: TenantAdminColors.mutedText,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Text(
          amount,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: TenantAdminColors.bodyText,
          ),
        ),
      ],
    );
  }
}
