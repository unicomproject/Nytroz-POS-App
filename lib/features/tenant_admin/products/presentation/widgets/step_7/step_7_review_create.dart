import 'package:flutter/material.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/theme/tenant_admin_theme.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/add_product_wizard_state.dart';

/// Step 7 Review for SIMPLE (and shared shell). Create Product is blocked until Chunk 6.
class Step7ReviewCreate extends StatelessWidget {
  const Step7ReviewCreate({
    super.key,
    required this.state,
  });

  final AddProductWizardState state;

  String _unitLabel(String? unitId) {
    if (unitId == null || unitId.isEmpty || state.createOptions == null) {
      return '—';
    }
    try {
      final unit =
          state.createOptions!.units.firstWhere((u) => u.id == unitId);
      return '${unit.name} (${unit.code})';
    } catch (_) {
      return unitId;
    }
  }

  String _categoryLabel() {
    final options = state.createOptions;
    if (options == null || state.categoryId == null) return '—';
    try {
      final cat =
          options.categories.firstWhere((c) => c.id == state.categoryId);
      return cat.name;
    } catch (_) {
      return state.categoryId!;
    }
  }

  String _brandLabel() {
    final options = state.createOptions;
    if (options == null || state.brandId == null) return '—';
    try {
      final brand = options.brands.firstWhere((b) => b.id == state.brandId);
      return brand.name;
    } catch (_) {
      return state.brandId!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isVariant = state.productStructure.toUpperCase() == 'VARIANT';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(TenantAdminSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Review & Create Product',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: TenantAdminColors.bodyText,
            ),
          ),
          const SizedBox(height: TenantAdminSpacing.xs),
          const Text(
            'Please review all the information below. You can edit any section if needed before creating the product.',
            style: TextStyle(
              fontSize: 14,
              color: TenantAdminColors.mutedText,
            ),
          ),
          const SizedBox(height: TenantAdminSpacing.xl),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column
              Expanded(
                child: Column(
                  children: [
                    _ReviewSectionCard(
                      title: 'Basic Information',
                      icon: Icons.info_outline,
                      iconColor: Colors.blue,
                      rows: [
                        _Row('Product Name', state.productName.isEmpty ? '—' : state.productName),
                        _Row('SKU', state.step5State.baseSku.isEmpty ? '—' : state.step5State.baseSku),
                        _Row('Internal Product Code', state.internalCode.isEmpty ? '—' : state.internalCode),
                        _Row('Barcode', state.step5State.parentProductBarcode.isEmpty ? '—' : state.step5State.parentProductBarcode),
                        _Row('Category', _categoryLabel()),
                        _Row('Brand', _brandLabel()),
                        _Row('Product Type', _formatProductType(state.productStructure)),
                        _Row('Description', state.shortDescription.isEmpty ? '—' : state.shortDescription),
                      ],
                    ),
                    const SizedBox(height: TenantAdminSpacing.lg),
                    if (!isVariant) ...[
                      _ReviewSectionCard(
                        title: 'Units & Pack Conversion',
                        icon: Icons.balance,
                        iconColor: Colors.blue,
                        rows: [
                          _Row(
                            'Base Unit',
                            state.unitModel == 'MULTIPLE_UNITS' ? _unitLabel(state.baseUnitId) : _unitLabel(state.productUnitId ?? state.baseUnitId),
                          ),
                          if (state.unitModel == 'MULTIPLE_UNITS') ...[
                             _Row('Selling Unit', _unitLabel(state.sellingUnitId)),
                             _Row('Purchase Unit', _unitLabel(state.purchaseUnitId)),
                          ] else ...[
                             const _Row('Pack Units', 'No additional packs'),
                             const _Row('Pack Conversion', '—'),
                          ],
                        ],
                      ),
                      const SizedBox(height: TenantAdminSpacing.lg),
                    ],
                    _ReviewSectionCard(
                      title: 'Barcode & SKU',
                      icon: Icons.barcode_reader,
                      iconColor: Colors.blue,
                      rows: [
                        _Row('SKU', state.step5State.baseSku.isEmpty ? '—' : state.step5State.baseSku),
                        _Row('Internal Code', state.internalCode.isEmpty ? '—' : state.internalCode),
                        _Row('Barcode', state.step5State.parentProductBarcode.isEmpty ? '—' : state.step5State.parentProductBarcode),
                      ],
                    ),
                    const SizedBox(height: TenantAdminSpacing.lg),
                    _ReviewSectionCard(
                      title: 'Channel Visibility',
                      icon: Icons.language,
                      iconColor: Colors.blue,
                      rows: [
                        _Row('In-Store POS', state.posSellable ? 'Visible' : 'Hidden', isBadge: true, isPositiveBadge: state.posSellable),
                        _Row('Online Store', state.allowOnlineSale ? 'Visible' : 'Hidden', isBadge: true, isPositiveBadge: state.allowOnlineSale),
                        _Row('Available for Click & Collect', 'Yes', isBadge: true, isPositiveBadge: true),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: TenantAdminSpacing.lg),
              // Right Column
              Expanded(
                child: Column(
                  children: [
                    _ReviewSectionCard(
                      title: 'Product Type & Tracking',
                      icon: Icons.local_offer_outlined,
                      iconColor: Colors.green,
                      rows: [
                        _Row('Product Type', _formatProductType(state.productStructure)),
                        _Row('Track Inventory', state.trackInventory ? 'Yes' : 'No', isBadge: true, isPositiveBadge: state.trackInventory),
                        _Row('POS Sellable', state.posSellable ? 'Yes' : 'No', isBadge: true, isPositiveBadge: state.posSellable),
                        _Row('Allow Online Sale', state.allowOnlineSale ? 'Yes' : 'No', isBadge: true, isPositiveBadge: state.allowOnlineSale),
                        _Row('Active Status', state.status == 'ACTIVE' || state.status.isEmpty ? 'Active' : state.status, isBadge: true, isPositiveBadge: true),
                      ],
                    ),
                    const SizedBox(height: TenantAdminSpacing.lg),
                    _ReviewSectionCard(
                      title: isVariant ? 'Product Configuration' : 'Product Configuration',
                      icon: Icons.grid_view,
                      iconColor: Colors.purple,
                      rows: [
                         if (isVariant) ...[
                            _Row('Attributes', '${state.step4State.attributeRows.where((a) => a.isValid).length}'),
                            _Row('Variants Created', '${state.step4State.generatedVariants.where((v) => v.isIncluded).length}'),
                         ] else ...[
                            const _Row('Configuration Type', 'Simple'),
                         ]
                      ],
                    ),
                    const SizedBox(height: TenantAdminSpacing.lg),
                    _ReviewSectionCard(
                      title: 'Pricing & Tax',
                      icon: Icons.attach_money,
                      iconColor: Colors.blue,
                      rows: [
                        _Row('Selling Price (LKR)', state.standardSellingPrice != null ? _formatCurrency(state.standardSellingPrice!.toDouble()) : '—'),
                        _Row('Cost Price (LKR)', state.costPrice != null ? _formatCurrency(state.costPrice!.toDouble()) : '—'),
                        _Row('Tax Class', state.taxName ?? state.taxId ?? 'Standard'),
                        _Row('Tax Included', !state.taxExclusive ? 'Yes' : 'No', isBadge: true, isPositiveBadge: !state.taxExclusive),
                      ],
                    ),
                    const SizedBox(height: TenantAdminSpacing.lg),
                    _ReviewSectionCard(
                      title: 'Product Images',
                      icon: Icons.image_outlined,
                      iconColor: Colors.blue,
                      rows: const [],
                      customContent: state.productImages.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(TenantAdminSpacing.md),
                                child: Text('No images added.', style: TextStyle(color: TenantAdminColors.mutedText)),
                              ),
                            )
                          : Wrap(
                              spacing: TenantAdminSpacing.sm,
                              runSpacing: TenantAdminSpacing.sm,
                              children: [
                                ...state.productImages.take(5).map((img) => _buildImageThumbnail(img)),
                                if (state.productImages.length > 5)
                                  Container(
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      color: TenantAdminColors.secondary,
                                      borderRadius: BorderRadius.circular(TenantAdminRadius.md),
                                      border: Border.all(color: TenantAdminColors.border),
                                    ),
                                    alignment: Alignment.center,
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.cloud_upload_outlined, size: 20, color: Colors.blue),
                                        const SizedBox(height: 4),
                                        Text('+${state.productImages.length - 5} More', style: const TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: TenantAdminSpacing.xxl),
        ],
      ),
    );
  }

  String _formatProductType(String structure) {
    switch (structure.toUpperCase()) {
      case 'VARIANT':
        return 'Variant Product';
      case 'BUNDLE':
        return 'Bundle / Kit';
      case 'SIMPLE':
      default:
        return 'Simple Product';
    }
  }

  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
  }

  Widget _buildImageThumbnail(dynamic img) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: TenantAdminColors.secondary,
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        border: Border.all(color: TenantAdminColors.border),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(TenantAdminRadius.md),
            child: img.bytes != null 
              ? Image.memory(img.bytes, fit: BoxFit.cover)
              : (img.imageUrl.isNotEmpty ? Image.network(img.imageUrl, fit: BoxFit.cover) : const Icon(Icons.image, color: TenantAdminColors.mutedText)),
          ),
          if (img.isPrimary)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(TenantAdminRadius.md - 1), bottomRight: Radius.circular(TenantAdminRadius.md - 1)),
                ),
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: const Text('Primary', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
    );
  }
}

