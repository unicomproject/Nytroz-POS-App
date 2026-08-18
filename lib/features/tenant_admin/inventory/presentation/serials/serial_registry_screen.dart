import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../presentation/widgets/tenant_admin_page_scaffold.dart';
import '../../../presentation/widgets/tenant_admin_pagination.dart';
import '../../../presentation/widgets/tenant_admin_states.dart';
import '../../data/mock/inventory_frontend_mock.dart';
import '../widgets/inventory_shared_widgets.dart';

final serialSearchProvider = StateProvider<String>((ref) => '');
final serialPageProvider = StateProvider<int>((ref) => 1);
final serialDraftProvider = StateProvider<String>((ref) => '');
final serialMessageProvider = StateProvider<String?>((ref) => null);

class SerialRegistryScreen extends ConsumerWidget {
  const SerialRegistryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final search = ref.watch(serialSearchProvider);
    final page = ref.watch(serialPageProvider);
    final draft = ref.watch(serialDraftProvider);
    final message = ref.watch(serialMessageProvider);
    final filtered = InventoryFrontendMock.serials
        .where((s) =>
            search.isEmpty ||
            s.serial.toLowerCase().contains(search.toLowerCase()) ||
            s.sku.toLowerCase().contains(search.toLowerCase()))
        .toList();
    const pageSize = TenantAdminPaginationDefaults.pageSize;
    final start = ((page - 1) * pageSize).clamp(0, filtered.length);
    final end = (start + pageSize).clamp(0, filtered.length);
    final inStock = InventoryFrontendMock.serials
        .where((s) => s.status == 'IN_STOCK')
        .length;
    final reserved = InventoryFrontendMock.serials
        .where((s) => s.status == 'RESERVED')
        .length;

    return TenantAdminPageScaffold(
      title: 'Serial Number Registry',
      subtitle:
          'One serial equals one unit. Gap-fill does not increase on-hand.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InventoryMetricStrip(
            cards: [
              InventoryStatCard(
                label: 'Total Serials',
                value: '${InventoryFrontendMock.serials.length}',
                subtitle: 'Across all outlets',
                icon: Icons.pin_outlined,
                iconColor: InventoryWorkspaceTokens.iconBlue,
              ),
              InventoryStatCard(
                label: 'In Stock',
                value: '$inStock',
                subtitle: 'Available units',
                icon: Icons.check_circle_outline,
                iconColor: InventoryWorkspaceTokens.iconGreen,
              ),
              InventoryStatCard(
                label: 'Reserved',
                value: '$reserved',
                subtitle: 'Held for orders',
                icon: Icons.hourglass_top_outlined,
                iconColor: InventoryWorkspaceTokens.iconOrange,
              ),
              const InventoryStatCard(
                label: 'Sold',
                value: '0',
                subtitle: 'Visual only in this phase',
                icon: Icons.shopping_bag_outlined,
                iconColor: InventoryWorkspaceTokens.iconPurple,
              ),
            ],
          ),
          const SizedBox(height: 16),
          InventorySearchField(
            value: search,
            hint: 'Search serial number, product, or SKU...',
            onChanged: (v) {
              ref.read(serialSearchProvider.notifier).state = v;
              ref.read(serialPageProvider.notifier).state = 1;
            },
          ),
          const SizedBox(height: 16),
          InventorySectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Register serials (gap-fill)',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                TextField(
                  onChanged: (v) =>
                      ref.read(serialDraftProvider.notifier).state = v,
                  decoration: inventoryInputDecoration(
                    hint: 'Enter a serial to validate',
                  ),
                ),
                const SizedBox(height: 8),
                InventoryPrimaryButton(
                  label: 'Validate Serial',
                  onPressed: () {
                    final value = draft.trim();
                    if (value.isEmpty) {
                      ref.read(serialMessageProvider.notifier).state =
                          'Serial is required.';
                      return;
                    }
                    final exists = InventoryFrontendMock.serials.any(
                        (s) => s.serial.toLowerCase() == value.toLowerCase());
                    ref.read(serialMessageProvider.notifier).state = exists
                        ? 'Duplicate serial: $value already exists for this product.'
                        : 'Serial $value is available to register. On-hand is unchanged.';
                  },
                ),
                if (message != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(message),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (filtered.isEmpty)
            const TenantAdminEmptyState(
              title: 'No serials found',
              message: 'Try another serial, SKU, or location filter.',
            )
          else
            InventorySectionCard(
              padding: EdgeInsets.zero,
              child: InventoryWorkspaceTable(
                headers: const [
                  'Serial Number',
                  'Product',
                  'Outlet',
                  'Stock Status',
                  'Actions',
                ],
                rows: [
                  for (final s in filtered.sublist(start, end))
                    [
                      Text(s.serial,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text(s.productName,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(s.locationName),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: InventoryStatusBadge(
                          label:
                              s.status == 'RESERVED' ? 'Reserved' : 'In Stock',
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Mark as Sold is not available in this phase (SERIAL_MARK_AS_SOLD_DEFERRED).',
                              ),
                            ),
                          );
                        },
                        child: const Text('Mark as Sold'),
                      ),
                    ],
                ],
              ),
            ),
          TenantAdminPaginationBar(
            currentPage: page,
            pageSize: pageSize,
            totalCount: filtered.length,
            onPageChanged: (p) =>
                ref.read(serialPageProvider.notifier).state = p,
          ),
        ],
      ),
    );
  }
}
