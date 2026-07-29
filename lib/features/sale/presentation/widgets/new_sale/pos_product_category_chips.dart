import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nytroz_pos/core/access/pos_permission_access.dart';
import 'package:nytroz_pos/features/auth/presentation/providers/session_provider.dart';
import 'package:nytroz_pos/features/cart/domain/entities/pos_catalog_models.dart';
import 'package:nytroz_pos/features/cart/presentation/providers/pos_catalog_provider.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

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

    return categoriesAsync.when(
      loading: () => const SizedBox(
        height: 34,
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (categories) {
        final allSelected = selectedCategoryId == null;
        return SizedBox(
          height: 48,
          child: Row(
            children: [
              Expanded(
                child: _QuickFilterButton(
                  icon: Icons.star_rounded,
                  label: 'Popular',
                  selected: allSelected,
                  onPressed: () => ref
                      .read(posNewSaleSelectedCategoryIdProvider.notifier)
                      .state = null,
                ),
              ),
              const SizedBox(width: TenantAdminSpacing.sm),
              const Expanded(
                child: _QuickFilterButton(
                  icon: Icons.history_rounded,
                  label: 'Frequently Sold',
                  tooltip:
                      'Frequently sold ranking is not available from the catalog API yet.',
                ),
              ),
              const SizedBox(width: TenantAdminSpacing.sm),
              const Expanded(
                child: _QuickFilterButton(
                  icon: Icons.local_offer_outlined,
                  label: 'Offers',
                  tooltip:
                      'Offer-based product filtering is not available from the catalog API yet.',
                ),
              ),
              const SizedBox(width: TenantAdminSpacing.sm),
              Expanded(
                child: _QuickFilterButton(
                  icon: Icons.grid_view_rounded,
                  label: 'More Categories',
                  selected: !allSelected,
                  onPressed: categories.length > 1
                      ? () => _showCategories(context, ref, categories)
                      : null,
                ),
              ),
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
    this.selected = false,
    this.onPressed,
    this.tooltip,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Tooltip(
      message: tooltip ?? label,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 21),
        label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        style: OutlinedButton.styleFrom(
          backgroundColor:
              selected ? TenantAdminColors.posNewSaleAccent : Colors.white,
          foregroundColor: selected
              ? Colors.white
              : enabled
                  ? TenantAdminColors.primary
                  : TenantAdminColors.mutedText,
          disabledForegroundColor: TenantAdminColors.mutedText,
          side: BorderSide(
            color: selected
                ? TenantAdminColors.posNewSaleAccent
                : TenantAdminColors.border,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TenantAdminRadius.md),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}
