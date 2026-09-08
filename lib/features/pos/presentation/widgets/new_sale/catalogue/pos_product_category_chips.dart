import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nytroz_pos/core/access/permission_access_providers.dart';
import 'package:nytroz_pos/core/access/pos_access_codes.dart';
import 'package:nytroz_pos/core/access/pos_permission_access.dart';
import 'package:nytroz_pos/features/auth/presentation/providers/session_provider.dart';
import 'package:nytroz_pos/features/pos/domain/entities/pos_catalog_models.dart';
import 'package:nytroz_pos/features/pos/presentation/providers/pos_catalog_provider.dart';

import '../../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

const bool _showMoreCategoriesAction = false;

class PosProductCategoryChips extends ConsumerWidget {
  const PosProductCategoryChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider);
    final permissions = ref.watch(effectivePermissionSetProvider);
    if (!PosPermissionAccess.canViewProductsSession(session)) {
      return const SizedBox.shrink();
    }
    if (!permissions
        .hasPermission(PosPermissionCodes.catalogSectionsQuickProducts)) {
      return const SizedBox.shrink();
    }

    final categoriesAsync = ref.watch(posNewSaleCategoriesProvider);
    final selectedCategoryId = ref.watch(posNewSaleSelectedCategoryIdProvider);
    final selectedSegment = ref.watch(posNewSaleSelectedSegmentProvider);

    return categoriesAsync.when(
      loading: () => const SizedBox(
        height: 56,
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (categories) {
        final allSelected = selectedCategoryId == null;
        final tabs = <({
          String segment,
          String label,
          IconData icon,
          Color color,
          String permission,
        })>[
          if (permissions
              .hasPermission(PosPermissionCodes.catalogSectionsPopular))
            (
              segment: 'popular',
              label: 'Popular',
              icon: Icons.star_rounded,
              color: TenantAdminColors.posNewSaleAccent,
              permission: PosPermissionCodes.catalogSectionsPopular,
            ),
          if (permissions.hasPermission(
              PosPermissionCodes.catalogSectionsFrequentlySold))
            (
              segment: 'frequently-sold',
              label: 'Frequently Sold',
              icon: Icons.history_rounded,
              color: const Color(0xFF2563EB),
              permission: PosPermissionCodes.catalogSectionsFrequentlySold,
            ),
          if (permissions
              .hasPermission(PosPermissionCodes.catalogSectionsOffers))
            (
              segment: 'offers',
              label: 'Offers',
              icon: Icons.local_offer_outlined,
              color: const Color(0xFF16A34A),
              permission: PosPermissionCodes.catalogSectionsOffers,
            ),
        ];

        if (tabs.isEmpty) {
          return const SizedBox.shrink();
        }

        // If selected segment was revoked, fall back to first permitted tab.
        final selectedStillValid =
            tabs.any((t) => t.segment == selectedSegment);
        if (!selectedStillValid && allSelected) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(posNewSaleSelectedSegmentProvider.notifier).state =
                tabs.first.segment;
          });
        }

        return SizedBox(
          height: 56,
          child: Row(
            children: [
              for (var i = 0; i < tabs.length; i++) ...[
                if (i > 0) const SizedBox(width: TenantAdminSpacing.md),
                Expanded(
                  child: _QuickFilterButton(
                    icon: tabs[i].icon,
                    label: tabs[i].label,
                    selected: selectedSegment == tabs[i].segment && allSelected,
                    activeColor: tabs[i].color,
                    inactiveColor: tabs[i].color,
                    onPressed: () {
                      ref
                          .read(posNewSaleSelectedSegmentProvider.notifier)
                          .state = tabs[i].segment;
                      ref
                          .read(posNewSaleSelectedCategoryIdProvider.notifier)
                          .state = null;
                    },
                  ),
                ),
              ],
              if (_showMoreCategoriesAction) ...[
                const SizedBox(width: TenantAdminSpacing.md),
                Expanded(
                  child: _QuickFilterButton(
                    icon: Icons.grid_view_rounded,
                    label: 'More Categories',
                    selected: !allSelected,
                    activeColor: const Color(0xFF7C3AED),
                    inactiveColor: const Color(0xFF7C3AED),
                    onPressed: categories.length > 1
                        ? () => _showCategories(context, ref, categories)
                        : null,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _showCategories(
    BuildContext context,
    WidgetRef ref,
    List<PosCatalogCategoryOption> categories,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(TenantAdminSpacing.lg),
          child: Wrap(
            spacing: TenantAdminSpacing.sm,
            runSpacing: TenantAdminSpacing.sm,
            children: [
              ChoiceChip(
                label: const Text('All'),
                selected:
                    ref.read(posNewSaleSelectedCategoryIdProvider) == null,
                onSelected: (_) {
                  ref
                      .read(posNewSaleSelectedCategoryIdProvider.notifier)
                      .state = null;
                  Navigator.of(sheetContext).pop();
                },
              ),
              for (final category in categories)
                ChoiceChip(
                  label: Text(category.name),
                  selected: ref.read(posNewSaleSelectedCategoryIdProvider) ==
                      category.id,
                  onSelected: (_) {
                    ref
                        .read(posNewSaleSelectedCategoryIdProvider.notifier)
                        .state = category.id;
                    Navigator.of(sheetContext).pop();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickFilterButton extends StatelessWidget {
  const _QuickFilterButton({
    required this.icon,
    required this.label,
    required this.activeColor,
    required this.inactiveColor,
    this.selected = false,
    this.onPressed,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 24),
        label: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: selected ? activeColor : Colors.white,
          foregroundColor: selected ? Colors.white : inactiveColor,
          disabledForegroundColor: inactiveColor,
          side: BorderSide(
            color:
                selected ? activeColor : inactiveColor.withValues(alpha: 0.2),
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TenantAdminRadius.md),
          ),
          padding:
              const EdgeInsets.symmetric(horizontal: TenantAdminSpacing.sm),
        ),
      ),
    );
  }
}
