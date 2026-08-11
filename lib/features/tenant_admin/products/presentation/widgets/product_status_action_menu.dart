import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';
import '../dashboard/product_dashboard_providers.dart';
import '../providers/tenant_product_providers.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/widgets/tenant_admin_toast.dart';
import '../utils/product_api_errors.dart';
import '../utils/product_status_actions.dart';

final productStatusUpdatingIdsProvider =
    StateProvider<Set<String>>((ref) => const {});

class ProductStatusActionMenu extends ConsumerWidget {
  const ProductStatusActionMenu({
    super.key,
    required this.productId,
    required this.productName,
    required this.currentStatus,
    this.compact = true,
  });

  final String productId;
  final String productName;
  final String currentStatus;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final updatingIds = ref.watch(productStatusUpdatingIdsProvider);
    final isUpdating = updatingIds.contains(productId);
    final actions = ProductStatusAction.availableForStatus(currentStatus);

    if (actions.isEmpty) {
      return const SizedBox.shrink();
    }

    return PopupMenuButton<ProductStatusAction>(
      tooltip: isUpdating ? 'Updating status...' : 'Change status',
      enabled: !isUpdating,
      icon: isUpdating
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(
              Icons.more_vert,
              size: compact ? 18 : 20,
              color: TenantAdminColors.mutedText,
            ),
      itemBuilder: (context) {
        return actions
            .map(
              (action) => PopupMenuItem<ProductStatusAction>(
                value: action,
                child: Text(action.label),
              ),
            )
            .toList(growable: false);
      },
      onSelected: (action) => _confirmAndUpdate(context, ref, action),
    );
  }

  Future<void> _confirmAndUpdate(
    BuildContext context,
    WidgetRef ref,
    ProductStatusAction action,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(action.confirmationTitle(productName)),
          content: Text(action.confirmationMessage(productName)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(action.label),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    ref.read(productStatusUpdatingIdsProvider.notifier).update(
          (ids) => {...ids, productId},
        );

    try {
      await ref.read(updateProductStatusProvider).call(
            productId: productId,
            status: action.apiValue,
          );

      ref
        ..invalidate(productDetailProvider(productId))
        ..invalidate(productListProvider)
        ..invalidate(productSummaryProvider)
        ..invalidate(productDashboardProvider);

      if (!context.mounted) {
        return;
      }

      showProductSaveToast(
        context,
        title: 'Status Updated',
        message: action.successMessage(productName),
      );
    } on DioException catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            productSubmitErrorMessage(
              error,
              fallback: 'Failed to update product status. Please try again.',
            ),
          ),
        ),
      );
    } catch (_) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update product status. Please try again.'),
        ),
      );
    } finally {
      ref.read(productStatusUpdatingIdsProvider.notifier).update(
            (ids) => ids.where((id) => id != productId).toSet(),
          );
    }
  }
}
