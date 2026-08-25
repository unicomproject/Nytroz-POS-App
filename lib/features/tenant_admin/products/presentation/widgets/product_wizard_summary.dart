import 'package:flutter/material.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/theme/tenant_admin_theme.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/add_product_wizard_state.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/staged_product_image.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/tenant_product_create_options.dart';

class ProductWizardSummary extends StatelessWidget {
  const ProductWizardSummary({
    super.key,
    required this.state,
  });

  final AddProductWizardState state;

  @override
  Widget build(BuildContext context) {
    final primaryImage = state.productImages.firstWhere(
      (img) => img.isPrimary,
      orElse: () => state.productImages.isNotEmpty
          ? state.productImages.first
          : const ProductWizardImageItem(
              id: '',
              mediaAssetId: '',
              imageUrl: '',
              fileName: '',
              isPrimary: false,
              sortOrder: 0,
            ),
    );

    final String? categoryName = state.createOptions?.categories
        .firstWhere((c) => c.id == state.categoryId,
            orElse: () =>
                const ProductCategoryOption(id: '', code: '', name: ''))
        .name;

    final String? brandName = state.createOptions?.brands
        .firstWhere((b) => b.id == state.brandId,
            orElse: () => const ProductBrandOption(id: '', code: '', name: ''))
        .name;

    return Container(
      width: 280,
      padding: const EdgeInsets.all(TenantAdminSpacing.lg),
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
        border: Border.all(color: TenantAdminColors.border),
        boxShadow: TenantAdminShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Product Summary',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: TenantAdminColors.bodyText,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: TenantAdminSpacing.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: TenantAdminColors.posHomeAccentOrange
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
                ),
                child: Text(
                  state.status.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: TenantAdminColors.posHomeAccentOrange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: TenantAdminSpacing.md),
          const Divider(height: 1, color: TenantAdminColors.border),
          const SizedBox(height: TenantAdminSpacing.md),

          // Product Cover Image
          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: TenantAdminColors.secondary,
                borderRadius: BorderRadius.circular(TenantAdminRadius.md),
                border: Border.all(color: TenantAdminColors.border),
              ),
              child: primaryImage.imageUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(TenantAdminRadius.md),
                      child: Image.network(
                        primaryImage.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.inventory_2_outlined,
                          size: 40,
                          color: TenantAdminColors.mutedText,
                        ),
                      ),
                    )
                  : const Icon(
                      Icons.inventory_2_outlined,
                      size: 40,
                      color: TenantAdminColors.mutedText,
                    ),
            ),
          ),
          const SizedBox(height: TenantAdminSpacing.md),

          // Name & Code
          Text(
            state.productName.isEmpty ? 'Untitled Product' : state.productName,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: TenantAdminColors.bodyText,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            state.internalCode.isEmpty
                ? 'Product Code: Pending'
                : state.internalCode,
            style: const TextStyle(
              fontSize: 12,
              color: TenantAdminColors.mutedText,
            ),
          ),
          const SizedBox(height: TenantAdminSpacing.md),

          // Property Rows
          _buildSummaryRow(
            'Product Type',
            _formatProductType(state.productStructure),
          ),
          _buildSummaryRow(
            'Inventory Method',
            state.inventoryMethod != null && state.inventoryMethod!.isNotEmpty
                ? _formatInventoryMethod(state.inventoryMethod!)
                : _deriveInventoryMethod(
                    state.productStructure, state.trackInventory),
          ),
          _buildSummaryRow(
            'Category',
            (categoryName != null && categoryName.isNotEmpty)
                ? categoryName
                : 'Not selected',
          ),
          _buildSummaryRow(
            'Brand',
            (brandName != null && brandName.isNotEmpty)
                ? brandName
                : 'Not selected',
          ),
          if (state.productStructure == 'BUNDLE')
            _buildSummaryRow(
              'Components',
              state.componentsConfigured
                  ? '${state.componentCount} Configured'
                  : 'Not configured',
            )
          else
            _buildSummaryRow(
              'Inventory Tracking',
              state.trackInventory ? 'Tracked' : 'Not Tracked',
            ),
          if (state.trackInventory && state.productStructure != 'BUNDLE') ...[
            _buildSummaryRow(
              'Unit Model',
              state.unitModel == 'MULTIPLE_UNITS'
                  ? 'Multiple Units'
                  : 'Single Unit',
            ),
            if (state.unitModel == 'SINGLE_UNIT' &&
                (state.productUnitId != null || state.baseUnitId != null))
              _buildSummaryRow(
                'Product Unit',
                state.baseUnitName ??
                    state.createOptions?.units
                        .firstWhere(
                          (u) =>
                              u.id == (state.productUnitId ?? state.baseUnitId),
                          orElse: () => const ProductUnitOption(
                              id: '', code: '', name: 'Selected'),
                        )
                        .name ??
                    'Configured',
              ),
            if (state.unitModel == 'MULTIPLE_UNITS') ...[
              if (state.baseUnitId != null)
                _buildSummaryRow(
                  'Base Unit',
                  state.baseUnitName ??
                      state.createOptions?.units
                          .firstWhere(
                            (u) => u.id == state.baseUnitId,
                            orElse: () => const ProductUnitOption(
                                id: '', code: '', name: 'Selected'),
                          )
                          .name ??
                      'Configured',
                ),
              if (state.purchaseUnitId != null)
                _buildSummaryRow(
                  'Purchase Unit',
                  state.purchaseUnitName ??
                      state.createOptions?.units
                          .firstWhere(
                            (u) => u.id == state.purchaseUnitId,
                            orElse: () => const ProductUnitOption(
                                id: '', code: '', name: 'Selected'),
                          )
                          .name ??
                      'Configured',
                ),
              if (state.sellingUnitId != null)
                _buildSummaryRow(
                  'Selling Unit',
                  state.sellingUnitName ??
                      state.createOptions?.units
                          .firstWhere(
                            (u) => u.id == state.sellingUnitId,
                            orElse: () => const ProductUnitOption(
                                id: '', code: '', name: 'Selected'),
                          )
                          .name ??
                      'Configured',
                ),
            ],
          ],
          _buildSummaryRow('SKU', 'Pending'),
          const SizedBox(height: TenantAdminSpacing.md),

          // Step Progress
          Container(
            padding: const EdgeInsets.all(TenantAdminSpacing.sm),
            decoration: BoxDecoration(
              color: TenantAdminColors.secondary,
              borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  size: 16,
                  color: TenantAdminColors.success,
                ),
                const SizedBox(width: TenantAdminSpacing.xs),
                Text(
                  'Step ${state.currentStep} of 7 Active',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: TenantAdminColors.bodyText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: TenantAdminColors.mutedText,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: TenantAdminColors.bodyText,
            ),
          ),
        ],
      ),
    );
  }

  String _formatProductType(String structure) {
    switch (structure) {
      case 'VARIANT':
        return 'Variant Product';
      case 'BUNDLE':
        return 'Bundle / Kit';
      case 'SIMPLE':
      default:
        return 'Simple Product';
    }
  }

  String _formatInventoryMethod(String method) {
    switch (method) {
      case 'VARIANT_BASED':
        return 'Variant-based';
      case 'COMPONENT_BASED':
        return 'Component-based';
      case 'PRODUCT_BASED':
        return 'Product-based';
      default:
        return method;
    }
  }

  String _deriveInventoryMethod(String structure, bool trackInventory) {
    if (structure == 'BUNDLE') {
      return 'Component-based';
    }
    if (!trackInventory) {
      return 'Not Tracked';
    }
    if (structure == 'VARIANT') {
      return 'Variant-based';
    }
    return 'Product-based';
  }
}
