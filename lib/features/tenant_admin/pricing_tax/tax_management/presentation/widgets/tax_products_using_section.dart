import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../presentation/theme/tenant_admin_theme.dart';
import '../../../../presentation/widgets/tenant_admin_form_section.dart';
import '../../../../presentation/widgets/tenant_admin_pagination.dart';
import '../../../../presentation/widgets/tenant_admin_search_field.dart';
import '../../../../presentation/widgets/tenant_admin_states.dart';
import '../../../../presentation/widgets/tenant_admin_status_badge.dart';
import '../../application/tax_management_controller.dart';
import '../../domain/tax_aggregate.dart';
import '../providers/tax_list_providers.dart';
import '../utils/tax_formatters.dart';

/// Products assigned to a tax setup — embedded in Edit Tax details.
class TaxProductsUsingSection extends ConsumerWidget {
  const TaxProductsUsingSection({
    super.key,
    required this.taxId,
    this.productCount,
  });

  final String taxId;
  final int? productCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(taxProductsProvider(taxId));
    final search = ref.watch(taxProductsSearchProvider(taxId));

    return TenantAdminFormSection(
      title: 'Products Using',
      subtitle: productCount == null
          ? 'Products currently assigned to this tax setup.'
          : '$productCount product${productCount == 1 ? '' : 's'} assigned to this tax setup.',
      children: [
        TenantAdminSearchField(
          hint: 'Search products by name or code...',
          value: search,
          onChanged: (value) {
            ref.read(taxProductsSearchProvider(taxId).notifier).state = value;
            ref.read(taxProductsPageProvider(taxId).notifier).state = 1;
          },
        ),
        productsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          error: (error, _) => TenantAdminErrorState(
            title: 'Unable to load products',
            message: taxApiErrorMessage(error),
            onRetry: () => ref.invalidate(taxProductsProvider(taxId)),
          ),
          data: (result) {
            if (result.items.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  search.trim().isEmpty
                      ? 'No products are currently assigned to this tax setup.'
                      : 'No products match your search.',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: TenantAdminColors.mutedText,
                  ),
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: TenantAdminColors.border),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Column(
                      children: [
                        for (var i = 0; i < result.items.length; i++) ...[
                          if (i > 0)
                            const Divider(
                              height: 1,
                              color: TenantAdminColors.border,
                            ),
                          _ProductRow(item: result.items[i]),
                        ],
                      ],
                    ),
                  ),
                ),
                if (result.totalCount > result.pageSize ||
                    result.pageNumber > 1)
                  TenantAdminPaginationBar(
                    currentPage: result.pageNumber,
                    pageSize: result.pageSize,
                    totalCount: result.totalCount,
                    itemLabel: 'products',
                    onPageChanged: (page) => ref
                        .read(taxProductsPageProvider(taxId).notifier)
                        .state = page,
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({required this.item});

  final TaxProductUsing item;

  @override
  Widget build(BuildContext context) {
    final isActive = item.status.toUpperCase() == 'ACTIVE';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.productCode,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: TenantAdminColors.mutedText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            item.taxPriceMode.label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: TenantAdminColors.mutedText,
            ),
          ),
          const SizedBox(width: 10),
          TenantAdminStatusBadge(
            label: taxProductStatusLabel(item.status),
            status: isActive
                ? TenantAdminStatusType.active
                : TenantAdminStatusType.inactive,
          ),
        ],
      ),
    );
  }
}
