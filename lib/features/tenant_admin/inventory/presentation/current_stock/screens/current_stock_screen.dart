import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:js_interop';
import 'dart:convert';
import 'package:web/web.dart' as web;
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';

import '../../../../../../core/network/dio_provider.dart';
import '../../../../presentation/theme/tenant_admin_theme.dart';
import '../../../../presentation/widgets/tenant_admin_page_scaffold.dart';
import '../../../../presentation/widgets/tenant_admin_states.dart';
import '../../../../presentation/widgets/tenant_admin_buttons.dart';
import '../../../../presentation/providers/tenant_admin_access_provider.dart';
import '../../../../../../core/access/tenant_admin_access_codes.dart';
import '../providers/current_stock_providers.dart';
import '../widgets/current_stock_summary_cards.dart';
import '../widgets/current_stock_table.dart';

class CurrentStockScreen extends ConsumerWidget {
  const CurrentStockScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessCheckerState = ref.watch(tenantAdminAccessCheckerProvider);
    final accessChecker = accessCheckerState.valueOrNull;

    if (accessChecker == null || !accessChecker.can(TenantAdminPermissionCodes.tenantStockView)) {
      return const TenantAdminPageScaffold(
        title: 'Current Stock',
        child: TenantAdminEmptyState(
          title: 'No access to Current Stock',
          message: 'You do not have permission to view current stock.',
          icon: Icons.lock_outline,
        ),
      );
    }

    final summaryState = ref.watch(currentStockSummaryProvider);
    final stockListState = ref.watch(currentStockListProvider);
    final outletsState = ref.watch(inventoryOutletsProvider);

    return TenantAdminPageScaffold(
      title: 'Current Stock',
      subtitle: 'Search or scan products to view stock.',
      showBackButton: true,
      onBackButtonPressed: () {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          context.go('/tenant-admin/stock/dashboard');
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search & Actions Row
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 800;
              
              final searchField = TextField(
                onChanged: (val) {
                  ref.read(currentStockSearchProvider.notifier).state = val;
                  ref.read(currentStockPageProvider.notifier).state = 1;
                },
                decoration: InputDecoration(
                  hintText: 'Search by product name, SKU or scan barcode',
                  hintStyle: (Theme.of(context).textTheme.bodySmall ?? const TextStyle()).copyWith(color: TenantAdminColors.mutedText),
                  prefixIcon: const Icon(Icons.search, size: 20, color: TenantAdminColors.mutedText),
                  suffixIcon: const Icon(Icons.qr_code_scanner, size: 20, color: TenantAdminColors.mutedText),
                  contentPadding: const EdgeInsets.symmetric(horizontal: TenantAdminSpacing.md, vertical: TenantAdminSpacing.sm),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(TenantAdminSpacing.sm),
                    borderSide: const BorderSide(color: TenantAdminColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(TenantAdminSpacing.sm),
                    borderSide: const BorderSide(color: TenantAdminColors.border),
                  ),
                  filled: true,
                  fillColor: TenantAdminColors.surface,
                ),
              );

              final actionButtons = Wrap(
                spacing: TenantAdminSpacing.md,
                runSpacing: TenantAdminSpacing.md,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: TenantAdminSpacing.md),
                    decoration: BoxDecoration(
                      color: TenantAdminColors.surface,
                      border: Border.all(color: TenantAdminColors.border),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: outletsState.when(
                      data: (outlets) {
                        if (outlets.length == 1) {
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.location_on_outlined, size: 18, color: Color(0xFF3B82F6)),
                              const SizedBox(width: TenantAdminSpacing.sm),
                              Text(outlets.first.name, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF3B82F6))),
                            ],
                          );
                        }

