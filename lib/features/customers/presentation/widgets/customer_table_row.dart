import 'package:flutter/material.dart';

import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../sale/domain/entities/pos_customer.dart';
import 'customer_status_badge.dart';
import 'customers_ui_tokens.dart';

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
    final avatarColor = _avatarBg(customer.displayName);
    final avatarTextColor = _avatarFg(customer.displayName);
    final textStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Colors.black87,
          fontWeight: FontWeight.w600,
        );

    return Material(
      color: selected ? const Color(0xFFFFF2EC) : Colors.white,
      child: InkWell(
        onTap: onSelect,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: const BorderSide(color: Color(0xFFE2E6ED)),
              left: BorderSide(
                color: selected
                    ? TenantAdminColors.posHomeAccentOrange
                    : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Row(
            children: [
              if (showSecondaryColumns) ...[
                _Cell(customer.shortCustomerId, flex: 14, style: textStyle),
                _Cell(customer.displayName, flex: 18, style: textStyle),
                _Cell(
                  customer.phone?.trim().isNotEmpty == true
                      ? customer.phone!.trim()
                      : '—',
                  flex: 12,
                  style: textStyle,
                ),
                _Cell(
                  customer.email?.trim().isNotEmpty == true
                      ? customer.email!.trim()
                      : '—',
                  flex: 18,
                  style: textStyle,
                ),
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
                _Cell(customer.ordersDisplay, flex: 10, style: textStyle),
                _Cell(customer.spentDisplay, flex: 12, style: textStyle),
              ] else ...[
                Expanded(
                  flex: 22,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: avatarColor,
                        child: Text(
                          customer.initials,
                          style: TextStyle(
                            color: avatarTextColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              customer.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              customer.shortCustomerId,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF8E9BAE),
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 15,
                  child: Text(
                    customer.phone?.trim().isNotEmpty == true
                        ? customer.phone!.trim()
                        : '—',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                Expanded(
                  flex: 22,
                  child: Text(
                    customer.email?.trim().isNotEmpty == true
                        ? customer.email!.trim()
                        : '—',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
                Expanded(
                  flex: 16,
                  child: Text(
                    _formatLastPurchase(customer.lastPurchaseAt),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                Expanded(
                  flex: 15,
                  child: Text(
                    customer.spentDisplay,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert_rounded,
                      size: 18, color: Color(0xFF8E9BAE)),
                  onPressed: onSelect,
                  splashRadius: 18,
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
              color: Color(0xFF8E9BAE),
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

String _formatLastPurchase(DateTime? date) {
  if (date == null) return '—';
  final now = DateTime.now();
  final diff = now.difference(date);
  if (diff.inDays == 0) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final ampm = date.hour >= 12 ? 'PM' : 'AM';
    return 'Today, $hour:${date.minute.toString().padLeft(2, '0')} $ampm';
  } else if (diff.inDays == 1) {
    return 'Yesterday';
  } else if (diff.inDays < 7) {
    return '${diff.inDays} Days Ago';
  } else if (diff.inDays < 14) {
    return '1 Week Ago';
  } else {
    return '${(diff.inDays / 7).floor()} Weeks Ago';
  }
}

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
      color: selected ? const Color(0xFFFFF2EC) : Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected
                  ? TenantAdminColors.posHomeAccentOrange
                  : const Color(0xFFE2E6ED),
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: _avatarBg(customer.displayName),
                    child: Text(
                      customer.initials,
                      style: TextStyle(
                        color: _avatarFg(customer.displayName),
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          customer.shortCustomerId,
                          style: const TextStyle(
                            color: Color(0xFF8E9BAE),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    customer.spentDisplay,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ],
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
