import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/services/tenant_admin_access_checker.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_buttons.dart';
import '../../../presentation/widgets/tenant_admin_page_scaffold.dart';
import '../../../presentation/widgets/tenant_admin_search_field.dart';
import '../../../presentation/widgets/tenant_admin_states.dart';
import '../providers/brand_providers.dart';
import '../providers/brand_visibility_provider.dart';
import '../widgets/brand_form_dialog.dart';
import '../widgets/brand_table.dart';

class BrandListScreen extends ConsumerWidget {
  const BrandListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visibilityState = ref.watch(brandListVisibilityProvider);

    return visibilityState.when(
      loading: () => const TenantAdminPageScaffold(
        title: 'Brands',
        subtitle: 'Manage product brands for your catalog.',
        child: TenantAdminLoadingSkeleton(rowCount: 6),
      ),
      error: (error, stackTrace) => TenantAdminPageScaffold(
        title: 'Brands',
        subtitle: 'Manage product brands for your catalog.',
        child: TenantAdminErrorState(
          title: 'Unable to load brands',
          message: 'Please try again.',
          onRetry: () => ref.invalidate(brandListVisibilityProvider),
        ),
      ),
      data: (visibility) {
        if (!visibility.showPage) {
          return const TenantAdminPageScaffold(
            title: 'No access to Brands',
            child: TenantAdminEmptyState(
              title: 'No access',
              message: 'You do not have permission to view brands.',
              icon: Icons.sell_outlined,
            ),
          );
        }

        return TenantAdminPageScaffold(
          title: visibility.showTitle ? 'Brands' : '',
          subtitle: visibility.showSubtitle
              ? 'Manage product brands for your catalog.'
              : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BrandToolbar(visibility: visibility),
              if (visibility.showSearch || visibility.showAddBrand)
                const SizedBox(height: TenantAdminSpacing.lg),
              if (visibility.showList) const _BrandListBody(),
            ],
          ),
        );
      },
    );
  }
}

class _BrandToolbar extends ConsumerWidget {
  const _BrandToolbar({required this.visibility});

  final BrandListVisibility visibility;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;

        if (isMobile) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (visibility.showSearch)
                TenantAdminSearchField(
                  hint: 'Search brands',
                  onChanged: (value) =>
                      ref.read(brandSearchProvider.notifier).state = value,
                ),
              if (visibility.showSearch && visibility.showAddBrand)
                const SizedBox(height: TenantAdminSpacing.md),
              if (visibility.showAddBrand)
                TenantAdminPrimaryButton(
                  label: 'Add brand',
                  icon: Icons.add,
                  onPressed: () => _addBrand(context, ref),
                ),
            ],
          );
        }

        return Row(
          children: [
            if (visibility.showSearch)
              Expanded(
                child: TenantAdminSearchField(
                  hint: 'Search brands',
                  onChanged: (value) =>
                      ref.read(brandSearchProvider.notifier).state = value,
                ),
              ),
            if (visibility.showSearch && visibility.showAddBrand)
              const SizedBox(width: TenantAdminSpacing.lg),
            if (visibility.showAddBrand)
              TenantAdminPrimaryButton(
                label: 'Add brand',
                icon: Icons.add,
                onPressed: () => _addBrand(context, ref),
              ),
          ],
        );
      },
    );
  }

  Future<void> _addBrand(BuildContext context, WidgetRef ref) async {
    final input = await showBrandFormDialog(context: context);
    if (input == null || !context.mounted) {
      return;
    }

    try {
      await ref.read(brandSaveControllerProvider.notifier).save(input: input);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Brand created successfully.')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(brandApiErrorMessage(error))),
        );
      }
    }
  }
}

class _BrandListBody extends ConsumerWidget {
  const _BrandListBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visibility = ref.watch(brandListVisibilityProvider).valueOrNull;
    final brandsState = ref.watch(brandListScreenProvider);

    if (visibility == null) {
      return const TenantAdminLoadingSkeleton(rowCount: 6);
    }

    return brandsState.when(
      loading: () => const TenantAdminLoadingSkeleton(rowCount: 6),
      error: (error, stackTrace) => TenantAdminErrorState(
        title: 'Unable to load brands',
        message: 'Please try again.',
        onRetry: () => ref.refresh(brandListScreenProvider),
      ),
      data: (result) {
        if (result == null) {
          return const TenantAdminEmptyState(
            title: 'No access',
            message: 'You do not have permission to view brands.',
            icon: Icons.sell_outlined,
          );
        }

        return BrandTable(
          brands: result.items,
          canEdit: visibility.showEditBrand,
          canDelete: visibility.showDeleteBrand,
        );
      },
    );
  }
}
