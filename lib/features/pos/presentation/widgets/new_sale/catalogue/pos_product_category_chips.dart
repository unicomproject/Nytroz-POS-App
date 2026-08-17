import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    if (!PosPermissionAccess.canViewProductsSession(session)) {
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
        final popularSelected = selectedSegment == 'popular' && allSelected;

        return SizedBox(
          height: 56,
          child: Row(
            children: [
              Expanded(
                child: _QuickFilterButton(
                  icon: Icons.star_rounded,
                  label: 'Popular',
                  selected: popularSelected,
                  activeColor: TenantAdminColors.posNewSaleAccent,
                  inactiveColor: TenantAdminColors.posNewSaleAccent,
                  onPressed: () {
                    ref.read(posNewSaleSelectedSegmentProvider.notifier).state =
                        'popular';
                    ref
                        .read(posNewSaleSelectedCategoryIdProvider.notifier)
                        .state = null;
                  },
                ),
              ),
              const SizedBox(width: TenantAdminSpacing.md),
              Expanded(
                child: _QuickFilterButton(
                  icon: Icons.history_rounded,
                  label: 'Frequently Sold',
                  selected: selectedSegment == 'frequently-sold' && allSelected,
                  activeColor: const Color(0xFF2563EB),
                  inactiveColor: const Color(0xFF2563EB),
                  onPressed: () {
                    ref.read(posNewSaleSelectedSegmentProvider.notifier).state =
                        'frequently-sold';
                    ref
                        .read(posNewSaleSelectedCategoryIdProvider.notifier)
                        .state = null;
                  },
                ),
              ),
              const SizedBox(width: TenantAdminSpacing.md),
              Expanded(
                child: _QuickFilterButton(
                  icon: Icons.local_offer_outlined,
                  label: 'Offers',
                  selected: selectedSegment == 'offers' && allSelected,
                  activeColor: const Color(0xFF16A34A),
                  inactiveColor: const Color(0xFF16A34A),
                  onPressed: () {
                    ref.read(posNewSaleSelectedSegmentProvider.notifier).state =
                        'offers';
                    ref
                        .read(posNewSaleSelectedCategoryIdProvider.notifier)
                        .state = null;
                  },
                ),
              ),
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
