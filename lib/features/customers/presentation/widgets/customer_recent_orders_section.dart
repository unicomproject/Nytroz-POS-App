import 'package:flutter/material.dart';

import '../../../sale/domain/entities/pos_customer.dart';
import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

class CustomerRecentOrdersSection extends StatelessWidget {
  const CustomerRecentOrdersSection({
    super.key,
    required this.orders,
    this.isLoading = false,
    this.errorMessage,
    this.onViewAll,
    this.showAmounts = true,
  });

  final List<PosCustomerOrder> orders;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onViewAll;
  final bool showAmounts;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Recent Purchases',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: Colors.black,
              ),
            ),
            const Spacer(),
            OutlinedButton(
              onPressed: onViewAll,
              style: OutlinedButton.styleFrom(
                foregroundColor: TenantAdminColors.posHomeAccentOrange,
                side: BorderSide(color: TenantAdminColors.posHomeAccentOrange),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                minimumSize: const Size(60, 28),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _buildBody(context),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (errorMessage != null && errorMessage!.trim().isNotEmpty) {
      return Text(
        errorMessage!,
        style: const TextStyle(
          color: TenantAdminColors.mutedText,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      );
    }

    if (orders.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E6ED)),
        ),
        child: const Center(
          child: Text(
            'No recent purchases found.',
            style: TextStyle(
              color: Color(0xFF8E9BAE),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        for (var i = 0; i < orders.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          _OrderRow(order: orders[i], showAmounts: showAmounts),
        ],
      ],
    );
  }
}

class _OrderRow extends StatelessWidget {
  const _OrderRow({required this.order, required this.showAmounts});

  final PosCustomerOrder order;
  final bool showAmounts;

  @override
  Widget build(BuildContext context) {
    final amount = order.currencyCode.trim().isEmpty
        ? (order.totalAmount == null
            ? '—'
            : 'LKR ${order.totalAmount!.toStringAsFixed(2)}')
        : (order.totalAmount == null
            ? '—'
            : '${order.currencyCode} ${order.totalAmount!.toStringAsFixed(2)}');
    final date = order.orderDate == null
        ? 'Today, 10:45 AM'
        : _formatOrderDate(order.orderDate!);
    final till = order.tillName?.trim().isNotEmpty == true
        ? order.tillName!.trim()
        : 'Till 01';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E6ED)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFE2E6ED)),
            ),
            child: const Icon(
              Icons.shopping_bag_outlined,
              size: 18,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.orderNumber.startsWith('Order')
                      ? order.orderNumber
                      : 'Order #${order.orderNumber}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$date  |  $till',
                  style: const TextStyle(
                    color: Color(0xFF8E9BAE),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (showAmounts)
            Text(
              amount,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: Colors.black,
              ),
            ),
        ],
      ),
    );
  }
}

String _formatOrderDate(DateTime date) {
  final now = DateTime.now();
  final diff = now.difference(date);
  final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
  final ampm = date.hour >= 12 ? 'PM' : 'AM';
  final timeStr = '$hour:${date.minute.toString().padLeft(2, '0')} $ampm';
  if (diff.inDays == 0) {
    return 'Today, $timeStr';
  } else if (diff.inDays == 1) {
    return 'Yesterday, $timeStr';
  } else {
    return '${date.day.toString().padLeft(2, '0')} ${_monthName(date.month)} ${date.year}, $timeStr';
  }
}

String _monthName(int month) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return months[(month - 1).clamp(0, 11)];
}
