import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';
import '../providers/tenant_product_providers.dart';
import 'product_summary_cards.dart';

class ProductSummarySection extends ConsumerWidget {
  const ProductSummarySection({super.key, required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryState = ref.watch(productSummaryProvider);

    return summaryState.when(
      loading: () => ProductSummaryCardsSkeleton(compact: compact),
      error: (error, stackTrace) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(TenantAdminSpacing.xl),
        decoration: BoxDecoration(
          color: TenantAdminColors.surface,
          borderRadius: BorderRadius.circular(TenantAdminRadius.md),
          border: Border.all(color: TenantAdminColors.border),
        ),
      ),
      data: (summary) {
        if (summary == null) {
          return const SizedBox.shrink();
        }

        return ProductSummaryCards(summary: summary, compact: compact);
      },
    );
  }
}
