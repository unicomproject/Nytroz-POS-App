import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_row_action.dart';
import '../../domain/entities/product_delete_result.dart';
import '../dashboard/product_dashboard_providers.dart';
import '../providers/tenant_product_providers.dart';
import '../utils/product_api_errors.dart';

class ProductDeleteAction extends ConsumerWidget {
  const ProductDeleteAction({
    super.key,
    required this.productId,
    required this.productName,
    this.sku,
    this.imageUrl,
    this.navigateToListOnSuccess = false,
    this.compact = true,
    this.isLocalDraft = false,
  });

  final String productId;
  final String productName;
  final String? sku;
  final String? imageUrl;
  final bool navigateToListOnSuccess;
  final bool compact;
  final bool isLocalDraft;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deletingIds = ref.watch(productDeletingIdsProvider);
    final isDeleting = deletingIds.contains(productId);

    const color = TenantAdminColors.danger;
    final bg = TenantAdminColors.danger.withValues(alpha: 0.08);
    final border = TenantAdminColors.danger.withValues(alpha: 0.3);

    return Tooltip(
      message: isDeleting
          ? (isLocalDraft ? 'Deleting draft...' : 'Deleting product...')
          : (isLocalDraft ? 'Delete draft' : 'Delete product'),
      child: InkWell(
        onTap: isDeleting ? null : () => _confirmAndDelete(context, ref),
        borderRadius: BorderRadius.circular(compact ? 8 : 4),
        child: compact
            ? Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: border, width: 1),
                ),
                child: isDeleting
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(
                        Icons.delete_outline,
                        size: 16,
                        color: color,
                      ),
              )
            : Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    isDeleting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: color),
                          )
                        : const Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: color,
                          ),
                    const SizedBox(width: 8),
                    const Text(
                      'Delete',
                      style: TextStyle(
                        color: color,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Future<void> _confirmAndDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return _DeleteConfirmationDialog(
          productName: productName,
          sku: sku,
          imageUrl: imageUrl,
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
      if (isLocalDraft) {
        await ref
            .read(productWizardDraftLocalRepositoryProvider)
            .deleteDraft(productId);
        ref.invalidate(localProductWizardDraftsProvider);
        ref.invalidate(productListProvider);

        if (!context.mounted) {
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Draft "$productName" deleted from this device.'),
          ),
        );

        if (navigateToListOnSuccess) {
          context.go('/tenant-admin/products');
        }
        return;
      }

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

class _DeleteConfirmationDialog extends StatelessWidget {
  const _DeleteConfirmationDialog({
    required this.productName,
    this.sku,
    this.imageUrl,
  });

  final String productName;
  final String? sku;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final titleName = productName.trim().isEmpty ? 'Product' : productName;
    final displaySku = (sku != null && sku!.trim().isNotEmpty) ? sku! : 'N/A';

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      backgroundColor: TenantAdminColors.surface,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(TenantAdminSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Red Trash Icon + Title + Close Button
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFEE2E2),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      size: 20,
                      color: Color(0xFFEF4444),
                    ),
                  ),
                  const SizedBox(width: TenantAdminSpacing.md),
                  const Expanded(
                    child: Text(
                      'Delete Product',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: TenantAdminColors.bodyText,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    icon: const Icon(
                      Icons.close,
                      size: 20,
                      color: TenantAdminColors.mutedText,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: TenantAdminSpacing.md),

              // Message Subtitle
              const Text(
                'Are you sure you want to delete this product?',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: TenantAdminColors.mutedText,
                ),
              ),
              const SizedBox(height: TenantAdminSpacing.md),

              // Product Info Preview Card
              Container(
                padding: const EdgeInsets.all(TenantAdminSpacing.md),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(TenantAdminRadius.md),
                  border: Border.all(color: TenantAdminColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAFAFA),
                        borderRadius:
                            BorderRadius.circular(TenantAdminRadius.sm),
                        border: Border.all(color: TenantAdminColors.border),
                      ),
                      child: imageUrl != null && imageUrl!.trim().isNotEmpty
                          ? ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(TenantAdminRadius.sm),
                              child: Image.network(
                                imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildPlaceholderIcon(),
                              ),
                            )
                          : _buildPlaceholderIcon(),
                    ),
                    const SizedBox(width: TenantAdminSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            titleName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: TenantAdminColors.bodyText,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'SKU: $displaySku',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: TenantAdminColors.mutedText,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: TenantAdminSpacing.md),

              // Warning Alert Box
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: TenantAdminSpacing.md,
                  vertical: TenantAdminSpacing.sm + 2,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(TenantAdminRadius.md),
                  border: Border.all(color: const Color(0xFFFFEDD5)),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 18,
                      color: Color(0xFFEA580C),
                    ),
                    SizedBox(width: TenantAdminSpacing.sm),
                    Expanded(
                      child: Text(
                        'Products with sales or stock history will be archived to preserve reports, while products without history will be permanently deleted.',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFC2410C),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: TenantAdminSpacing.xl),

              // Footer Action Buttons: Cancel + Delete Product
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      side: const BorderSide(color: TenantAdminColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(TenantAdminRadius.md),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: TenantAdminColors.bodyText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: TenantAdminSpacing.md),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF2D1A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(TenantAdminRadius.md),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Delete Product',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderIcon() {
    return const Center(
      child: Icon(
        Icons.checkroom_outlined,
        size: 22,
        color: TenantAdminColors.primary,
      ),
    );
  }
}
