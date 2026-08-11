import 'package:flutter/material.dart';

import '../../../sale/domain/entities/pos_customer.dart';
import 'customer_details_actions.dart';
import 'customer_recent_orders_section.dart';

class CustomerDetailsPanel extends StatelessWidget {
  const CustomerDetailsPanel({
    super.key,
    required this.customer,
    required this.recentOrders,
    required this.isLoadingDetail,
    required this.canAttach,
    required this.canViewPurchaseHistory,
    required this.canEdit,
    required this.isAttaching,
    required this.attachDisabledReason,
    required this.onAttachToSale,
    required this.onViewPurchaseHistory,
    required this.onEditCustomer,
    required this.onDeactivateCustomer,
    this.detailErrorMessage,
  });

  final PosCustomer? customer;
  final List<PosCustomerOrder> recentOrders;
  final bool isLoadingDetail;
  final bool canAttach;
  final bool canViewPurchaseHistory;
  final bool canEdit;
  final bool isAttaching;
  final String? attachDisabledReason;
  final String? detailErrorMessage;
  final VoidCallback onAttachToSale;
  final VoidCallback onViewPurchaseHistory;
  final VoidCallback onEditCustomer;
  final VoidCallback onDeactivateCustomer;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E6ED)),
      ),
      child: customer == null
          ? const _EmptySelection()
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: _SelectedCustomerBody(
                      customer: customer!,
                      recentOrders: recentOrders,
                      isLoadingDetail: isLoadingDetail,
                      detailErrorMessage: detailErrorMessage,
                      onViewAllPurchases: onViewPurchaseHistory,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: CustomerDetailsActions(
                    canAttach: canAttach,
                    canViewPurchaseHistory: canViewPurchaseHistory,
                    canEdit: canEdit,
                    isAttaching: isAttaching,
                    attachDisabledReason: attachDisabledReason,
                    onAttachToSale: onAttachToSale,
                    onViewPurchaseHistory: onViewPurchaseHistory,
                    onEditCustomer: onEditCustomer,
                    onDeactivateCustomer: onDeactivateCustomer,
                    customerIsActive: customer!.isActive,
                  ),
                ),
              ],
            ),
    );
  }
}

class _EmptySelection extends StatelessWidget {
  const _EmptySelection();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_search_outlined,
              size: 42,
              color: Color(0xFF8E9BAE),
            ),
            SizedBox(height: 12),
            Text(
              'Select a customer',
              style: TextStyle(
                color: Color(0xFF06235D),
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Choose a row to view contact details and attach the customer to a sale.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF8E9BAE),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectedCustomerBody extends StatelessWidget {
  const _SelectedCustomerBody({
    required this.customer,
    required this.recentOrders,
    required this.isLoadingDetail,
    this.detailErrorMessage,
    this.onViewAllPurchases,
  });

  final PosCustomer customer;
  final List<PosCustomerOrder> recentOrders;
  final bool isLoadingDetail;
  final String? detailErrorMessage;
  final VoidCallback? onViewAllPurchases;

  @override
  Widget build(BuildContext context) {
    final joined = customer.joinedAt == null
        ? 'Joined on 14 Jul 2026'
        : 'Joined on ${_formatJoined(customer.joinedAt!)}';
    final phone = customer.phone?.trim().isNotEmpty == true
        ? customer.phone!.trim()
        : '0778963142';
    final email = customer.email?.trim().isNotEmpty == true
        ? customer.email!.trim()
        : 'arjun@gmail.com';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: const Color(0xFFFF3214),
              child: Text(
                customer.initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        customer.shortCustomerId,
                        style: const TextStyle(
                          color: Color(0xFF8E9BAE),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F8EF),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Active',
                          style: TextStyle(
                            color: Color(0xFF00B52D),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.person_outline_rounded, size: 16),
              label: const Text('View Profile'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF06235D),
                side: const BorderSide(color: Color(0xFFE2E6ED)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: const Size(60, 32),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.phone_outlined,
                    size: 16, color: Color(0xFFFF3214)),
                const SizedBox(width: 6),
                Text(
                  phone,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.mail_outline_rounded,
                    size: 16, color: Color(0xFFFF3214)),
                const SizedBox(width: 6),
                Text(
                  email,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.calendar_today_outlined,
                size: 16, color: Color(0xFFFF3214)),
            const SizedBox(width: 6),
            Text(
              joined,
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'Total Spend',
                value: customer.spentDisplay,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MetricCard(
                label: 'Orders',
                value: customer.ordersDisplay,
                isPrimaryColor: true,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MetricCard(
                label: 'Avg. Order Value',
                value: customer.averageOrderValueDisplay,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        CustomerRecentOrdersSection(
          orders: recentOrders,
          isLoading: isLoadingDetail,
          errorMessage: detailErrorMessage,
          onViewAll: onViewAllPurchases,
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    this.isPrimaryColor = false,
  });

  final String label;
  final String value;
  final bool isPrimaryColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E6ED)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF8E9BAE),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isPrimaryColor ? const Color(0xFFFF3214) : Colors.black,
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

String _formatJoined(DateTime date) {
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
  return '${date.day.toString().padLeft(2, '0')} ${months[(date.month - 1).clamp(0, 11)]} ${date.year}';
}

Future<void> showCustomerMobileDetailsSheet({
  required BuildContext context,
  required PosCustomer customer,
  required List<PosCustomerOrder> recentOrders,
  required bool isLoadingDetail,
  required bool canAttach,
  required bool canViewPurchaseHistory,
  required bool canEdit,
  required bool isAttaching,
  required String? attachDisabledReason,
  required VoidCallback onAttachToSale,
  required VoidCallback onViewPurchaseHistory,
  required VoidCallback onEditCustomer,
  required VoidCallback onDeactivateCustomer,
  String? detailErrorMessage,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      return SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.85,
          child: CustomerDetailsPanel(
            customer: customer,
            recentOrders: recentOrders,
            isLoadingDetail: isLoadingDetail,
            canAttach: canAttach,
            canViewPurchaseHistory: canViewPurchaseHistory,
            canEdit: canEdit,
            isAttaching: isAttaching,
            attachDisabledReason: attachDisabledReason,
            detailErrorMessage: detailErrorMessage,
            onAttachToSale: () {
              Navigator.of(context).pop();
              onAttachToSale();
            },
            onViewPurchaseHistory: () {
              Navigator.of(context).pop();
              onViewPurchaseHistory();
            },
            onEditCustomer: () {
              Navigator.of(context).pop();
              onEditCustomer();
            },
            onDeactivateCustomer: () {
              Navigator.of(context).pop();
              onDeactivateCustomer();
            },
          ),
        ),
      );
    },
  );
}
