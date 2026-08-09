import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import 'parked_sales_formatters.dart';

class ParkedSaleSummaryPanel extends StatelessWidget {
  const ParkedSaleSummaryPanel({
    super.key,
    required this.totalCount,
    required this.totalValue,
    required this.currency,
    required this.canStartSale,
    this.compact = false,
  });

  final int totalCount, totalValue;
  final String currency;
  final bool canStartSale;
  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.fromLTRB(
          0,
          TenantAdminSpacing.xs,
          TenantAdminSpacing.md,
          TenantAdminSpacing.md,
        ),
        padding: const EdgeInsets.all(TenantAdminSpacing.md),
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFA),
          border: Border.all(color: TenantAdminColors.border),
          borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header title area
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF1EBFF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.shopping_cart_outlined,
                      size: 20,
                      color: Color(0xFF7C3AED),
                    ),
                  ),
                  const SizedBox(width: TenantAdminSpacing.sm),
                  const Expanded(
                    child: Text(
                      'Parked Sales Summary',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: TenantAdminSpacing.sm),

              // Card 1: Total Parked Sales
              Container(
                padding: const EdgeInsets.all(TenantAdminSpacing.sm),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F7FF),
                  border: Border.all(color: const Color(0xFFE0F2FE)),
                  borderRadius: BorderRadius.circular(TenantAdminRadius.md),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Color(0xFFBAE6FD),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.shopping_bag_outlined,
                            size: 16,
                            color: Color(0xFF0284C7),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Total Parked Sales',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$totalCount',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const Text(
                      'Sales',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: TenantAdminSpacing.xs),

              // Card 2: Total Parked Value
              Container(
                padding: const EdgeInsets.all(TenantAdminSpacing.sm),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  border: Border.all(color: const Color(0xFFDCFCE7)),
                  borderRadius: BorderRadius.circular(TenantAdminRadius.md),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Color(0xFFBBF7D0),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.payments_outlined,
                            size: 16,
                            color: Color(0xFF16A34A),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Total Parked Value',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatMoney(currency, totalValue),
                      key: const ValueKey('parked-sales-total-value'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF16A34A),
                      ),
                    ),
                    const Text(
                      'Value',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: TenantAdminSpacing.xs),

              // Card 3: Start New Sale section
              Container(
                padding: const EdgeInsets.all(TenantAdminSpacing.sm),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF5EE),
                  border: Border.all(color: const Color(0xFFFFEDD5)),
                  borderRadius: BorderRadius.circular(TenantAdminRadius.md),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF6A00),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.shopping_cart_outlined,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Start a New Sale',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Create a new sale and start adding items.',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: TenantAdminSpacing.xs),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: TenantAdminColors.posHomeAccentOrange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(TenantAdminRadius.sm),
                          ),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text(
                          'Start New Sale',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                        onPressed: canStartSale
                            ? () => context.go('/pos/new-sale')
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}