                        final selectedId = ref.watch(currentStockOutletFilterProvider);
                        return DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedId,
                            hint: Row(
                              children: [
                                const Icon(Icons.location_on_outlined, size: 18, color: Color(0xFF3B82F6)),
                                const SizedBox(width: TenantAdminSpacing.sm),
                                Text(
                                  'All Outlets',
                                  style: (Theme.of(context).textTheme.labelMedium ?? const TextStyle()).copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF3B82F6),
                                  ),
                                ),
                              ],
                            ),
                            icon: const Padding(
                              padding: EdgeInsets.only(left: TenantAdminSpacing.sm),
                              child: Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF1E293B)),
                            ),
                            isDense: true,
                            onChanged: (val) {
                              ref.read(currentStockOutletFilterProvider.notifier).state = val;
                              ref.read(currentStockPageProvider.notifier).state = 1;
                            },
                            items: [
                              const DropdownMenuItem<String>(
                                value: null,
                                child: Row(
                                  children: [
                                    Icon(Icons.location_on_outlined, size: 18, color: Color(0xFF3B82F6)),
                                    SizedBox(width: TenantAdminSpacing.sm),
                                    Text('All Outlets', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF3B82F6))),
                                  ],
                                ),
                              ),
                              ...outlets.map((o) => DropdownMenuItem(
                                    value: o.id,
                                    child: Row(
                                      children: [
                                        const Icon(Icons.location_on_outlined, size: 18, color: Color(0xFF3B82F6)),
                                        const SizedBox(width: TenantAdminSpacing.sm),
                                        Text(o.name, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF3B82F6))),
                                      ],
                                    ),
                                  )),
                            ],
                          ),
                        );
                      },
                      loading: () => const Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))),
                      error: (_, __) => const Text('Error', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final dio = ref.read(appDioProvider);
                      final selectedOutletId = ref.read(currentStockOutletFilterProvider);
                      final search = ref.read(currentStockSearchProvider);
                      final status = ref.read(currentStockStatusFilterProvider);
                      
                      try {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Exporting current stock...')));
                        
                        final response = await dio.get(
                          '/api/v1/tenant-admin/inventory/current-stock/export',
                          queryParameters: {
                            if (selectedOutletId != null) 'outletId': selectedOutletId,
                            if (search.trim().isNotEmpty) 'search': search.trim(),
                            if (status != null) 'stockStatus': status,
                          },
                          options: Options(responseType: ResponseType.plain),
                        );
                        
                        final csvString = response.data.toString();
                        final bytes = utf8.encode(csvString);
                        final blob = web.Blob([bytes.toJS].toJS, web.BlobPropertyBag(type: 'text/csv'));
                        final url = web.URL.createObjectURL(blob);
                        final anchor = web.HTMLAnchorElement()
                          ..href = url
                          ..download = 'current_stock.csv';
                        web.document.body!.append(anchor);
                        anchor.click();
                        anchor.remove();
                        web.URL.revokeObjectURL(url);
                        
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Export successful!')));
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
                      }
                    },
                    icon: const Icon(Icons.upload, size: 18, color: TenantAdminColors.bodyText),
                    label: Text('Export', style: (Theme.of(context).textTheme.labelSmall ?? const TextStyle()).copyWith(fontWeight: FontWeight.bold, color: TenantAdminColors.bodyText)),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: TenantAdminColors.surface,
                      padding: const EdgeInsets.symmetric(horizontal: TenantAdminSpacing.lg),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TenantAdminSpacing.sm)),
                      side: const BorderSide(color: TenantAdminColors.border),
                      minimumSize: const Size(120, 48),
                    ),
                  ),
                  if (accessChecker.can(TenantAdminPermissionCodes.tenantStockIn)) ...[
                    TenantAdminPrimaryButton(
                      label: 'Stock In',
                      icon: Icons.add,
                      onPressed: () {},
                    ),
                  ],
                ],
              );

              if (isCompact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    searchField,
                    const SizedBox(height: TenantAdminSpacing.md),
                    actionButtons,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(flex: 3, child: searchField),
                  const Spacer(flex: 1),
                  actionButtons,
                ],
              );
            },
          ),

          const SizedBox(height: TenantAdminSpacing.lg),

          // Summary Metric Cards
          summaryState.when(
            data: (summary) => CurrentStockSummaryCards(summary: summary),
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(TenantAdminSpacing.lg),
                child: TenantAdminLoadingSkeleton(rowCount: 2),
              ),
            ),
            error: (error, stack) => TenantAdminErrorState(
              onRetry: () => ref.refresh(currentStockSummaryProvider),
              title: 'Error loading stock summary',
              message: error.toString(),
            ),
          ),

          const SizedBox(height: TenantAdminSpacing.lg),

          // Main Current Stock Table
          stockListState.when(
            data: (stockPage) => CurrentStockTable(stockPage: stockPage),
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(TenantAdminSpacing.xxl),
                child: TenantAdminLoadingSkeleton(rowCount: 8),
              ),
            ),
            error: (error, stack) => TenantAdminErrorState(
              onRetry: () => ref.refresh(currentStockListProvider),
              title: 'Error loading stock list',
              message: error.toString(),
            ),
          ),

          const SizedBox(height: 24.0),
        ],
      ),
    );
  }
}

