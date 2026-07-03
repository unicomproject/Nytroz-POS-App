import 'package:flutter/material.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';
import 'product_section_card.dart';

class ProductTopSellingCard extends StatelessWidget {
  const ProductTopSellingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return ProductSectionCard(
      title: 'Top Selling Products',
      trailing: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: TenantAdminSpacing.md,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: TenantAdminColors.background,
          border: Border.all(color: TenantAdminColors.border),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(
              Icons.calendar_today_outlined,
              size: 14,
              color: TenantAdminColors.mutedText,
            ),
            SizedBox(width: 6),
            Text(
              'This Month',
              style: TextStyle(
                color: TenantAdminColors.mutedText,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: TenantAdminSpacing.lg),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  TenantAdminColors.primary.withValues(alpha: 0.04),
                  TenantAdminColors.info.withValues(alpha: 0.02),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: TenantAdminColors.primary.withValues(alpha: 0.06),
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        TenantAdminColors.primary.withValues(alpha: 0.15),
                        TenantAdminColors.primary.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.insights_outlined,
                    size: 26,
                    color: TenantAdminColors.primary,
                  ),
                ),
                const SizedBox(height: TenantAdminSpacing.lg),
                const Text(
                  'Top selling report is not available yet.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: TenantAdminColors.bodyText,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: TenantAdminSpacing.sm),
                Text(
                  'Sales ranking data will appear here once the top-selling report API is available.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: TenantAdminColors.mutedText,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
