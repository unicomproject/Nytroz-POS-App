import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_buttons.dart';
import '../../domain/entities/product_form_data.dart';
import '../../domain/entities/tenant_product_create_options.dart';
import '../../domain/entities/tenant_product_detail.dart';
import '../dashboard/product_dashboard_providers.dart';
import '../providers/tenant_product_providers.dart';
import '../utils/product_api_errors.dart';
import '../utils/product_form_validation.dart';
import 'product_form_fields.dart';

class ProductDetailForm extends ConsumerStatefulWidget {
  const ProductDetailForm({
    super.key,
    required this.productId,
    required this.detail,
    required this.fieldsEnabled,
    required this.canSave,
    this.options,
  });

  final String productId;
  final TenantProductDetail detail;
  final bool fieldsEnabled;
  final bool canSave;
  final TenantProductCreateOptions? options;

  @override
  ConsumerState<ProductDetailForm> createState() => _ProductDetailFormState();
}

class _ProductDetailFormState extends ConsumerState<ProductDetailForm> {
  final _nameController = TextEditingController();
  final _skuController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _costPriceController = TextEditingController();
  final _discountPriceController = TextEditingController();
  final _openingStockController = TextEditingController();
  final _lowStockController = TextEditingController();
  final _onHandController = TextEditingController();
  final _availableStockController = TextEditingController();
  final _variantsController = TextEditingController();

  var _trackStock = false;
  var _inStorePos = true;
  var _onlineStore = true;
  late String _productStatus;
  late String _stockStatus;

  String? _categoryId;
  String? _subCategoryId;
  String? _brandId;
  String? _unitId;
  String? _taxId;
  final _selectedOutletIds = <String>{};
  var _submitting = false;
  Map<String, String> _fieldErrors = const {};

  bool get _useDropdowns => widget.fieldsEnabled && widget.options != null;
  bool get _inputsEnabled => widget.fieldsEnabled && !_submitting;

  @override
  void initState() {
    super.initState();
    _productStatus = widget.detail.status;
    _stockStatus = _calculateStockStatus(widget.detail);
    _syncFromDetail(widget.detail, widget.options);
  }

