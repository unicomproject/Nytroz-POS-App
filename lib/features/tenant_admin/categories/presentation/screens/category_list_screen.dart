import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_buttons.dart';
import '../../../presentation/widgets/tenant_admin_page_scaffold.dart';
import '../../../presentation/widgets/tenant_admin_pagination.dart';
import '../../../presentation/widgets/tenant_admin_states.dart';
import '../../../products/presentation/navigation/products_sidebar_routes.dart';
import '../providers/category_providers.dart';
import '../providers/category_visibility_provider.dart';
import '../utils/category_form_utils.dart';
import '../widgets/category_filters.dart';
import '../widgets/category_table.dart';

class CategoryListScreen extends ConsumerWidget {
  const CategoryListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visibilityState = ref.watch(categoryListVisibilityProvider);

    return visibilityState.when(
      loading: () => const TenantAdminPageScaffold(
        title: 'Category Management',
        subtitle:
            'Organize and manage product categories using a parent-child hierarchy.',
        child: TenantAdminLoadingSkeleton(rowCount: 5),
      ),
      error: (error, stackTrace) => TenantAdminPageScaffold(
        title: 'Category Management',
        subtitle:
            'Organize and manage product categories using a parent-child hierarchy.',
        child: TenantAdminErrorState(
          title: 'Unable to load categories',
          message: 'Please try again.',
          onRetry: () => ref.invalidate(categoryListVisibilityProvider),
        ),
      ),
      data: (visibility) {
        if (!visibility.showPage) {
          return const TenantAdminPageScaffold(
            title: 'No access to Categories',
            child: TenantAdminEmptyState(
              title: 'No access',
              message: 'You do not have permission to view categories.',
              icon: Icons.category_outlined,
            ),
          );
        }

        return TenantAdminPageScaffold(
          title: visibility.showTitle ? 'Category Management' : '',
          subtitle: visibility.showSubtitle
              ? 'Organize and manage product categories using a parent-child hierarchy.'
              : null,
          headerSpacing: TenantAdminSpacing.sm,
          scrollable: false,
          fillHeight: true,
          actions: [
            if (visibility.showAddCategory)
              TenantAdminPrimaryButton(
                label: 'Add Category',
                icon: Icons.add,
                backgroundColor: TenantAdminColors.posHomeAccentOrange,
                onPressed: () =>
                    context.go(ProductsSidebarRoutes.categoriesAdd),
              ),
          ],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (visibility.showSearch) const CategoryFiltersBar(),
              if (visibility.showSearch) const SizedBox(height: TenantAdminSpacing.lg),
              if (visibility.showList) const Expanded(child: _CategoryListBody()),
            ],
          ),
        );
      },
    );
  }
}

class _CategoryListBody extends ConsumerWidget {
  const _CategoryListBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visibility = ref.watch(categoryListVisibilityProvider).valueOrNull;
    final treeState = ref.watch(categoryTreeProvider);

    if (visibility == null) {
      return const TenantAdminLoadingSkeleton(rowCount: 5);
    }

    return treeState.when(
      loading: () => const TenantAdminLoadingSkeleton(rowCount: 5),
      error: (error, stackTrace) => TenantAdminErrorState(
        title: 'Unable to load categories',
        message: 'Please try again.',
        onRetry: () => ref.invalidate(categoryTreeProvider),
      ),
      data: (tree) {
        final search = ref.watch(categorySearchProvider);
        final statusFilter = ref.watch(categoryStatusFilterProvider);
        final parentFilter = ref.watch(categoryParentFilterProvider);
        final filtered = filterCategoryTree(
          nodes: tree,
          search: search,
          statusFilter: statusFilter,
          parentFilter: parentFilter,
        );

        if (filtered.nodes.isEmpty) {
          return TenantAdminEmptyState(
            title: search.trim().isEmpty
                ? 'No categories yet'
                : 'No search results',
            message: search.trim().isEmpty
                ? 'Add a category to organize your product catalog.'
                : 'No categories match your search or filters.',
            icon: Icons.category_outlined,
          );
        }

        final requestedPage = ref.watch(categoryPageProvider);
        const pageSize = CategoryTable.pageSize;
        final totalCount = filtered.nodes.length;
        final totalPages = (totalCount / pageSize).ceil();
        final page = requestedPage.clamp(1, totalPages);
        if (page != requestedPage) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (ref.read(categoryPageProvider) != page) {
              ref.read(categoryPageProvider.notifier).state = page;
            }
          });
        }

        final pagedNodes = paginateList(
          filtered.nodes,
          page: page,
          pageSize: pageSize,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: TenantAdminColors.surface,
                    borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
                    border: Border.all(color: TenantAdminColors.border),
                    boxShadow: TenantAdminShadows.card,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
                    child: CategoryTable(
                      nodes: pagedNodes,
                      forcedExpandedIds: filtered.expandedIds,
                      canView: visibility.showViewAction,
                      canEdit: visibility.showEditAction,
                      canDelete: visibility.showDeleteAction,
                      canChangeStatus: visibility.showStatusAction,
                    ),
                  ),
                ),
              ),
            ),
            if (totalCount > pageSize)
              TenantAdminPaginationBar(
                currentPage: page,
                pageSize: pageSize,
                totalCount: totalCount,
                itemLabel: 'categories',
                onPageChanged: (nextPage) =>
                    ref.read(categoryPageProvider.notifier).state = nextPage,
              ),
          ],
        );
      },
    );
  }
}
