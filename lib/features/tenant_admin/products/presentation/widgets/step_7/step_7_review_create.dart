import 'package:flutter/material.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/theme/tenant_admin_theme.dart';
import 'package:nytroz_pos/features/tenant_admin/products/data/models/step5_barcode_dtos.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/add_product_wizard_state.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/product_wizard_capabilities.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/staged_product_image.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/step4_variant_configuration_state.dart';
import 'package:nytroz_pos/features/tenant_admin/products/presentation/controllers/add_product_wizard_controller.dart';
import 'package:nytroz_pos/features/tenant_admin/products/presentation/utils/step_6_variant_pricing.dart';

/// Step 7 Review & Create — structure-aware projection of Steps 1–6.
/// Card titles match the wizard stepper names. SIMPLE skips Product
/// Configuration; VARIANT skips Units & Pack Conversion.
class Step7ReviewCreate extends StatelessWidget {
  const Step7ReviewCreate({
    super.key,
    required this.state,
    this.controller,
    this.canViewProductCost = true,
  });

  final AddProductWizardState state;
  final AddProductWizardController? controller;
  final bool canViewProductCost;

  String get _structure => state.productStructure.toUpperCase();
  bool get _isVariant => _structure == 'VARIANT';
  bool get _isSimple => _structure == 'SIMPLE';
  bool get _isBundle => _structure == 'BUNDLE';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(TenantAdminSpacing.md),
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
          Text(
            _isVariant
                ? 'Review all variant product information and create the product.'
                : 'Please review all the information below. You can edit any section if needed before creating the product.',
            style: const TextStyle(
              fontSize: 14,
              color: TenantAdminColors.mutedText,
            ),
          ),
          const SizedBox(height: TenantAdminSpacing.xl),
          _ReviewCardGrid(
            children: [
              _basicDetailsCard(),
              _productTypeTrackingCard(),
              if (_isSimple) _unitsPackCard(),
              if (_isVariant || _isBundle) _productConfigurationCard(),
              _barcodeSkuCard(),
              _pricingTaxCard(),
            ],
          ),
          const SizedBox(height: TenantAdminSpacing.xxl),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Step 1 — Basic Details
  // ---------------------------------------------------------------------------

  Widget _basicDetailsCard() {
    return _ReviewSectionCard(
      title: 'Basic Details',
      icon: Icons.info_outline,
      iconColor: TenantAdminColors.info,
      onEdit: _edit(1),
      rows: [
        _Row('Product Name', _dash(state.productName)),
        _Row('Product Code', _dash(state.internalCode)),
        _Row('Category', _categoryLabel()),
        _Row('Brand', _brandLabel()),
        _Row('Short Description', _dash(state.shortDescription)),
        if (state.longDescription.trim().isNotEmpty)
          _Row('Long Description', state.longDescription.trim()),
        _Row(
          'In-Store POS',
          state.posSellable ? 'Enabled' : 'Disabled',
          badge: state.posSellable ? _BadgeTone.positive : _BadgeTone.negative,
        ),
        _Row(
          'Online Store',
          state.allowOnlineSale ? 'Enabled' : 'Disabled',
          badge:
              state.allowOnlineSale ? _BadgeTone.positive : _BadgeTone.negative,
        ),
      ],
      customContent: _imagesContent(),
    );
  }

  // ---------------------------------------------------------------------------
  // Step 2 — Product Type & Tracking
  // ---------------------------------------------------------------------------