class _ReviewSectionCard extends StatelessWidget {
  const _ReviewSectionCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.rows,
    this.customContent,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final List<_Row> rows;
  final Widget? customContent;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        border: Border.all(color: TenantAdminColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(TenantAdminSpacing.md),
            child: Row(
              children: [
                Icon(icon, color: iconColor, size: 20),
                const SizedBox(width: TenantAdminSpacing.sm),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: TenantAdminColors.bodyText,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {}, // For visual completeness matching the design
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    foregroundColor: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: TenantAdminColors.border),
          Padding(
            padding: const EdgeInsets.all(TenantAdminSpacing.md),
            child: customContent ??
                Column(
                  children: rows.map((r) => _buildRow(r)).toList(),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(_Row r) {
    return Padding(
      padding: const EdgeInsets.only(bottom: TenantAdminSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              r.label,
              style: const TextStyle(
                fontSize: 13,
                color: TenantAdminColors.mutedText,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: r.isBadge
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: _buildStatusBadge(r.value, r.isPositiveBadge),
                  )
                : Text(
                    r.value,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: TenantAdminColors.bodyText,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String text, bool isPositive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isPositive ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
        border: Border.all(color: isPositive ? Colors.green : Colors.red),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isPositive ? Colors.green : Colors.red,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _Row {
  const _Row(this.label, this.value, {this.isBadge = false, this.isPositiveBadge = true});
  final String label;
  final String value;
  final bool isBadge;
  final bool isPositiveBadge;
}
