import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../../core/network/dio_provider.dart';
import '../../../../../core/network/media_url_resolver.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_buttons.dart';
import '../../domain/entities/product_form_data.dart';
import '../../domain/entities/tenant_product_create_options.dart';
import '../../domain/entities/tenant_product_detail.dart';
import '../dashboard/product_dashboard_providers.dart';
import '../providers/tenant_product_providers.dart';
import '../utils/product_api_errors.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/widgets/tenant_admin_toast.dart';
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
  final _productCodeController = TextEditingController();
  final _skuController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _longDescriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _costPriceController = TextEditingController();
  final _discountPriceController = TextEditingController();
  final _openingStockController = TextEditingController();
  final _lowStockController = TextEditingController();
  final _variantsController = TextEditingController();

  var _trackStock = false;
  var _inStorePos = true;
  var _onlineStore = true;

  String? _categoryId;
  String? _subCategoryId;
  String? _brandId;
  String? _unitId;
  String? _taxId;
  final _selectedOutletIds = <String>{};
  var _submitting = false;
  var _uploadingImage = false;
  String? _overrideImageUrl;
  Map<String, String> _fieldErrors = const {};

  bool get _useDropdowns => widget.fieldsEnabled && widget.options != null;
  bool get _inputsEnabled => widget.fieldsEnabled && !_submitting;

  @override
  void initState() {
    super.initState();
    _syncFromDetail(widget.detail, widget.options);
  }

  @override
  void didUpdateWidget(covariant ProductDetailForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.detail.productId != widget.detail.productId ||
        oldWidget.options != widget.options) {
      _syncFromDetail(widget.detail, widget.options);
    }
  }

  void _syncFromDetail(
    TenantProductDetail detail,
    TenantProductCreateOptions? options,
  ) {
    _nameController.text = detail.productName;
    _productCodeController.text = detail.productCode;
    _skuController.text = detail.sku;
    _barcodeController.text = detail.barcode ?? '';
    _descriptionController.text = detail.shortDescription ?? '';
    _longDescriptionController.text = detail.longDescription ?? '';
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
    _productCodeController.dispose();
    _skuController.dispose();
    _barcodeController.dispose();
    _descriptionController.dispose();
    _longDescriptionController.dispose();
    _priceController.dispose();
    _costPriceController.dispose();
    _discountPriceController.dispose();
    _openingStockController.dispose();
    _lowStockController.dispose();
    _variantsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= TenantAdminBreakpoints.tablet;
        const gap = TenantAdminSpacing.md;
        final isDesktop =
            constraints.maxWidth >= TenantAdminBreakpoints.desktop;
        final imageWidth = isDesktop ? 240.0 : 200.0;

        if (!isWide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildProductImageEditCard(compact: true),
              const SizedBox(height: gap),
              _buildBasicDetailsEditCard(compact: true),
              const SizedBox(height: gap),
              _buildPricingSummaryEditCard(compact: true),
              const SizedBox(height: gap),
              _buildVariantSummaryEditCard(compact: true),
              const SizedBox(height: gap),
              _buildAuditSummaryEditCard(widget.detail, compact: true),
              if (widget.canSave) ...[
                const SizedBox(height: TenantAdminSpacing.xl),
                _buildSaveActions(),
              ],
            ],
          );
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: imageWidth,
                  child: _buildProductImageEditCard(compact: true),
                ),
                const SizedBox(width: gap),
                Expanded(
                  child: _buildBasicDetailsEditCard(compact: true),
                ),
              ],
            ),
            const SizedBox(height: gap),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _buildPricingSummaryEditCard(
                      compact: true,
                      stretch: true,
                    ),
                  ),
                  const SizedBox(width: gap),
                  Expanded(
                    child: _buildVariantSummaryEditCard(
                      compact: true,
                      stretch: true,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: gap),
            _buildAuditSummaryEditCard(widget.detail, compact: true),
            if (widget.canSave) ...[
              const SizedBox(height: TenantAdminSpacing.xl),
              _buildSaveActions(),
            ],
          ],
        );
      },
    );
  }

  Widget _buildSaveActions() {
    return Row(
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
          backgroundColor: TenantAdminColors.primary,
          onPressed: _inputsEnabled ? _saveChanges : null,
        ),
      ],
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
      productCode: _productCodeController.text,
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

    final trimmedBarcode = _barcodeController.text.trim();
    final trimmedSku = _skuController.text.trim();

    final request = ProductFormData(
      productName: _nameController.text.trim(),
      productCode: _productCodeController.text.trim(),
      sku: trimmedSku,
      barcode: trimmedBarcode.isEmpty ? null : trimmedBarcode,
      categoryId: _categoryId!,
      subCategoryId: _subCategoryId,
      brandId: _brandId,
      unitType: unitCode!,
      shortDescription: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      longDescription: _longDescriptionController.text.trim().isEmpty
          ? null
          : _longDescriptionController.text.trim(),
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
              .asMap()
              .entries
              .map(
                (entry) {
                  final variant = entry.value;
                  final isDefault = entry.key == 0;
                  return ProductVariantFormData(
                    variantName: variant.variantName,
                    sku: isDefault ? trimmedSku : variant.sku,
                    barcode: isDefault
                        ? (trimmedBarcode.isEmpty ? null : trimmedBarcode)
                        : variant.barcode,
                    sellingPrice: variant.sellingPrice,
                    discountPrice: variant.discountPrice,
                    status: variant.status,
                  );
                },
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

      showProductSaveToast(
        context,
        title: 'Product Updated',
        message: 'Product updated successfully.',
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

  String _resolveImageUrl(String rawUrl) {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) return trimmed;
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    final baseUrl = ref.read(appDioProvider).options.baseUrl;
    return MediaUrlResolver.resolve(trimmed, apiBaseUrl: baseUrl) ?? trimmed;
  }

  Future<void> _uploadOrReplaceImage() async {
    if (_uploadingImage) return;

    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(source: ImageSource.gallery);
      if (file == null) return;

      final bytes = await file.readAsBytes();
      if (bytes.length > 5242880) {
        if (mounted) {
          showAppToast(
            context,
            message: 'Image file size exceeds maximum limit of 5MB.',
            type: AppToastType.error,
          );
        }
        return;
      }

      final fileName = file.name;
      String mimeType = file.mimeType ?? '';
      if (mimeType.isEmpty || mimeType == 'application/octet-stream') {
        final lower = fileName.toLowerCase();
        if (lower.endsWith('.png')) {
          mimeType = 'image/png';
        } else if (lower.endsWith('.webp')) {
          mimeType = 'image/webp';
        } else {
          mimeType = 'image/jpeg';
        }
      }

      if (mounted) {
        setState(() {
          _uploadingImage = true;
        });
      }

      final uploadedDto =
          await ref.read(tenantProductRepositoryProvider).uploadProductImage(
                widget.productId,
                bytes,
                fileName,
                mimeType,
              );

      if (mounted) {
        setState(() {
          _overrideImageUrl = uploadedDto.imageUrl;
        });
      }

      ref.invalidate(productDetailProvider(widget.productId));
      ref.invalidate(productListProvider);

      if (mounted) {
        showAppToast(
          context,
          message: 'Product image uploaded successfully',
          type: AppToastType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        String msg = 'Failed to upload image';
        if (e is DioException) {
          final data = e.response?.data;
          if (data is Map && data['message'] != null) {
            msg = data['message'].toString();
          }
        }
        showAppToast(
          context,
          message: msg,
          type: AppToastType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _uploadingImage = false;
        });
      }
    }
  }

  Widget _buildProductImageEditCard({bool compact = false}) {
    final rawUrl = _overrideImageUrl ?? widget.detail.imageUrl;
    final displayUrl = (rawUrl != null && rawUrl.trim().isNotEmpty)
        ? _resolveImageUrl(rawUrl)
        : null;

    return _SectionCard(
      title: 'Product Image',
      compact: compact,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AspectRatio(
            aspectRatio: 1.1,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAFA),
                borderRadius: BorderRadius.circular(TenantAdminRadius.md),
                border: Border.all(color: TenantAdminColors.border),
              ),
              child: displayUrl != null && displayUrl.trim().isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(TenantAdminRadius.md),
                      child: Image.network(
                        displayUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildPlaceholderImage(),
                      ),
                    )
                  : _buildPlaceholderImage(),
            ),
          ),
          SizedBox(height: compact ? TenantAdminSpacing.sm : TenantAdminSpacing.md),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: (_inputsEnabled && !_uploadingImage)
                  ? _uploadOrReplaceImage
                  : null,
              icon: Icon(Icons.upload_outlined, size: compact ? 16 : 18),
              label: Text(
                'Upload / Replace Image',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: compact ? 12 : 13,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: compact ? 10 : 14),
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

  Widget _buildBasicDetailsEditCard({bool compact = false}) {
    final options = widget.options;

    final basicFields = <Widget>[
      ProductFormTextField(
        label: 'Product Code *',
        hint: 'Enter product code',
        icon: Icons.qr_code_2_outlined,
        controller: _productCodeController,
        enabled: _inputsEnabled,
        errorText: _fieldErrors['productCode'],
      ),
      ProductFormTextField(
        label: 'SKU *',
        hint: 'Enter SKU',
        icon: Icons.tag_outlined,
        controller: _skuController,
        enabled: _inputsEnabled,
        errorText: _fieldErrors['sku'],
      ),
      ProductFormTextField(
        label: 'Barcode',
        hint: 'Enter barcode',
        icon: Icons.barcode_reader,
        controller: _barcodeController,
        enabled: _inputsEnabled,
        errorText: _fieldErrors['barcode'],
      ),
      ProductFormTextField(
        label: 'Short description',
        hint: 'Add a short description',
        icon: Icons.notes_outlined,
        controller: _descriptionController,
        enabled: _inputsEnabled,
        maxLines: 2,
      ),
      ProductFormTextField(
        label: 'Long description',
        hint: 'Add detailed product description',
        icon: Icons.description_outlined,
        controller: _longDescriptionController,
        enabled: _inputsEnabled,
        maxLines: 3,
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
      _useDropdowns
          ? ProductOptionDropdown(
              label: 'Variants *',
              hint: 'Select variant',
              icon: Icons.published_with_changes_outlined,
              value: _variantsController.text,
              enabled: false,
              items: [
                DropdownMenuItem(
                  value: _variantsController.text,
                  child: Text(
                    _variantsController.text,
                    overflow: TextOverflow.ellipsis,
                  ),
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
      compact: compact,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          ProductFormTextField(
            label: 'Product name *',
            hint: 'Enter product name',
            icon: Icons.inventory_2_outlined,
            controller: _nameController,
            enabled: _inputsEnabled,
            errorText: _fieldErrors['productName'],
          ),
          SizedBox(height: compact ? TenantAdminSpacing.sm : TenantAdminSpacing.md),
          _EditFieldGrid(children: basicFields),
          SizedBox(height: compact ? TenantAdminSpacing.md : TenantAdminSpacing.lg),
          _buildChannelVisibilitySection(compact: compact),
        ],
      ),
    );
  }

  Widget _buildChannelVisibilitySection({bool compact = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Channel Visibility',
          style: TextStyle(
            fontSize: compact ? 12 : 13,
            fontWeight: FontWeight.w700,
            color: TenantAdminColors.bodyText,
          ),
        ),
        SizedBox(height: compact ? TenantAdminSpacing.sm : TenantAdminSpacing.md),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildChannelEditItem(
                icon: Icons.storefront_outlined,
                title: 'In-Store POS',
                value: _inStorePos,
                compact: compact,
                onChanged: (val) => setState(() => _inStorePos = val),
              ),
            ),
            SizedBox(width: compact ? TenantAdminSpacing.sm : TenantAdminSpacing.md),
            Expanded(
              child: _buildChannelEditItem(
                icon: Icons.shopping_cart_outlined,
                title: 'Online Store',
                value: _onlineStore,
                compact: compact,
                onChanged: (val) => setState(() => _onlineStore = val),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPricingSummaryEditCard({
    bool compact = false,
    bool stretch = false,
  }) {
    final options = widget.options;

    return _SectionCard(
      title: 'Pricing Summary',
      compact: compact,
      stretch: stretch,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: stretch ? MainAxisSize.max : MainAxisSize.min,
        children: [
          ProductFormTextField(
            label: 'Cost Price',
            hint: 'LKR 0.00',
            icon: Icons.attach_money_outlined,
            controller: _costPriceController,
            enabled: _inputsEnabled,
            keyboardType: TextInputType.number,
            errorText: _fieldErrors['costPrice'],
          ),
          SizedBox(height: compact ? TenantAdminSpacing.sm : TenantAdminSpacing.md),
          ProductFormTextField(
            label: 'Standard Selling Price *',
            hint: 'LKR 2,500.00',
            icon: Icons.sell_outlined,
            controller: _priceController,
            enabled: _inputsEnabled,
            keyboardType: TextInputType.number,
            errorText: _fieldErrors['sellingPrice'],
          ),
          SizedBox(height: compact ? TenantAdminSpacing.sm : TenantAdminSpacing.md),
          ProductFormTextField(
            label: 'Discount Price',
            hint: 'LKR 0.00',
            icon: Icons.local_offer_outlined,
            controller: _discountPriceController,
            enabled: _inputsEnabled,
            keyboardType: TextInputType.number,
            errorText: _fieldErrors['discountPrice'],
          ),
          if (_useDropdowns) ...[
            SizedBox(height: compact ? TenantAdminSpacing.sm : TenantAdminSpacing.md),
            ProductOptionDropdown(
              label: 'Tax',
              hint: 'Select tax',
              icon: Icons.receipt_long_outlined,
              value: _taxId,
              enabled: _inputsEnabled,
              items: buildOptionItems(
                options: options!.taxes
                    .map((item) => (id: item.id, label: item.name))
                    .toList(),
                emptyLabel: 'No taxes available',
              ),
              onChanged: (value) => setState(() => _taxId = value),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVariantSummaryEditCard({
    bool compact = false,
    bool stretch = false,
  }) {
    final total = widget.detail.variants.length;
    final active = widget.detail.variants
        .where((v) => v.status.trim().toUpperCase() == 'ACTIVE')
        .length;
    final inactive = total - active;

    return _SectionCard(
      title: 'Variant Summary',
      compact: compact,
      stretch: stretch,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: stretch ? MainAxisSize.max : MainAxisSize.min,
        children: [
          ProductReadOnlyField(
            label: 'Total',
            value: '$total',
            icon: Icons.published_with_changes_outlined,
          ),
          SizedBox(height: compact ? TenantAdminSpacing.sm : TenantAdminSpacing.md),
          ProductReadOnlyField(
            label: 'Active',
            value: '$active',
            icon: Icons.check_circle_outline,
          ),
          SizedBox(height: compact ? TenantAdminSpacing.sm : TenantAdminSpacing.md),
          ProductReadOnlyField(
            label: 'Inactive',
            value: '$inactive',
            icon: Icons.remove_circle_outline,
          ),
          if (stretch) const Spacer(),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: null,
              icon: Icon(Icons.visibility_outlined, size: compact ? 14 : 16),
              label: Text(
                'View All Variants',
                style: TextStyle(fontSize: compact ? 12 : 13),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: TenantAdminColors.mutedText,
                side: const BorderSide(color: TenantAdminColors.border),
                padding: EdgeInsets.symmetric(vertical: compact ? 6 : 8),
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

  Widget _buildChannelEditItem({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool compact = false,
  }) {
    return Container(
      padding: EdgeInsets.all(compact ? TenantAdminSpacing.sm : TenantAdminSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        border: Border.all(color: TenantAdminColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: compact ? 16 : 18, color: TenantAdminColors.bodyText),
          const SizedBox(width: TenantAdminSpacing.sm),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: TenantAdminColors.bodyText,
                fontSize: compact ? 12 : 13,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Switch(
            value: value,
            activeTrackColor: TenantAdminColors.success,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            onChanged: _inputsEnabled ? onChanged : null,
          ),
        ],
      ),
    );
  }

  Widget _buildAuditSummaryEditCard(
    TenantProductDetail detail, {
    bool compact = false,
  }) {
    final dateFormat = DateFormat('MMM dd, yyyy hh:mm a');
    final createdStr = dateFormat.format(detail.createdAt);
    final updatedStr = dateFormat.format(detail.updatedAt);

    return _SectionCard(
      title: 'Product Audit Information',
      compact: compact,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _AuditTile(
                icon: Icons.person_outline,
                label: 'Created By',
                value: 'John Perera',
                secondaryValue: createdStr,
                compact: compact,
              ),
            ),
            const SizedBox(width: TenantAdminSpacing.md),
            Expanded(
              child: _AuditTile(
                icon: Icons.person_outline,
                label: 'Last Updated By',
                value: 'John Perera',
                compact: compact,
              ),
            ),
            const SizedBox(width: TenantAdminSpacing.md),
            Expanded(
              child: _AuditTile(
                icon: Icons.calendar_month_outlined,
                label: 'Last Updated',
                value: updatedStr,
                compact: compact,
              ),
            ),
          ],
        ),
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
    this.compact = false,
    this.stretch = false,
  });

  final String title;
  final Widget child;
  final bool compact;
  final bool stretch;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: compact ? 13.5 : 16,
            fontWeight: FontWeight.w800,
            color: TenantAdminColors.bodyText,
          ),
        ),
        SizedBox(height: compact ? TenantAdminSpacing.sm : TenantAdminSpacing.lg),
        if (stretch)
          Expanded(child: child)
        else
          child,
      ],
    );

    return Container(
      width: stretch ? double.infinity : null,
      height: stretch ? double.infinity : null,
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
        border: Border.all(color: TenantAdminColors.border),
      ),
      padding: EdgeInsets.all(compact ? TenantAdminSpacing.md : TenantAdminSpacing.xl),
      child: content,
    );
  }
}

class _EditFieldGrid extends StatelessWidget {
  const _EditFieldGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    assert(children.length == 9, 'Edit field grid expects 9 fields');
    const columns = 3;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        border: Border.all(color: TenantAdminColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var rowIndex = 0; rowIndex < 3; rowIndex++) ...[
            if (rowIndex > 0)
              const Divider(
                height: 1,
                thickness: 1,
                color: TenantAdminColors.border,
              ),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var colIndex = 0; colIndex < columns; colIndex++) ...[
                    if (colIndex > 0)
                      const VerticalDivider(
                        width: 1,
                        thickness: 1,
                        color: TenantAdminColors.border,
                      ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(TenantAdminSpacing.sm),
                        child: children[rowIndex * columns + colIndex],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
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
    this.secondaryValue,
    this.compact = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? secondaryValue;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: compact ? 15 : 18,
          color: TenantAdminColors.mutedText,
        ),
        const SizedBox(width: TenantAdminSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: TenantAdminColors.mutedText,
                  fontSize: compact ? 10 : 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: TenantAdminColors.bodyText,
                  fontSize: compact ? 11.5 : 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (secondaryValue != null) ...[
                const SizedBox(height: 1),
                Text(
                  secondaryValue!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: TenantAdminColors.mutedText,
                    fontSize: compact ? 10 : 10.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
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
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: TenantAdminColors.bodyText,
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        InputDecorator(
          decoration: InputDecoration(
            isDense: true,
            prefixIcon: Icon(icon, size: 18, color: const Color(0xFF64748B)),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 40,
              minHeight: 40,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            filled: true,
            fillColor: TenantAdminColors.surface,
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: TenantAdminColors.bodyText,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