  Widget _productTypeTrackingCard() {
    final rows = <_Row>[
      _Row('Product Type', _formatProductType(state.productStructure)),
      _Row(
        'Track Inventory',
        state.trackInventory ? 'Yes' : 'No',
        badge:
            state.trackInventory ? _BadgeTone.positive : _BadgeTone.negative,
      ),
    ];

    if (state.trackInventory && !_isBundle) {
      rows.addAll([
        _Row(
          'Batch / Lot Tracking',
          state.batchTracking ? 'Yes' : 'No',
          badge:
              state.batchTracking ? _BadgeTone.positive : _BadgeTone.neutral,
        ),
        _Row(
          'Expiry Date Tracking',
          state.expiryTracking ? 'Yes' : 'No',
          badge:
              state.expiryTracking ? _BadgeTone.positive : _BadgeTone.neutral,
        ),
        _Row(
          'Serial Number Tracking',
          state.serialTracking ? 'Yes' : 'No',
          badge:
              state.serialTracking ? _BadgeTone.positive : _BadgeTone.neutral,
        ),
      ]);
    }

    rows.addAll([
      _Row(
        'POS Sellable',
        state.posSellable ? 'Yes' : 'No',
        badge: state.posSellable ? _BadgeTone.positive : _BadgeTone.negative,
      ),
      _Row(
        'Allow Online Sale',
        state.allowOnlineSale ? 'Yes' : 'No',
        badge:
            state.allowOnlineSale ? _BadgeTone.positive : _BadgeTone.negative,
      ),
      _Row(
        'Active Status',
        _statusLabel(),
        badge: _statusTone(),
      ),
    ]);

    rows.addAll(_compatibleTrackingRows());

    return _ReviewSectionCard(
      title: 'Product Type & Tracking',
      icon: Icons.local_offer_outlined,
      iconColor: TenantAdminColors.success,
      onEdit: _edit(2),
      rows: rows,
      customContent: _isVariant ? _variantAssignment() : null,
    );
  }

  // ---------------------------------------------------------------------------
  // Step 3 — Units & Pack Conversion (SIMPLE only)
  // ---------------------------------------------------------------------------

  Widget _unitsPackCard() {
    final isMultiple = state.unitModel == 'MULTIPLE_UNITS';
    final rows = <_Row>[
      _Row(
        'Unit Model',
        isMultiple ? 'Multiple Units & Pack Conversion' : 'Single Unit Only',
      ),
    ];

    if (isMultiple) {
      rows.addAll([
        _Row('Base Unit', _unitLabel(state.baseUnitId)),
        _Row('Selling Unit', _unitLabel(state.sellingUnitId)),
        _Row('Purchase Unit', _unitLabel(state.purchaseUnitId)),
        if (state.outerPackUnitId != null && state.outerPackUnitId!.isNotEmpty)
          _Row('Outer Pack Unit', _unitLabel(state.outerPackUnitId)),
        if (state.itemsPerPurchaseUnit != null)
          _Row(
            'Items per Purchase Unit',
            _formatNumber(state.itemsPerPurchaseUnit!),
          ),
        if (state.purchaseUnitsPerOuterPack != null)
          _Row(
            'Purchase Units per Outer Pack',
            _formatNumber(state.purchaseUnitsPerOuterPack!),
          ),
      ]);
      for (final conv in state.unitConversions) {
        rows.add(
          _Row(
            '${conv.uomName} (${conv.uomCode})',
            '${_formatNumber(conv.conversionToBaseFactor)} × base',
          ),
        );
      }
    } else {
      rows.add(
        _Row(
          'Product Unit',
          _unitLabel(state.productUnitId ?? state.baseUnitId),
        ),
      );
    }

    rows.add(
      _Row(
        'Decimal Quantity',
        state.allowDecimalQuantity ? 'Allow decimals' : 'Whole numbers only',
      ),
    );

    return _ReviewSectionCard(
      title: 'Units & Pack Conversion',
      icon: Icons.balance,
      iconColor: TenantAdminColors.info,
      onEdit: _edit(3),
      rows: rows,
    );
  }

  // ---------------------------------------------------------------------------
  // Step 4 — Product Configuration (VARIANT / BUNDLE)
  // ---------------------------------------------------------------------------

