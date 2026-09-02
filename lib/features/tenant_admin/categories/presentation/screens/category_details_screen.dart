import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_buttons.dart';
import '../../../presentation/widgets/tenant_admin_page_scaffold.dart';
import '../../../presentation/widgets/tenant_admin_states.dart';
import '../../../products/presentation/navigation/products_sidebar_routes.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/category_tree_node.dart';
import '../providers/category_providers.dart';
import '../providers/category_visibility_provider.dart';
import '../utils/category_form_utils.dart';
import '../widgets/category_actions.dart';
import '../widgets/category_details_content.dart';

class CategoryDetailsScreen extends ConsumerWidget {
  const CategoryDetailsScreen({super.key, required this.categoryId});

  final String categoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const pageTitle = 'Category Details';
    const pageSubtitle =
        'View category information, hierarchy, status and product usage.';

    final hasViewAccess = ref.watch(categoryDetailPageAccessProvider);
    final canUpdate = ref.watch(categoryUpdateAccessProvider);
    final canDelete = ref.watch(categoryDeleteAccessProvider);
    final categoryAsync = ref.watch(categoryDetailsProvider(categoryId));
    final mutationInProgress =
        ref.watch(categorySaveControllerProvider).isLoading;

    if (!hasViewAccess) {
      return TenantAdminPageScaffold(
        title: pageTitle,
        subtitle: pageSubtitle,
        actions: [
          TenantAdminSecondaryButton(
            label: 'Back to List',
            onPressed: () => context.go(ProductsSidebarRoutes.categories),
            icon: Icons.arrow_back,
          ),
        ],
        child: const TenantAdminEmptyState(
          title: 'No access',
          message: 'You do not have permission to view categories.',
          icon: Icons.category_outlined,
        ),
      );
    }

    return categoryAsync.when(
      loading: () => TenantAdminPageScaffold(
        title: pageTitle,
        subtitle: pageSubtitle,
        actions: [
          TenantAdminSecondaryButton(
            label: 'Back to List',
            onPressed: () => context.go(ProductsSidebarRoutes.categories),
            icon: Icons.arrow_back,
          ),
        ],
        child: const TenantAdminLoadingSkeleton(rowCount: 10),
      ),
      error: (error, stackTrace) => TenantAdminPageScaffold(
        title: pageTitle,
        subtitle: pageSubtitle,
        actions: [
          TenantAdminSecondaryButton(
            label: 'Back to List',
            onPressed: () => context.go(ProductsSidebarRoutes.categories),
            icon: Icons.arrow_back,
          ),
        ],
        child: _CategoryDetailsErrorBody(
          error: error,
          onRetry: () => ref.invalidate(categoryDetailsProvider(categoryId)),
        ),
      ),
      data: (category) {
        final treeAsync = ref.watch(categoryTreeProvider);
        final childCategories = treeAsync.maybeWhen(
          data: (tree) =>
              findCategoryTreeNode(tree, category.id)?.children ??
              const <CategoryTreeNode>[],
          orElse: () => const <CategoryTreeNode>[],
        );

        return TenantAdminPageScaffold(
          title: pageTitle,
          subtitle: pageSubtitle,
          headerSpacing: TenantAdminSpacing.md,
          fillHeight: false,
          padding: const EdgeInsets.fromLTRB(
            TenantAdminSpacing.xl,
            TenantAdminSpacing.lg,
            TenantAdminSpacing.xl,
            TenantAdminSpacing.lg,
          ),
          actions: [
            TenantAdminSecondaryButton(
              label: 'Back to List',
              onPressed: () => context.go(ProductsSidebarRoutes.categories),
              icon: Icons.arrow_back,
            ),
            if (canUpdate) ...[
              const SizedBox(width: TenantAdminSpacing.sm),
              TenantAdminPrimaryButton(
                label: 'Edit Category',
                onPressed: mutationInProgress
                    ? null
                    : () => context.go(
                          ProductsSidebarRoutes.categoryEdit(category.id),
                        ),
                icon: Icons.edit_outlined,
              ),
            ],
            if (canUpdate || canDelete) ...[
              const SizedBox(width: TenantAdminSpacing.sm),
              _CategoryMoreActions(
                category: category,
                canChangeStatus: canUpdate,
                canDelete: canDelete,
                enabled: !mutationInProgress,
              ),
            ],
          ],
          child: CategoryDetailsContent(
            category: category,
            childCategories: childCategories,
            childrenLoading: treeAsync.isLoading,
            onChildCategoryTap: (id) =>
                context.go(ProductsSidebarRoutes.categoryDetail(id)),
          ),
        );
      },
    );
  }
}

class _CategoryDetailsErrorBody extends StatelessWidget {
  const _CategoryDetailsErrorBody({
    required this.error,
    required this.onRetry,
  });

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (isCategoryNotFoundError(error)) {
      return const TenantAdminEmptyState(
        title: 'Category not found',
        message: 'The requested category could not be found.',
        icon: Icons.search_off_outlined,
      );
    }

    if (isCategoryPermissionDeniedError(error)) {
      return const TenantAdminEmptyState(
        title: 'No access',
        message: 'You do not have permission to view this category.',
        icon: Icons.lock_outline,
      );
    }

    return TenantAdminErrorState(
      title: 'Unable to load category',
      message: categoryApiErrorMessage(error),
      onRetry: onRetry,
    );
  }
}

class _CategoryMoreActions extends ConsumerWidget {
  const _CategoryMoreActions({
    required this.category,
    required this.canChangeStatus,
    required this.canDelete,
    required this.enabled,
  });

  final Category category;
  final bool canChangeStatus;
  final bool canDelete;
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      enabled: enabled,
      tooltip: 'More category actions',
      icon: const Icon(Icons.more_vert),
      color: TenantAdminOverlaySurfaces.color,
      surfaceTintColor: TenantAdminOverlaySurfaces.surfaceTint,
      elevation: 8,
      onSelected: (value) async {
        switch (value) {
          case 'status':
            await toggleCategoryStatus(context, ref, category);
          case 'archive':
            await archiveCategory(
              context,
              ref,
              category,
              navigateToListOnSuccess: true,
            );
        }
      },
      itemBuilder: (context) => [
        if (canChangeStatus)
          PopupMenuItem(
            value: 'status',
            child: Text(category.isActive ? 'Inactivate' : 'Activate'),
          ),
        if (canDelete)
          const PopupMenuItem(
            value: 'archive',
            child: Text('Archive'),
          ),
      ],
    );
  }
}
