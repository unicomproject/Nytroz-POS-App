import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nytroz_pos/core/access/effective_permission_set.dart';
import 'package:nytroz_pos/core/access/permission_access_providers.dart';
import 'package:nytroz_pos/core/access/pos_customers_orders_returns_visibility.dart';

import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../sale/domain/entities/pos_customer.dart';
import 'customers_ui_tokens.dart';

Color _avatarBg(String name) {
  final hash = name.codeUnits.fold(0, (s, c) => s + c);
  const colors = [
    Color(0xFFCCE4FF),
    Color(0xFFD4F7DC),
    Color(0xFFFDE8E8),
    Color(0xFFEADBFF),
    Color(0xFFFFF3D6),
    Color(0xFFE2F0D9),
  ];
  return colors[hash % colors.length];
}

Color _avatarFg(String name) {
  final hash = name.codeUnits.fold(0, (s, c) => s + c);
  const colors = [
    Color(0xFF0066CC),
    Color(0xFF008833),
    Color(0xFFCC3333),
    Color(0xFF7722CC),
    Color(0xFFB37400),
    Color(0xFF336622),
  ];
  return colors[hash % colors.length];
}

class CustomerListCard extends ConsumerWidget {
  const CustomerListCard({
    super.key,
    required this.customer,
    required this.selected,
    required this.onSelect,
  });

  final PosCustomer customer;
  final bool selected;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(effectivePermissionSetProvider);

    return Semantics(
      button: true,
      selected: selected,
      label: 'Customer ${customer.displayName}',
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(TenantAdminSpacing.xl),
          decoration: BoxDecoration(
            color: selected
                ? TenantAdminColors.posHomeAccentOrange.withValues(alpha: 0.03)
                : TenantAdminColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? TenantAdminColors.posHomeAccentOrange
                  : TenantAdminColors.border.withValues(alpha: 0.6),
              width: selected ? 1.5 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: TenantAdminColors.posHomeAccentOrange
                          .withValues(alpha: 0.12),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _CustomerThumbnail(customer: customer),
              const SizedBox(width: TenantAdminSpacing.xl),
              Expanded(
                child: _CustomerMainInfo(customer: customer, p: p),
              ),
              const SizedBox(width: TenantAdminSpacing.xl),
              IconButton(
                icon: const Icon(Icons.more_vert_rounded,
                    color: TenantAdminColors.mutedText),
                onPressed: onSelect,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomerThumbnail extends StatelessWidget {
  const _CustomerThumbnail({required this.customer});

  final PosCustomer customer;

  @override
  Widget build(BuildContext context) {
    const size = 64.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _avatarBg(customer.displayName),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: TenantAdminColors.border.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        customer.initials,
        style: TextStyle(
          color: _avatarFg(customer.displayName),
          fontWeight: FontWeight.w900,
          fontSize: 22,
        ),
      ),
    );
  }
}

class _CustomerMainInfo extends StatelessWidget {
  const _CustomerMainInfo({required this.customer, required this.p});

  final PosCustomer customer;
  final EffectivePermissionSet p;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stackMeta = constraints.maxWidth < 450;

        final nameRow = Row(
          children: [
            if (PosCustomersOrdersReturnsVisibility.canShowCustomerName(p))
              Flexible(
                child: Text(
                  customer.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: TenantAdminColors.navy,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            const SizedBox(width: TenantAdminSpacing.md),
            if (PosCustomersOrdersReturnsVisibility.canShowCustomerSource(p))
              CustomerSourceBadge(customer: customer),
          ],
        );

        Widget buildMetaItem(String label, Widget child) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: TenantAdminColors.mutedText,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 4),
              child,
            ],
          );
        }

        final codeBlock =
            PosCustomersOrdersReturnsVisibility.canShowCustomerId(p)
                ? buildMetaItem(
                    'Customer ID',
                    Text(
                      customer.shortCustomerId.isNotEmpty
                          ? customer.shortCustomerId
                          : '-',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: TenantAdminColors.bodyText,
                      ),
                    ),
                  )
                : const SizedBox.shrink();

        final contactBlock =
            (PosCustomersOrdersReturnsVisibility.canShowCustomerPhone(p) ||
                    PosCustomersOrdersReturnsVisibility.canShowCustomerEmail(p))
                ? buildMetaItem(
                    'Contact',
                    _ContactCell(
                      phone: PosCustomersOrdersReturnsVisibility
                              .canShowCustomerPhone(p)
                          ? customer.phone
                          : null,
                      email: PosCustomersOrdersReturnsVisibility
                              .canShowCustomerEmail(p)
                          ? customer.email
                          : null,
                    ),
                  )
                : const SizedBox.shrink();

        final spendBlock =
            PosCustomersOrdersReturnsVisibility.canShowCustomerTotalSpend(p)
                ? buildMetaItem(
                    'Total Spend',
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          customer.spentDisplay,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: TenantAdminColors.bodyText,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (PosCustomersOrdersReturnsVisibility
                            .canShowCustomerStatus(p))
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: customer.isActive
                                      ? TenantAdminColors.success
                                      : TenantAdminColors.warning,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                customer.isActive ? 'Active' : 'Inactive',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: TenantAdminColors.mutedText,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  )
                : const SizedBox.shrink();

        final divider = Container(
          width: 1,
          height: 32,
          color: TenantAdminColors.border.withValues(alpha: 0.6),
          margin: const EdgeInsets.symmetric(horizontal: TenantAdminSpacing.lg),
        );

        if (stackMeta) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              nameRow,
              const SizedBox(height: TenantAdminSpacing.lg),
              Wrap(
                spacing: TenantAdminSpacing.xl,
                runSpacing: TenantAdminSpacing.md,
                children: [
                  codeBlock,
                  contactBlock,
                  spendBlock,
                ],
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            nameRow,
            const SizedBox(height: TenantAdminSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (PosCustomersOrdersReturnsVisibility.canShowCustomerId(
                    p)) ...[
                  Expanded(child: codeBlock),
                  divider,
                ],
                Expanded(flex: 2, child: contactBlock),
                divider,
                Expanded(flex: 2, child: spendBlock),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _ContactCell extends StatelessWidget {
  const _ContactCell({this.phone, this.email});

  final String? phone;
  final String? email;

  @override
  Widget build(BuildContext context) {
    final hasPhone = phone != null && phone!.trim().isNotEmpty;
    final hasEmail = email != null && email!.trim().isNotEmpty;

    if (!hasPhone && !hasEmail) {
      return const Text(
        'Not provided',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: TenantAdminColors.mutedText,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasPhone)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.phone_outlined,
                  size: 14, color: TenantAdminColors.mutedText),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  phone!.trim(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: TenantAdminColors.bodyText,
                  ),
                ),
              ),
            ],
          ),
        if (hasEmail) ...[
          if (hasPhone) const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.mail_outline_rounded,
                  size: 14, color: TenantAdminColors.mutedText),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  email!.trim(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: TenantAdminColors.bodyText,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class CustomerSourceBadge extends StatelessWidget {
  const CustomerSourceBadge({
    super.key,
    required this.customer,
  });

  final PosCustomer customer;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: CustomersUiTokens.lightBlueSurface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: CustomersUiTokens.lightBlueBorder),
      ),
      child: Text(
        customer.sourceLabel,
        style: const TextStyle(
          color: CustomersUiTokens.accentText,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