  Widget _productConfigurationCard() {
    if (_isBundle) {
      return _ReviewSectionCard(
        title: 'Product Configuration',
        icon: Icons.grid_view,
        iconColor: const Color(0xFF7C3AED),
        onEdit: _edit(4),
        rows: [
          const _Row('Configuration Type', 'Bundle / Kit'),
          _Row('Components', '${state.componentCount}'),
          _Row(
            'Components Configured',
            state.componentsConfigured ? 'Yes' : 'No',
            badge: state.componentsConfigured
                ? _BadgeTone.positive
                : _BadgeTone.neutral,
          ),
        ],
      );
    }

    final validAttrs =
        state.step4State.attributeRows.where((a) => a.isValid).toList();
    final included = _includedVariants();
    final generated = state.step4State.generatedVariants;
    final naming = validAttrs
        .map((a) => a.templateName ?? 'Attribute')
        .where((n) => n.trim().isNotEmpty)
        .join(' / ');
    final example = included.isEmpty
        ? '—'
        : (included.first.displayLabel ?? included.first.combinationLabel);

    final rows = <_Row>[
      _Row('Attributes', '${validAttrs.length}'),
      _Row('Variants Created', '${included.length}'),
      _Row('Total Generated', '${generated.length}'),
      _Row('Included Variants', '${included.length} of ${generated.length}'),
    ];

    for (final attr in validAttrs) {
      final names = attr.selectedValues.map((v) => v.valueName).join(', ');
      rows.add(
        _Row(
          '${attr.templateName ?? 'Attribute'} (${attr.selectedValues.length})',
          names.isEmpty ? '—' : names,
        ),
      );
    }

    if (naming.isNotEmpty) {
      rows.add(_Row('Variant Naming', naming));
    }
    rows.add(_Row('Example Variant', example));

    return _ReviewSectionCard(
      title: 'Product Configuration',
      icon: Icons.grid_view,
      iconColor: const Color(0xFF7C3AED),
      onEdit: _edit(4),
      rows: rows,
      customContent: included.isEmpty ? null : _variantNameList(included),
    );
  }

  // ---------------------------------------------------------------------------
  // Step 5 — Barcode & SKU
  // ---------------------------------------------------------------------------

  Widget _barcodeSkuCard() {
    if (_isVariant) {
      return _variantBarcodeSkuCard();
    }

    return _ReviewSectionCard(
      title: 'Barcode & SKU',
      icon: Icons.barcode_reader,
      iconColor: TenantAdminColors.info,
      onEdit: _edit(5),
      rows: [
        _Row('SKU', _dash(state.step5State.baseSku)),
        _Row(
          'Barcode',
          _dash(state.step5State.parentProductBarcode),
        ),
        if ((state.step5State.parentBarcodeType ?? '').trim().isNotEmpty)
          _Row('Barcode Type', state.step5State.parentBarcodeType!.trim()),
      ],
    );
  }

