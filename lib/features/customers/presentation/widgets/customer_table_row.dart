import 'package:flutter/material.dart';

import '../../../sale/domain/entities/pos_customer.dart';
import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import 'customer_status_badge.dart';

class CustomerTableRow extends StatelessWidget {
  const CustomerTableRow({
    super.key,
    required this.customer,
    required this.selected,
    required this.showSecondaryColumns,
    required this.onSelect,
  });

  final PosCustomer customer;
  final bool selected;
  final bool showSecondaryColumns;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: TenantAdminColors.bodyText,
          fontWeight: FontWeight.w600,
        );

    return Material(
      color: selected ? const Color(0xFFEEF3FF) : TenantAdminColors.surface,
      child: InkWell(
        onTap: onSelect,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: TenantAdminSpacing.lg,
            vertical: TenantAdminSpacing.md,
          ),
          decoration: BoxDecoration(
            border: Border(
              bottom: const BorderSide(color: TenantAdminColors.border),
              left: BorderSide(
                color: selected ? TenantAdminColors.primary : Colors.transparent,
                width: 3,
              ),
              right: BorderSide(
                color: selected ? TenantAdminColors.primary : Colors.transparent,
                width: 1,
              ),
              top: BorderSide(
                color: selected ? TenantAdminColors.primary : Colors.transparent,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              _Cell(customer.shortCustomerId, flex: 14, style: textStyle),
              _Cell(customer.displayName, flex: 18, style: textStyle),
              _Cell(customer.phone?.trim().isNotEmpty == true
                  ? customer.phone!.trim()
                  : '—', flex: 12, style: textStyle),
              if (showSecondaryColumns)
                _Cell(
                  customer.email?.trim().isNotEmpty == true
                      ? customer.email!.trim()
                      : '—',
                  flex: 18,
                  style: textStyle,
                ),
              if (showSecondaryColumns)
                Expanded(
                  flex: 10,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: CustomerSourceBadge(customer: customer),
                  ),
                ),
              Expanded(
                flex: 10,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: CustomerStatusBadge(customer: customer),
                ),
              ),
              if (showSecondaryColumns)
                _Cell(customer.ordersDisplay, flex: 10, style: textStyle),
              if (showSecondaryColumns)
                _Cell(customer.spentDisplay, flex: 12, style: textStyle),
              Expanded(
                flex: 8,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    tooltip: 'View details',
                    onPressed: onSelect,
                    style: IconButton.styleFrom(
                      backgroundColor: selected
                          ? TenantAdminColors.primary
                          : const Color(0xFFF1F5F9),
                      foregroundColor:
                          selected ? Colors.white : TenantAdminColors.bodyText,
                      minimumSize: const Size(36, 36),
                    ),
                    icon: const Icon(Icons.visibility_outlined, size: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        customer.sourceLabel,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: TenantAdminColors.primary,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class CustomerListCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFEEF3FF) : TenantAdminColors.surface,
      borderRadius: BorderRadius.circular(TenantAdminRadius.md),
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        child: Container(
          padding: const EdgeInsets.all(TenantAdminSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(TenantAdminRadius.md),
            border: Border.all(
              color: selected
                  ? TenantAdminColors.primary
                  : TenantAdminColors.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      customer.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: TenantAdminColors.bodyText,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  CustomerStatusBadge(customer: customer),
                ],
              ),
              const SizedBox(height: TenantAdminSpacing.sm),
              Text(
                customer.shortCustomerId,
                style: const TextStyle(
                  color: TenantAdminColors.mutedText,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: TenantAdminSpacing.xs),
              Text(
                customer.phone?.trim().isNotEmpty == true
                    ? customer.phone!.trim()
                    : 'No phone',
                style: const TextStyle(
                  color: TenantAdminColors.bodyText,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (customer.email?.trim().isNotEmpty == true) ...[
                const SizedBox(height: TenantAdminSpacing.xs),
                Text(
                  customer.email!.trim(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: TenantAdminColors.mutedText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell(this.value, {required this.flex, this.style});

  final String value;
  final int flex;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: style ??
            const TextStyle(
              color: TenantAdminColors.mutedText,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
