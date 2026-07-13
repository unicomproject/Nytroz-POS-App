import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../presentation/widgets/tenant_admin_page_scaffold.dart';
import '../../../presentation/widgets/tenant_admin_states.dart';
import '../providers/tenant_product_providers.dart';
import '../providers/tenant_product_visibility_provider.dart';
import '../widgets/product_delete_action.dart';
import '../widgets/product_detail_form.dart';
import '../widgets/product_status_action_menu.dart';

class ProductDetailScreen extends ConsumerWidget {
  const ProductDetailScreen({
    super.key,
    required this.productId,
    this.isEditRoute = false,
  });

  final String productId;
  final bool isEditRoute;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasViewAccess = ref.watch(productDetailPageAccessProvider);
    final canUpdate = ref.watch(productUpdateAccessProvider);
    final canDelete = ref.watch(productDeleteAccessProvider);
    final detailState = ref.watch(productDetailProvider(productId));
    final optionsState = canUpdate
        ? ref.watch(productEditCreateOptionsProvider)
        : const AsyncData(null);

    final pageTitle = isEditRoute ? 'Edit product' : 'Product details';
    final pageSubtitle = isEditRoute
        ? 'Review and update this product.'
        : 'View product information.';

    if (!hasViewAccess) {
      return TenantAdminPageScaffold(
        title: pageTitle,
        subtitle: pageSubtitle,
        child: const TenantAdminEmptyState(
          title: 'No access',
          message: 'You do not have permission to view products.',
          icon: Icons.inventory_2_outlined,
        ),
      );
    }

    if (isEditRoute && !canUpdate) {
      return TenantAdminPageScaffold(
        title: pageTitle,
        subtitle: pageSubtitle,
        child: const TenantAdminEmptyState(
          title: 'No access',
          message: 'You do not have permission to edit products.',
          icon: Icons.inventory_2_outlined,
        ),
      );
    }

    return detailState.when(
      loading: () => TenantAdminPageScaffold(
        title: pageTitle,
        subtitle: pageSubtitle,
        child: const TenantAdminLoadingSkeleton(rowCount: 10),
      ),
      error: (error, stackTrace) => TenantAdminPageScaffold(
        title: pageTitle,
        subtitle: pageSubtitle,
        actions: [
          TextButton.icon(
            onPressed: () => context.go('/tenant-admin/products'),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back to products'),
          ),
        ],
        child: TenantAdminErrorState(
          title: _errorTitle(error),
          message: _errorMessage(error),
          onRetry: () => ref.invalidate(productDetailProvider(productId)),
        ),
      ),
      data: (detail) {
        if (detail == null) {
          return TenantAdminPageScaffold(
            title: pageTitle,
            subtitle: pageSubtitle,
            child: const TenantAdminEmptyState(
              title: 'No access',
              message: 'You do not have permission to view products.',
              icon: Icons.inventory_2_outlined,
            ),
          );
        }

        final fieldsEnabled = canUpdate && isEditRoute;
        final canSave = canUpdate && isEditRoute;
        final resolvedTitle =
            detail.productName.trim().isEmpty ? pageTitle : detail.productName;

        if (fieldsEnabled) {
          return optionsState.when(
            loading: () => TenantAdminPageScaffold(
              title: resolvedTitle,
              subtitle: pageSubtitle,
              child: const TenantAdminLoadingSkeleton(rowCount: 10),
            ),
            error: (error, stackTrace) => TenantAdminPageScaffold(
              title: resolvedTitle,
              subtitle: pageSubtitle,
              actions: [
                TextButton.icon(
                  onPressed: () => context.go('/tenant-admin/products'),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back to products'),
                ),
              ],
              child: TenantAdminErrorState(
                title: 'Unable to load form options',
                message: 'Please try again.',
                onRetry: () => ref.invalidate(productEditCreateOptionsProvider),
              ),
            ),
            data: (options) => TenantAdminPageScaffold(
              title: resolvedTitle,
              subtitle: pageSubtitle,
              actions: [
                if (canDelete)
                  ProductDeleteAction(
                    productId: productId,
                    productName: detail.productName,
                    navigateToListOnSuccess: true,
                    compact: false,
                  ),
                if (canSave)
                  ProductStatusActionMenu(
                    productId: productId,
                    productName: detail.productName,
                    currentStatus: detail.status,
                    compact: false,
                  ),
                TextButton.icon(
                  onPressed: () => context.go('/tenant-admin/products'),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back to products'),
                ),
              ],
              child: ProductDetailForm(
                productId: productId,
                detail: detail,
                fieldsEnabled: fieldsEnabled,
                canSave: canSave,
                options: options,
              ),
            ),
          );
        }

        return TenantAdminPageScaffold(
          title: resolvedTitle,
          subtitle: pageSubtitle,
          actions: [
            if (canDelete)
              ProductDeleteAction(
                productId: productId,
                productName: detail.productName,
                navigateToListOnSuccess: true,
                compact: false,
              ),
            if (canUpdate)
              ProductStatusActionMenu(
                productId: productId,
                productName: detail.productName,
                currentStatus: detail.status,
                compact: false,
              ),
            TextButton.icon(
              onPressed: () => context.go('/tenant-admin/products'),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back to products'),
            ),
          ],
          child: ProductDetailForm(
            productId: productId,
            detail: detail,
            fieldsEnabled: false,
            canSave: false,
          ),
        );
      },
    );
  }

  String _errorTitle(Object error) {
    if (error is DioException && error.response?.statusCode == 404) {
      return 'Product not found';
    }

    return 'Unable to load product';
  }

  String _errorMessage(Object error) {
    if (error is DioException && error.response?.statusCode == 404) {
      return 'This product could not be found or may have been removed.';
    }

    return 'Please try again.';
  }
}