  Widget _variantBarcodeSkuCard() {
    final assignments = _variantAssignments();
    final total = assignments.isNotEmpty
        ? assignments.length
        : _includedVariants().length;
    final withSku = assignments
        .where((a) => a.sku != null && a.sku!.trim().isNotEmpty)
        .length;
    final withBarcode = assignments
        .where((a) => a.barcode != null && a.barcode!.trim().isNotEmpty)
        .length;
    final allComplete = total > 0 && withSku == total && withBarcode == total;

    return _ReviewSectionCard(
      title: 'Barcode & SKU',
      icon: Icons.barcode_reader,
      iconColor: TenantAdminColors.info,
      onEdit: _edit(5),
      rows: [
        _Row('Variants with SKU', '$withSku of $total'),
        _Row('Variants with Barcode', '$withBarcode of $total'),
      ],
      customContent: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CompletionBar(label: 'Variants with SKU', complete: withSku, total: total),
          const SizedBox(height: TenantAdminSpacing.sm),
          _CompletionBar(
            label: 'Variants with Barcode',
            complete: withBarcode,
            total: total,
          ),
          if (allComplete) ...[
            const SizedBox(height: TenantAdminSpacing.md),
            const _SuccessBanner(
              message: 'All variants have SKU and barcode assigned.',
            ),
          ],
          if (assignments.isNotEmpty) ...[
            const SizedBox(height: TenantAdminSpacing.md),
            const Text(
              'Variant Identifiers',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: TenantAdminColors.bodyText,
              ),
            ),
            const SizedBox(height: TenantAdminSpacing.sm),
            ...assignments.map(_identifierRow),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Step 6 — Pricing & Tax
  // ---------------------------------------------------------------------------

  Widget _pricingTaxCard() {
    if (_isVariant) {
      return _ReviewSectionCard(
        title: 'Pricing & Tax',
        icon: Icons.attach_money,
        iconColor: TenantAdminColors.info,
        onEdit: _edit(6),
        rows: _variantPricingTaxRows(),
        customContent: _variantPricingSummary(),
      );
    }

    final currency = _currencyCode();
    final rows = <_Row>[
      _Row(
        currency.isEmpty ? 'Selling Price' : 'Selling Price ($currency)',
        state.standardSellingPrice != null
            ? _formatCurrency(state.standardSellingPrice!.toDouble())
            : '—',
      ),
    ];

    if (canViewProductCost && state.costPrice != null) {
      rows.add(
        _Row(
          currency.isEmpty ? 'Cost Price' : 'Cost Price ($currency)',
          _formatCurrency(state.costPrice!.toDouble()),
        ),
      );
    }
    if (state.discountPrice != null) {
      rows.add(
        _Row(
          currency.isEmpty ? 'Discount Price' : 'Discount Price ($currency)',
          _formatCurrency(state.discountPrice!.toDouble()),
        ),
      );
    }

    rows.addAll(_taxRows());

    return _ReviewSectionCard(
      title: 'Pricing & Tax',
      icon: Icons.attach_money,
      iconColor: TenantAdminColors.info,
      onEdit: _edit(6),
      rows: rows,
    );
  }

  List<_Row> _taxRows() {
    final taxLabel = (state.taxName ?? '').trim().isNotEmpty
        ? state.taxName!.trim()
        : ((state.taxId ?? '').trim().isNotEmpty ? state.taxId!.trim() : '—');
    return [
      _Row('Tax Class', taxLabel),
      if (state.taxRate != null)
        _Row('Tax Rate', '${state.taxRate!.toStringAsFixed(2)}%'),
      _Row(
        'Tax Presentation',
        state.taxExclusive ? 'Tax Exclusive' : 'Tax Inclusive',
      ),
      _Row(
        'Tax Included',
        !state.taxExclusive ? 'Yes' : 'No',
        badge: !state.taxExclusive ? _BadgeTone.positive : _BadgeTone.neutral,
      ),
    ];
  }

  List<_Row> _variantPricingTaxRows() {
    final rows = buildVariantPricingRows(state: state);
    final status = deriveVariantPricingStatus(rows);
    final currency = _currencyCode();
    return [
      _Row('Total Variants', '${status.total}'),
      _Row('Priced Variants', '${status.priced} / ${status.total}'),
      _Row('Pending Variants', '${status.pending} / ${status.total}'),
      _Row('Price Range', status.priceRangeLabel(currency)),
      ..._taxRows(),
    ];
  }

  Widget? _variantPricingSummary() {
    final rows = buildVariantPricingRows(state: state);
    if (rows.isEmpty) return null;
    final status = deriveVariantPricingStatus(rows);
    final currency = _currencyCode();
    final suffix = currency.isEmpty ? '' : ' $currency';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CompletionBar(
          label: 'Variants with Price',
          complete: status.priced,
          total: status.total,
        ),
        if (status.priced == status.total && status.total > 0) ...[
          const SizedBox(height: TenantAdminSpacing.md),
          const _SuccessBanner(
            message: 'All variants have standard selling price set.',
          ),
        ],
        const SizedBox(height: TenantAdminSpacing.md),
        const Text(
          'Variant Prices',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: TenantAdminColors.bodyText,
          ),
        ),
        const SizedBox(height: TenantAdminSpacing.sm),
        ...rows.map(
          (r) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    r.displayLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    (r.sku == null || r.sku!.isEmpty) ? '—' : r.sku!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: TenantAdminColors.mutedText,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    r.isPriced
                        ? '${_formatCurrency(r.sellingPrice!.toDouble())}$suffix'
                        : 'Pending',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: r.isPriced
                          ? TenantAdminColors.bodyText
                          : TenantAdminColors.warning,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Shared helpers
  // ---------------------------------------------------------------------------

  VoidCallback? _edit(int step) {
    final c = controller;
    if (c == null) return null;
    return () => c.goToStep(step);
  }

  List<GeneratedVariantRow> _includedVariants() {
    return state.step4State.generatedVariants
        .where((v) => v.isIncluded)
        .toList();
  }

  List<BarcodeSkuAssignmentDto> _variantAssignments() {
    return state.step5State.assignments;
  }

  Widget _identifierRow(BarcodeSkuAssignmentDto a) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              (a.displayName ?? '').trim().isEmpty ? '—' : a.displayName!.trim(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              (a.sku ?? '').trim().isEmpty ? '—' : a.sku!.trim(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                color: TenantAdminColors.mutedText,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              (a.barcode ?? '').trim().isEmpty ? '—' : a.barcode!.trim(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 11,
                color: TenantAdminColors.mutedText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _variantNameList(List<GeneratedVariantRow> included) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Included Variants',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: TenantAdminColors.bodyText,
          ),
        ),
        const SizedBox(height: TenantAdminSpacing.sm),
        ...included.map(
          (v) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              v.displayLabel ?? v.combinationLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: TenantAdminColors.bodyText,
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<_Row> _compatibleTrackingRows() {
    final plan = InitialTrackingCompatibility.evaluate(
      productStructure: state.productStructure,
      trackInventory: state.trackInventory,
      batchTracking: state.batchTracking,
      expiryTracking: state.expiryTracking,
      serialTracking: state.serialTracking,
      batch: state.initialBatchNumber,
      expiry: state.initialExpiryDate,
      serial: state.initialSerialNumber,
    );
    final rows = <_Row>[];
    if (plan.batchNumber != null && plan.batchNumber!.isNotEmpty) {
      rows.add(_Row('Initial Batch Number', plan.batchNumber!));
    }
    if (plan.expiryDate != null) {
      final d = plan.expiryDate!;
      rows.add(_Row(
        'Initial Expiry Date',
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}',
      ));
    }
    if (plan.serialNumber != null && plan.serialNumber!.isNotEmpty) {
      rows.add(_Row('Initial Serial Number', plan.serialNumber!));
    }
    return rows;
  }

  Widget? _variantAssignment() {
    final included = _includedVariants();
    if (included.isEmpty) return null;
    final keys = included
        .map((v) => v.productVariantId ?? v.clientCombinationKey)
        .toSet();
    final assignedId = state.initialTrackingAssignedVariantId;
    final assignedInList =
        assignedId != null && assignedId.isNotEmpty && keys.contains(assignedId);
    String? assignedLabel;
    if (assignedInList) {
      for (final v in included) {
        final key = v.productVariantId ?? v.clientCombinationKey;
        if (key == assignedId) {
          assignedLabel = v.displayLabel ?? v.combinationLabel;
          break;
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildInlineRow(
          'Assigned Tracking Variant',
          assignedLabel ?? 'Not assigned',
        ),
        if (controller != null) ...[
          const SizedBox(height: TenantAdminSpacing.sm),
          DropdownButtonFormField<String>(
            value: assignedInList ? assignedId : null,
            decoration: const InputDecoration(
              isDense: true,
              labelText: 'Assign tracking to variant',
            ),
            items: included
                .map(
                  (v) => DropdownMenuItem(
                    value: v.productVariantId ?? v.clientCombinationKey,
                    child: Text(v.displayLabel ?? v.combinationLabel),
                  ),
                )
                .toList(),
            onChanged: (value) =>
                controller!.setInitialTrackingAssignedVariantId(value),
          ),
        ],
      ],
    );
  }

  Widget _buildInlineRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: TenantAdminSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: TenantAdminColors.mutedText,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
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

  Widget _imagesContent() {
    if (state.productImages.isEmpty) {
      return const Text(
        'No images added.',
        style: TextStyle(color: TenantAdminColors.mutedText, fontSize: 13),
      );
    }
    return Wrap(
      spacing: TenantAdminSpacing.sm,
      runSpacing: TenantAdminSpacing.sm,
      children: [
        ...state.productImages.take(5).map(_buildImageThumbnail),
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
                const Icon(Icons.cloud_upload_outlined,
                    size: 20, color: TenantAdminColors.info),
                const SizedBox(height: 4),
                Text(
                  '+${state.productImages.length - 5} More',
                  style: const TextStyle(
                    fontSize: 10,
                    color: TenantAdminColors.info,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  String _unitLabel(String? unitId) {
    if (unitId == null || unitId.isEmpty || state.createOptions == null) {
      return '—';
    }
    try {
      final unit = state.createOptions!.units.firstWhere((u) => u.id == unitId);
      return '${unit.name} (${unit.code})';
    } catch (_) {
      return unitId;
    }
  }

  String _currencyCode() {
    final code = state.createOptions?.currencyCode.trim() ?? '';
    return code.toUpperCase();
  }

  String _categoryLabel() {
    final options = state.createOptions;
    if (options == null || state.categoryId == null) return '—';
    try {
      final cat = options.categories.firstWhere((c) => c.id == state.categoryId);
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

  String _statusLabel() {
    if (state.status.trim().isEmpty) {
      return state.desiredPublishActive ? 'Active' : 'Inactive';
    }
    return state.status;
  }

  _BadgeTone _statusTone() {
    final label = _statusLabel().toUpperCase();
    if (label == 'ACTIVE') return _BadgeTone.positive;
    if (label == 'INACTIVE') return _BadgeTone.negative;
    return _BadgeTone.neutral;
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
    return amount.toStringAsFixed(2).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
  }

  String _formatNumber(num val) {
    if (val % 1 == 0) return val.toInt().toString();
    return val.toString();
  }

  String _dash(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? '—' : trimmed;
  }

  Widget _buildImageThumbnail(ProductWizardImageItem img) {
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
                ? Image.memory(img.bytes!, fit: BoxFit.cover)
                : (img.imageUrl.isNotEmpty
                    ? Image.network(img.imageUrl, fit: BoxFit.cover)
                    : const Icon(Icons.image,
                        color: TenantAdminColors.mutedText)),
          ),
          if (img.isPrimary)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(TenantAdminRadius.md - 1),
                    bottomRight: Radius.circular(TenantAdminRadius.md - 1),
                  ),
                ),
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: const Text(
                  'Primary',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ReviewCardGrid extends StatelessWidget {
  const _ReviewCardGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final cols = width >= TenantAdminBreakpoints.desktop
            ? 3
            : width >= TenantAdminBreakpoints.smallTablet
                ? 2
                : 1;
        const gap = TenantAdminSpacing.lg;
        final cardWidth =
            cols == 1 ? width : (width - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final child in children)
              SizedBox(width: cardWidth, child: child),
          ],
        );
      },
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
    this.onEdit,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final List<_Row> rows;
  final Widget? customContent;
  final VoidCallback? onEdit;

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
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit'),
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    foregroundColor: TenantAdminColors.info,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: TenantAdminColors.border),
          Padding(
            padding: const EdgeInsets.all(TenantAdminSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ...rows.map(_buildRow),
                if (customContent != null) ...[
                  if (rows.isNotEmpty)
                    const SizedBox(height: TenantAdminSpacing.sm),
                  customContent!,
                ],
              ],
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
            child: r.badge != null
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: _buildStatusBadge(r.value, r.badge!),
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

  Widget _buildStatusBadge(String text, _BadgeTone tone) {
    late final Color color;
    switch (tone) {
      case _BadgeTone.positive:
        color = TenantAdminColors.success;
        break;
      case _BadgeTone.negative:
        color = TenantAdminColors.danger;
        break;
      case _BadgeTone.neutral:
        color = TenantAdminColors.mutedText;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _CompletionBar extends StatelessWidget {
  const _CompletionBar({
    required this.label,
    required this.complete,
    required this.total,
  });

  final String label;
  final int complete;
  final int total;

  @override
  Widget build(BuildContext context) {
    final ratio = total <= 0 ? 0.0 : (complete / total).clamp(0.0, 1.0);
    final done = total > 0 && complete >= total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: TenantAdminColors.mutedText,
                ),
              ),
            ),
            Text(
              '$complete of $total',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: done
                    ? TenantAdminColors.success
                    : TenantAdminColors.bodyText,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 8,
            backgroundColor: TenantAdminColors.border,
            color: done ? TenantAdminColors.success : TenantAdminColors.warning,
          ),
        ),
      ],
    );
  }
}

class _SuccessBanner extends StatelessWidget {
  const _SuccessBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(TenantAdminSpacing.sm),
      decoration: BoxDecoration(
        color: TenantAdminColors.successSurface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        border: Border.all(color: TenantAdminColors.successBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle,
              size: 16, color: TenantAdminColors.success),
          const SizedBox(width: TenantAdminSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 12,
                color: TenantAdminColors.success,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _BadgeTone { positive, negative, neutral }

class _Row {
  const _Row(this.label, this.value, {this.badge});
  final String label;
  final String value;
  final _BadgeTone? badge;
}