  @override
  void didUpdateWidget(covariant ProductDetailForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.detail.productId != widget.detail.productId ||
        oldWidget.options != widget.options) {
      _productStatus = widget.detail.status;
      _stockStatus = _calculateStockStatus(widget.detail);
      _syncFromDetail(widget.detail, widget.options);
    }
  }

  String _calculateStockStatus(TenantProductDetail detail) {
    if (!detail.trackInventory || detail.stock == null) {
      return 'NOT_TRACKED';
    }
    final onHand = detail.stock!.onHandQuantity;
    final minAlert = detail.stock!.minimumStockAlertQuantity;

    if (onHand <= 0) {
      return 'OUT_OF_STOCK';
    } else if (minAlert != null && onHand <= minAlert) {
      return 'LOW_STOCK';
    }
    return 'IN_STOCK';
  }

  void _syncFromDetail(
    TenantProductDetail detail,
    TenantProductCreateOptions? options,
  ) {
    _nameController.text = detail.productName;
    _skuController.text = detail.sku;
    _barcodeController.text = detail.barcode ?? '';
    _descriptionController.text = detail.shortDescription ?? '';
    _priceController.text = _formatNumber(detail.sellingPrice);
    _costPriceController.text =
        detail.costPrice == null ? '' : _formatNumber(detail.costPrice!);
    _discountPriceController.text = detail.discountPrice == null
        ? ''
        : _formatNumber(detail.discountPrice!);
    _openingStockController.text = detail.stock?.openingStockQuantity == null
        ? ''
        : _formatNumber(detail.stock!.openingStockQuantity!);
    _lowStockController.text = detail.stock?.minimumStockAlertQuantity == null
        ? ''
        : _formatNumber(detail.stock!.minimumStockAlertQuantity!);
    _onHandController.text =
        detail.stock == null ? '' : _formatNumber(detail.stock!.onHandQuantity);
    _availableStockController.text = detail.stock == null
        ? ''
        : _formatNumber(detail.stock!.availableQuantity);
    _variantsController.text = detail.variants.length.toString();

    _trackStock = detail.trackInventory;
    _categoryId = detail.categoryId;
    _subCategoryId = detail.subCategoryId;
    _brandId = detail.brandId;
    _taxId = detail.taxId;
    _unitId = options == null ? null : unitIdForCode(options, detail.unitType);
    _selectedOutletIds
      ..clear()
      ..addAll(detail.outlets.map((item) => item.outletId));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _barcodeController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _costPriceController.dispose();
    _discountPriceController.dispose();
    _openingStockController.dispose();
    _lowStockController.dispose();
    _onHandController.dispose();
    _availableStockController.dispose();
    _variantsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= TenantAdminBreakpoints.desktop;
    final isTablet = width >= TenantAdminBreakpoints.tablet &&
        width < TenantAdminBreakpoints.desktop;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Row 1: Product Image + Basic Details Card
          if (isDesktop || isTablet)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: isDesktop ? 280 : 240,
                  child: _buildProductImageEditCard(),
                ),
                const SizedBox(width: TenantAdminSpacing.lg),
                Expanded(
                  child: _buildBasicDetailsEditCard(context),
                ),
              ],
            )
          else ...[
            _buildProductImageEditCard(),
            const SizedBox(height: TenantAdminSpacing.lg),
            _buildBasicDetailsEditCard(context),
          ],

          const SizedBox(height: TenantAdminSpacing.lg),

          // Row 2: Inventory & Pricing + Channel Visibility Card
          if (isDesktop || isTablet)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: _buildInventoryPricingEditCard(context),
                ),
                const SizedBox(width: TenantAdminSpacing.lg),
                Expanded(
                  flex: 3,
                  child: _buildChannelVisibilityEditCard(),
                ),
              ],
            )
          else ...[
            _buildInventoryPricingEditCard(context),
            const SizedBox(height: TenantAdminSpacing.lg),
            _buildChannelVisibilityEditCard(),
          ],

          const SizedBox(height: TenantAdminSpacing.lg),

          // Row 3: Product Summary (Audit Info)
          _buildAuditSummaryEditCard(widget.detail),

          const SizedBox(height: TenantAdminSpacing.xl),

          // Bottom Action Bar: Cancel & Save Changes
          if (widget.canSave)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: _submitting
                      ? null
                      : () => context.go('/tenant-admin/products'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    side: const BorderSide(color: TenantAdminColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(TenantAdminRadius.md),
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
                TenantAdminPrimaryButton(
                  label: _submitting ? 'Saving...' : 'Save Changes',
                  loading: _submitting,
                  backgroundColor: const Color(0xFFFF5200),
                  onPressed: _inputsEnabled ? _saveChanges : null,
                ),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _saveChanges() async {
    if (_submitting || !widget.canSave) {
      return;
    }

    final options = widget.options;
    if (options == null) {
      return;
    }

    final unitCode = unitCodeForId(options, _unitId);
    final errors = validateProductUpdateForm(
      productName: _nameController.text,
      sku: _skuController.text,
      barcode: _barcodeController.text,
      categoryId: _categoryId,
      unitCode: unitCode,
      sellingPriceText: _priceController.text,
      costPriceText: _costPriceController.text,
      discountPriceText: _discountPriceController.text,
      trackInventory: _trackStock,
      openingStockText: _openingStockController.text,
      minimumStockText: _lowStockController.text,
      selectedOutletIds: _selectedOutletIds,
    );

    if (errors.isNotEmpty) {
      setState(() => _fieldErrors = errors);
      return;
    }

    final sellingPrice = double.parse(_priceController.text.trim());
    final costPrice = _parseOptionalDecimal(_costPriceController.text);
    final discountPrice = _parseOptionalDecimal(_discountPriceController.text);
    final detail = widget.detail;
    final hasVariants = detail.variants.isNotEmpty;
    final batch = detail.batchDetails;

    setState(() {
      _submitting = true;
      _fieldErrors = const {};
    });

    final request = ProductFormData(
      productName: _nameController.text.trim(),
      sku: _skuController.text.trim(),
      barcode: _barcodeController.text.trim().isEmpty
          ? null
          : _barcodeController.text.trim(),
      categoryId: _categoryId!,
      subCategoryId: _subCategoryId,
      brandId: _brandId,
      unitType: unitCode!,
      shortDescription: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      sellingPrice: sellingPrice,
      taxId: _taxId,
      costPrice: costPrice,
      discountPrice: discountPrice,
      trackInventory: _trackStock,
      openingStockQuantity: _trackStock
          ? double.tryParse(_openingStockController.text.trim())
          : null,
      minimumStockAlertQuantity:
          _trackStock ? double.tryParse(_lowStockController.text.trim()) : null,
      maximumStockQuantity:
          _trackStock ? detail.stock?.maximumStockQuantity : null,
      stockUnit: _trackStock ? unitCode : null,
      outletIds:
          _trackStock ? _selectedOutletIds.toList(growable: false) : const [],
      hasVariants: hasVariants,
      variants: hasVariants
          ? detail.variants
              .map(
                (variant) => ProductVariantFormData(
                  variantName: variant.variantName,
                  sku: variant.sku,
                  barcode: variant.barcode,
                  sellingPrice: variant.sellingPrice,
                  discountPrice: variant.discountPrice,
                  status: variant.status,
                ),
              )
              .toList()
          : const [],
      hasExpiryDate: batch != null,
      batchNumber: batch?.batchNumber,
      manufactureDate: batch?.manufactureDate,
      expiryDate: batch?.expiryDate,
      expiryAlertDays: batch?.expiryAlertDays,
      status: _normalizeStatus(detail.status),
    );

    try {
      await ref.read(updateProductProvider).call(
            productId: widget.productId,
            request: request,
          );

      ref
        ..invalidate(productDetailProvider(widget.productId))
        ..invalidate(productListProvider)
        ..invalidate(productSummaryProvider)
        ..invalidate(productDashboardProvider);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product updated successfully.')),
      );
      context.go('/tenant-admin/products');
    } on DioException catch (error) {
      if (!mounted) {
        return;
      }

      final fieldErrors = productValidationErrors(error);
      if (fieldErrors.isNotEmpty) {
        setState(() {
          _fieldErrors = fieldErrors;
          _submitting = false;
        });
        return;
      }

      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            productSubmitErrorMessage(
              error,
              fallback: 'Failed to update product. Please try again.',
            ),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update product. Please try again.'),
        ),
      );
    }
  }

  double? _parseOptionalDecimal(String value) {
    if (value.trim().isEmpty) {
      return null;
    }

    return double.tryParse(value.trim());
  }

  String _normalizeStatus(String status) {
    final normalized = status.trim().toUpperCase();
    if (normalized == 'INACTIVE') {
      return 'INACTIVE';
    }

    return 'ACTIVE';
  }

  Widget _buildProductImageEditCard() {
    return _SectionCard(
      title: 'Product Image',
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 1.1,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAFA),
                borderRadius: BorderRadius.circular(TenantAdminRadius.md),
                border: Border.all(color: TenantAdminColors.border),
              ),
              child: widget.detail.imageUrl != null &&
                      widget.detail.imageUrl!.trim().isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(TenantAdminRadius.md),
                      child: Image.network(
                        widget.detail.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildPlaceholderImage(),
                      ),
                    )
                  : _buildPlaceholderImage(),
            ),
          ),
          const SizedBox(height: TenantAdminSpacing.md),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _inputsEnabled ? () {} : null,
              icon: const Icon(Icons.upload_outlined, size: 18),
              label: const Text(
                'Upload / Replace Image',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                foregroundColor: TenantAdminColors.bodyText,
                side: const BorderSide(color: TenantAdminColors.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(TenantAdminRadius.md),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: TenantAdminColors.secondary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.checkroom_outlined,
              size: 36,
              color: TenantAdminColors.primary,
            ),
          ),
          const SizedBox(height: TenantAdminSpacing.sm),
          Text(
            widget.detail.productName,
            style: const TextStyle(
              color: TenantAdminColors.mutedText,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildBasicDetailsEditCard(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final crossAxisCount = width >= TenantAdminBreakpoints.desktop
        ? 3
        : width >= TenantAdminBreakpoints.smallTablet
            ? 2
            : 1;

    final options = widget.options;

    final basicFields = [
      ProductFormTextField(
        label: 'Product name *',
        hint: 'Enter product name',
        icon: Icons.inventory_2_outlined,
        controller: _nameController,
        enabled: _inputsEnabled,
        errorText: _fieldErrors['productName'],
      ),
      ProductFormTextField(
        label: 'Product code / SKU *',
        hint: 'Enter SKU',
        icon: Icons.qr_code_2_outlined,
        controller: _skuController,
        enabled: _inputsEnabled,
        errorText: _fieldErrors['sku'],
      ),
      ProductFormTextField(
        label: 'Short description',
        hint: 'Add a short description',
        icon: Icons.notes_outlined,
        controller: _descriptionController,
        enabled: _inputsEnabled,
      ),
      _useDropdowns
          ? ProductOptionDropdown(
              label: 'Category *',
              hint: 'Select category',
              icon: Icons.category_outlined,
              value: _categoryId,
              enabled: _inputsEnabled,
              errorText: _fieldErrors['categoryId'],
              items: buildOptionItems(
                options: options!.categories
                    .map((item) => (id: item.id, label: item.name))
                    .toList(),
                emptyLabel: 'No categories available',
              ),
              onChanged: (value) {
                setState(() {
                  _categoryId = value;
                  _subCategoryId = null;
                });
              },
            )
          : ProductReadOnlyField(
              label: 'Category *',
              value: widget.detail.categoryName,
              icon: Icons.category_outlined,
            ),
      _useDropdowns
          ? ProductOptionDropdown(
              label: 'Brand *',
              hint: 'Select brand',
              icon: Icons.sell_outlined,
              value: _brandId,
              enabled: _inputsEnabled,
              errorText: _fieldErrors['brandId'],
              items: buildOptionItems(
                options: options!.brands
                    .map((item) => (id: item.id, label: item.name))
                    .toList(),
                emptyLabel: 'No brands available',
              ),
              onChanged: (value) => setState(() => _brandId = value),
            )
          : ProductReadOnlyField(
              label: 'Brand *',
              value: _displayLabel(
                _brandId,
                options?.brands
                        .map((item) => (id: item.id, label: item.name))
                        .toList() ??
                    const [],
              ),
              icon: Icons.sell_outlined,
            ),
      ProductFormTextField(
        label: 'Barcode',
        hint: 'Enter barcode',
        icon: Icons.barcode_reader,
        controller: _barcodeController,
        enabled: _inputsEnabled,
        errorText: _fieldErrors['barcode'],
      ),
      _useDropdowns
          ? ProductOptionDropdown(
              label: 'Variants *',
              hint: 'Select variant',
              icon: Icons.published_with_changes_outlined,
              value: _variantsController.text,
              enabled: _inputsEnabled,
              items: [
                DropdownMenuItem(
                  value: _variantsController.text,
                  child: Text(_variantsController.text),
                ),
              ],
              onChanged: (v) {},
            )
          : ProductReadOnlyField(
              label: 'Variants *',
              value: _variantsController.text,
              icon: Icons.published_with_changes_outlined,
            ),
      _useDropdowns
          ? ProductOptionDropdown(
              label: 'Unit Type *',
              hint: 'Select unit type',
              icon: Icons.straighten_outlined,
              value: _unitId,
              enabled: _inputsEnabled,
              errorText: _fieldErrors['unitType'],
              items: buildOptionItems(
                options: options!.units
                    .map((item) => (id: item.id, label: item.name))
                    .toList(),
                emptyLabel: 'No units available',
              ),
              onChanged: (value) => setState(() => _unitId = value),
            )
          : ProductReadOnlyField(
              label: 'Unit Type *',
              value: widget.detail.unitType,
              icon: Icons.straighten_outlined,
            ),
    ];

    return _SectionCard(
      title: 'Basic Details',
      child: LayoutBuilder(
        builder: (context, constraints) {
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: TenantAdminSpacing.md,
              mainAxisSpacing: TenantAdminSpacing.md,
              mainAxisExtent: 76,
            ),
            itemCount: basicFields.length,
            itemBuilder: (context, index) => basicFields[index],
          );
        },
      ),
    );
  }

  Widget _buildInventoryPricingEditCard(BuildContext context) {
    return _SectionCard(
      title: 'Inventory & Pricing',
      child: GridView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: TenantAdminSpacing.md,
          mainAxisSpacing: TenantAdminSpacing.md,
          mainAxisExtent: 76,
        ),
        children: [
          ProductFormTextField(
            label: 'Price *',
            hint: 'LKR 2,500.00',
            icon: Icons.attach_money_outlined,
            controller: _priceController,
            enabled: _inputsEnabled,
            keyboardType: TextInputType.number,
            errorText: _fieldErrors['sellingPrice'],
          ),
          ProductFormTextField(
            label: 'Stock *',
            hint: '0',
            icon: Icons.inventory_outlined,
            controller: _onHandController.text.isNotEmpty
                ? _onHandController
                : _openingStockController,
            enabled: _inputsEnabled && _trackStock,
            keyboardType: TextInputType.number,
            errorText: _fieldErrors['openingStockQuantity'],
          ),
          ProductOptionDropdown(
            label: 'Product Status *',
            hint: 'Select status',
            icon: Icons.check_circle_outline,
            value: _productStatus,
            enabled: _inputsEnabled,
            items: const [
              DropdownMenuItem(value: 'ACTIVE', child: Text('Active')),
              DropdownMenuItem(value: 'INACTIVE', child: Text('Inactive')),
            ],
            onChanged: (val) {
              if (val != null) {
                setState(() => _productStatus = val);
              }
            },
          ),
          ProductOptionDropdown(
            label: 'Stock Status *',
            hint: 'Select stock status',
            icon: Icons.inventory_2_outlined,
            value: _stockStatus,
            enabled: _inputsEnabled,
            items: const [
              DropdownMenuItem(value: 'IN_STOCK', child: Text('In Stock')),
              DropdownMenuItem(value: 'LOW_STOCK', child: Text('Low Stock')),
              DropdownMenuItem(
                  value: 'OUT_OF_STOCK', child: Text('Out of Stock')),
              DropdownMenuItem(
                  value: 'NOT_TRACKED', child: Text('Not Tracked')),
            ],
            onChanged: (val) {
              if (val != null) {
                setState(() => _stockStatus = val);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildChannelVisibilityEditCard() {
    final isDesktop =
        MediaQuery.sizeOf(context).width >= TenantAdminBreakpoints.desktop;

    return _SectionCard(
      title: 'Channel Visibility',
      child: isDesktop
          ? Row(
              children: [
                Expanded(
                  child: _buildChannelEditItem(
                    icon: Icons.storefront_outlined,
                    title: 'In-Store POS',
                    subtitle: 'This product is available in the in-store POS.',
                    value: _inStorePos,
                    onChanged: (val) => setState(() => _inStorePos = val),
                  ),
                ),
                const SizedBox(width: TenantAdminSpacing.md),
                Expanded(
                  child: _buildChannelEditItem(
                    icon: Icons.shopping_cart_outlined,
                    title: 'Online Store',
                    subtitle: 'This product is visible on the online store.',
                    value: _onlineStore,
                    onChanged: (val) => setState(() => _onlineStore = val),
                  ),
                ),
              ],
            )
          : Column(
              children: [
                _buildChannelEditItem(
                  icon: Icons.storefront_outlined,
                  title: 'In-Store POS',
                  subtitle: 'This product is available in the in-store POS.',
                  value: _inStorePos,
                  onChanged: (val) => setState(() => _inStorePos = val),
                ),
                const SizedBox(height: TenantAdminSpacing.md),
                _buildChannelEditItem(
                  icon: Icons.shopping_cart_outlined,
                  title: 'Online Store',
                  subtitle: 'This product is visible on the online store.',
                  value: _onlineStore,
                  onChanged: (val) => setState(() => _onlineStore = val),
                ),
              ],
            ),
    );
  }

  Widget _buildChannelEditItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(TenantAdminSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        border: Border.all(color: TenantAdminColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: TenantAdminColors.bodyText),
              const SizedBox(width: TenantAdminSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: TenantAdminColors.bodyText,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Switch(
                value: value,
                activeTrackColor: TenantAdminColors.success,
                onChanged: _inputsEnabled ? onChanged : null,
              ),
            ],
          ),
          const SizedBox(height: TenantAdminSpacing.xs),
          Text(
            subtitle,
            style: const TextStyle(
              color: TenantAdminColors.mutedText,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuditSummaryEditCard(TenantProductDetail detail) {
    final dateFormat = DateFormat('MMM dd, yyyy hh:mm a');
    final createdStr = dateFormat.format(detail.createdAt);
    final updatedStr = dateFormat.format(detail.updatedAt);

    return _SectionCard(
      title: 'Product Summary (Audit Info)',
      child: Row(
        children: [
          Expanded(
            child: _AuditTile(
              icon: Icons.calendar_today_outlined,
              label: 'Created date',
              value: createdStr,
            ),
          ),
          const SizedBox(width: TenantAdminSpacing.md),
          const Expanded(
            child: _AuditTile(
              icon: Icons.person_outline,
              label: 'Added by',
              value: 'John Perera',
            ),
          ),
          const SizedBox(width: TenantAdminSpacing.md),
          Expanded(
            child: _AuditTile(
              icon: Icons.calendar_month_outlined,
              label: 'Last updated',
              value: updatedStr,
            ),
          ),
        ],
      ),
    );
  }

  String _displayLabel(
    String? id,
    List<({String id, String label})> options,
  ) {
    if (id == null) {
      return '-';
    }

    return labelForId(id, options) ?? '-';
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value.toString();
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
        border: Border.all(color: TenantAdminColors.border),
      ),
      padding: const EdgeInsets.all(TenantAdminSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: TenantAdminColors.bodyText,
            ),
          ),
          const SizedBox(height: TenantAdminSpacing.lg),
          child,
        ],
      ),
    );
  }
}

class _AuditTile extends StatelessWidget {
  const _AuditTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: TenantAdminColors.mutedText),
        const SizedBox(width: TenantAdminSpacing.md),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: TenantAdminColors.mutedText,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                color: TenantAdminColors.bodyText,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class ProductReadOnlyField extends StatelessWidget {
  const ProductReadOnlyField({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: TenantAdminColors.bodyText,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: TenantAdminSpacing.sm),
        InputDecorator(
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 19),
            filled: true,
            fillColor: TenantAdminColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TenantAdminRadius.md),
              borderSide: const BorderSide(color: TenantAdminColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TenantAdminRadius.md),
              borderSide: const BorderSide(color: TenantAdminColors.border),
            ),
          ),
          child: Text(
            value.isEmpty ? '-' : value,
            style: const TextStyle(color: TenantAdminColors.bodyText),
          ),
        ),
      ],
    );
  }
}
