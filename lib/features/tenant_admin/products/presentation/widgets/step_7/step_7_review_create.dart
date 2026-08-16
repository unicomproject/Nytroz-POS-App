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
    final isSimple = state.productStructure.toUpperCase() == 'SIMPLE';
    final isVariant = state.productStructure.toUpperCase() == 'VARIANT';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(TenantAdminSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Review & Create',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: TenantAdminColors.bodyText,
            ),
          ),
          const SizedBox(height: TenantAdminSpacing.xs),
          const Text(
            'Confirm the product details below. Final Create Product is not enabled yet.',
            style: TextStyle(
              fontSize: 14,
              color: TenantAdminColors.mutedText,
            ),
          ),
          const SizedBox(height: TenantAdminSpacing.xl),
          _Section(
            title: 'Basic Details',
            rows: [
              _Row('Product Name', state.productName),
              _Row('Internal Code',
                  state.internalCode.isEmpty ? '—' : state.internalCode),
              _Row('Category', _categoryLabel()),
              _Row('Brand', _brandLabel()),
              _Row(
                'Short Description',
                state.shortDescription.isEmpty ? '—' : state.shortDescription,
              ),
            ],
          ),
          _Section(
            title: 'Channel Visibility',
            rows: [
              _Row('In-Store POS', state.posSellable ? 'On' : 'Off'),
              _Row('Online Store', state.allowOnlineSale ? 'On' : 'Off'),
            ],
          ),
          _Section(
            title: 'Product Type & Tracking',
            rows: [
              _Row('Product Type', state.productStructure),
              _Row('Track Inventory', state.trackInventory ? 'On' : 'Off'),
              _Row('Batch Tracking', state.batchTracking ? 'On' : 'Off'),
              _Row('Expiry Tracking', state.expiryTracking ? 'On' : 'Off'),
              _Row('Serial Tracking', state.serialTracking ? 'On' : 'Off'),
            ],
          ),
          if (isSimple)
            _Section(
              title: 'Units & Pack Conversion',
              rows: [
                _Row(
                  'Unit Model',
                  state.unitModel == 'MULTIPLE_UNITS'
                      ? 'Multiple Units'
                      : 'Single Unit',
                ),
                if (state.unitModel == 'SINGLE_UNIT')
                  _Row(
                    'Product Unit',
                    _unitLabel(state.productUnitId ?? state.baseUnitId),
                  ),
                if (state.unitModel == 'MULTIPLE_UNITS') ...[
                  _Row('Base Unit', _unitLabel(state.baseUnitId)),
                  _Row('Selling Unit', _unitLabel(state.sellingUnitId)),
                  _Row('Purchase Unit', _unitLabel(state.purchaseUnitId)),
                  _Row(
                    'Items per Purchase Unit',
                    state.itemsPerPurchaseUnit?.toString() ?? '—',
                  ),
                  _Row('Outer Pack Unit', _unitLabel(state.outerPackUnitId)),
                  _Row(
                    'Purchase Units per Outer Pack',
                    state.purchaseUnitsPerOuterPack?.toString() ?? '—',
                  ),
                ],
                _Row(
                  'Allow Decimal Quantity',
                  state.allowDecimalQuantity ? 'Yes' : 'No',
                ),
              ],
            ),
          if (isVariant)
            _Section(
              title: 'Variant Configuration',
              rows: [
                _Row(
                  'Attributes',
                  '${state.step4State.attributeRows.where((a) => a.isValid).length}',
                ),
                _Row(
                  'Generated Variants',
                  '${state.step4State.generatedVariants.where((v) => v.isIncluded).length}',
                ),
                ...state.step4State.generatedVariants
                    .where((v) => v.isIncluded)
                    .map(
                      (v) => _Row(
                        'Variant',
                        v.displayLabel ?? v.combinationLabel,
                      ),
                    ),
              ],
            ),
          if (isSimple)
            _Section(
              title: 'Barcode & SKU',
              rows: [
                _Row(
                  'Base SKU',
                  state.step5State.baseSku.isEmpty
                      ? '—'
                      : state.step5State.baseSku,
                ),
                _Row(
                  'Parent Product Barcode',
                  state.step5State.parentProductBarcode.isEmpty
                      ? '—'
                      : state.step5State.parentProductBarcode,
                ),
              ],
            ),
          if (isVariant)
            _Section(
              title: 'Variant SKU / Barcode',
              rows: state.step5State.assignments.isEmpty
                  ? [const _Row('Assignments', '—')]
                  : state.step5State.assignments.map((a) {
                      final variant = state.step4State.generatedVariants
                          .where(
                              (v) => v.clientCombinationKey == a.clientCombinationKey)
                          .toList();
                      final label = variant.isNotEmpty
                          ? (variant.first.displayLabel ??
                              variant.first.combinationLabel)
                          : a.clientCombinationKey;
                      final sku = a.sku?.isNotEmpty == true ? a.sku! : '—';
                      final barcode =
                          a.barcode?.isNotEmpty == true ? a.barcode! : '—';
                      return _Row(label, 'SKU: $sku · Barcode: $barcode');
                    }).toList(),
            ),
          _Section(
            title: 'Pricing & Tax',
            rows: [
              _Row('Cost Price', state.costPrice?.toString() ?? '—'),
              _Row(
                'Standard Selling Price',
                state.standardSellingPrice?.toString() ?? '—',
              ),
              _Row(
                'Discount Price',
                state.discountPrice?.toString() ?? '—',
              ),
              _Row(
                'Tax Name',
                state.taxName ?? state.taxId ?? '—',
              ),
              _Row(
                'Tax Rate',
                state.taxRate != null ? '${state.taxRate}%' : '—',
              ),
              _Row(
                'Tax Exclusive',
                state.taxExclusive ? 'Yes' : 'No',
              ),
            ],
          ),
          const SizedBox(height: TenantAdminSpacing.lg),
          Container(
            padding: const EdgeInsets.all(TenantAdminSpacing.md),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(TenantAdminRadius.md),
              border: Border.all(color: const Color(0xFFFDBA74)),
            ),
            child: const Text(
              'Review all values carefully. Create Product will persist this '
              'Product to the catalog in a single atomic transaction.',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF9A3412),
              ),
            ),
          ),
          const SizedBox(height: TenantAdminSpacing.xxl),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.rows});

  final String title;
  final List<_Row> rows;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: TenantAdminSpacing.lg),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(TenantAdminSpacing.lg),
        decoration: BoxDecoration(
          color: TenantAdminColors.surface,
          borderRadius: BorderRadius.circular(TenantAdminRadius.md),
          border: Border.all(color: TenantAdminColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: TenantAdminColors.bodyText,
              ),
            ),
            const SizedBox(height: TenantAdminSpacing.md),
            ...rows.map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: TenantAdminSpacing.sm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 180,
                      child: Text(
                        r.label,
                        style: const TextStyle(
                          fontSize: 13,
                          color: TenantAdminColors.mutedText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        r.value,
                        style: const TextStyle(
                          fontSize: 13,
                          color: TenantAdminColors.bodyText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Row {
  const _Row(this.label, this.value);
  final String label;
  final String value;
}
