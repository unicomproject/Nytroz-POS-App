import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../domain/entities/product_delete_result.dart';
import '../dashboard/product_dashboard_providers.dart';
import '../providers/tenant_product_providers.dart';
import '../utils/product_api_errors.dart';

class ProductDeleteAction extends ConsumerWidget {
  const ProductDeleteAction({
    super.key,
    required this.productId,
    required this.productName,
    this.navigateToListOnSuccess = false,
    this.compact = true,
  });

  final String productId;
  final String productName;
  final bool navigateToListOnSuccess;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deletingIds = ref.watch(productDeletingIdsProvider);
    final isDeleting = deletingIds.contains(productId);

    return IconButton(
      tooltip: isDeleting ? 'Deleting product...' : 'Delete product',
      onPressed: isDeleting ? null : () => _confirmAndDelete(context, ref),
      icon: isDeleting
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(
              Icons.delete_outline,
              size: compact ? 18 : 20,
              color: TenantAdminColors.danger,
            ),
      visualDensity: VisualDensity.compact,
      style: IconButton.styleFrom(
        foregroundColor: TenantAdminColors.danger,
      ),
    );
  }

  Future<void> _confirmAndDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete product'),
          content: const Text('Are you sure you want to delete this product?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: TenantAdminColors.danger,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    ref.read(productDeletingIdsProvider.notifier).update(
          (ids) => {...ids, productId},
        );

    try {
      final result = await ref.read(deleteProductProvider).call(productId);

      ref
        ..invalidate(productListProvider)
        ..invalidate(productSummaryProvider)
        ..invalidate(productDetailProvider(productId))
        ..invalidate(productDashboardProvider);

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_successMessage(result, productName))),
      );

      if (navigateToListOnSuccess) {
        context.go('/tenant-admin/products');
      }
    } on DioException catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            productDeleteErrorMessage(
              error,
              fallback: 'Failed to delete product. Please try again.',
            ),
          ),
          backgroundColor: TenantAdminColors.danger,
        ),
      );
    } catch (_) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to delete product. Please try again.'),
          backgroundColor: TenantAdminColors.danger,
        ),
      );
    } finally {
      ref.read(productDeletingIdsProvider.notifier).update(
            (ids) => ids.where((id) => id != productId).toSet(),
          );
    }
  }

  String _successMessage(ProductDeleteResult result, String productName) {
    final name = productName.trim().isEmpty ? 'Product' : productName;
    if (result.wasArchived) {
      return '$name was archived because it has sales or stock history.';
    }

    return '$name deleted successfully.';
  }
}
