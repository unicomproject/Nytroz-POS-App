import 'package:flutter/material.dart';

import '../../../sale/domain/entities/pos_customer.dart';
import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import 'customer_details_actions.dart';
import 'customer_recent_orders_section.dart';
import 'customer_status_badge.dart';

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

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        border: Border.all(color: TenantAdminColors.border),
        boxShadow: TenantAdminShadows.card,
      ),
      child: customer == null
          ? const _EmptySelection()
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(TenantAdminSpacing.lg),
                    child: _SelectedCustomerBody(
                      customer: customer!,
                      recentOrders: recentOrders,
                      isLoadingDetail: isLoadingDetail,
                      detailErrorMessage: detailErrorMessage,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    TenantAdminSpacing.lg,
                    0,
                    TenantAdminSpacing.lg,
                    TenantAdminSpacing.lg,
                  ),
                  child: CustomerDetailsActions(
                    canAttach: canAttach,
                    canViewPurchaseHistory: canViewPurchaseHistory,
                    canEdit: canEdit,
                    isAttaching: isAttaching,
                    attachDisabledReason: attachDisabledReason,
                    onAttachToSale: onAttachToSale,
                    onViewPurchaseHistory: onViewPurchaseHistory,
                    onEditCustomer: onEditCustomer,
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
        padding: EdgeInsets.all(TenantAdminSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_search_outlined,
              size: 42,
              color: TenantAdminColors.mutedText,
            ),
            SizedBox(height: TenantAdminSpacing.md),
            Text(
              'Select a customer',
              style: TextStyle(
                color: TenantAdminColors.bodyText,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
            SizedBox(height: TenantAdminSpacing.sm),
            Text(
              'Choose a row to view contact details and attach the customer to a sale.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: TenantAdminColors.mutedText,
                fontWeight: FontWeight.w600,
                height: 1.35,
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
  });

  final PosCustomer customer;
  final List<PosCustomerOrder> recentOrders;
  final bool isLoadingDetail;
  final String? detailErrorMessage;

  @override
  Widget build(BuildContext context) {
    final joined = customer.joinedAt == null
        ? '—'
        : '${customer.joinedAt!.year}-${customer.joinedAt!.month.toString().padLeft(2, '0')}-${customer.joinedAt!.day.toString().padLeft(2, '0')}';
    final lastPurchase = customer.lastPurchaseAt == null
        ? '—'
        : '${customer.lastPurchaseAt!.year}-${customer.lastPurchaseAt!.month.toString().padLeft(2, '0')}-${customer.lastPurchaseAt!.day.toString().padLeft(2, '0')}';
    final spent = customer.spentDisplay;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: const Color(0xFFE8F1FF),
              child: Text(
                customer.initials,
                style: const TextStyle(
                  color: TenantAdminColors.primary,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: TenantAdminSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer.displayName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: TenantAdminColors.bodyText,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    customer.shortCustomerId,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: TenantAdminColors.mutedText,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: TenantAdminSpacing.sm),
                  CustomerStatusBadge(customer: customer),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: TenantAdminSpacing.xl),
        _InfoRow(
          icon: Icons.phone_outlined,
          label: customer.phone?.trim().isNotEmpty == true
              ? customer.phone!.trim()
              : 'No phone on file',
        ),
        const SizedBox(height: TenantAdminSpacing.md),
        _InfoRow(
          icon: Icons.email_outlined,
          label: customer.email?.trim().isNotEmpty == true
              ? customer.email!.trim()
              : 'No email on file',
        ),
        const SizedBox(height: TenantAdminSpacing.md),
        _MetaRow(label: 'Source', value: customer.sourceLabel),
        const SizedBox(height: TenantAdminSpacing.sm),
        _MetaRow(label: 'Joined On', value: joined),
        const SizedBox(height: TenantAdminSpacing.xl),
        _MetaRow(label: 'Total Orders', value: customer.ordersDisplay),
        const SizedBox(height: TenantAdminSpacing.sm),
        _MetaRow(label: 'Total Spent', value: spent),
        const SizedBox(height: TenantAdminSpacing.sm),
        _MetaRow(label: 'Last Purchase', value: lastPurchase),
        const SizedBox(height: TenantAdminSpacing.xl),
        CustomerRecentOrdersSection(
          orders: recentOrders,
          isLoading: isLoadingDetail,
          errorMessage: detailErrorMessage,
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: TenantAdminColors.mutedText),
        const SizedBox(width: TenantAdminSpacing.sm),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: TenantAdminColors.bodyText,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: TenantAdminColors.mutedText,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: TenantAdminColors.bodyText,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
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
  String? detailErrorMessage,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: TenantAdminColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(TenantAdminRadius.lg),
      ),
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
          ),
        ),
      );
    },
  );
}
