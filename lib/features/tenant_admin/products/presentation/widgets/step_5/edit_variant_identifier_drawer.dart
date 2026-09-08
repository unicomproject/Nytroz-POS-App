import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../data/models/step5_barcode_dtos.dart';

class EditVariantIdentifierDrawer extends StatefulWidget {
  final Step5VariantIdentifierDto variantDto;
  final String displayLabel;
  final ValueChanged<Step5VariantIdentifierDto> onUpdate;
  final List<({String code, String label})> barcodeTypes;

  /// Other variants' barcodes (trimmed). Used for in-drawer uniqueness UX.
  final Set<String> existingBarcodes;

  /// Other variants' SKUs (trimmed). Used for in-drawer uniqueness UX.
  final Set<String> existingSkus;

  const EditVariantIdentifierDrawer({
    super.key,
    required this.variantDto,
    required this.displayLabel,
    required this.onUpdate,
    this.existingBarcodes = const {},
    this.existingSkus = const {},
    this.barcodeTypes = const [
      (code: 'EAN13', label: 'EAN-13'),
      (code: 'EAN8', label: 'EAN-8'),
      (code: 'UPCA', label: 'UPC-A'),
      (code: 'CODE128', label: 'Code 128'),
      (code: 'CODE39', label: 'Code 39'),
    ],
  });

  @override
  State<EditVariantIdentifierDrawer> createState() =>
      _EditVariantIdentifierDrawerState();
}

class _EditVariantIdentifierDrawerState
    extends State<EditVariantIdentifierDrawer> {
  late TextEditingController _skuController;
  late TextEditingController _barcodeController;
  late final FocusNode _barcodeFocus;
  final _formKey = GlobalKey<FormState>();
  String? _barcodeType;

  static const _infoBlue = Color(0xFF2563EB);
  static const _infoBlueSurface = Color(0xFFEFF6FF);
  static const _infoBlueBorder = Color(0xFFBFDBFE);

  @override
  void initState() {
    super.initState();
    _skuController = TextEditingController(text: widget.variantDto.sku ?? '');
    _barcodeController =
        TextEditingController(text: widget.variantDto.barcode ?? '');
    _barcodeFocus = FocusNode();
    _barcodeType = widget.variantDto.barcodeType;
    if (_barcodeType == null ||
        !widget.barcodeTypes.any((t) => t.code == _barcodeType)) {
      _barcodeType = widget.barcodeTypes.first.code;
    }
    _skuController.addListener(_onFieldChanged);
    _barcodeController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() => setState(() {});

  @override
  void dispose() {
    _skuController.dispose();
    _barcodeController.dispose();
    _barcodeFocus.dispose();
    super.dispose();
  }

  String get _sku => _skuController.text.trim();
  String get _barcode => _barcodeController.text.trim();

  bool get _skuDuplicate =>
      _sku.isNotEmpty && widget.existingSkus.contains(_sku);

  bool get _barcodeDuplicate =>
      _barcode.isNotEmpty && widget.existingBarcodes.contains(_barcode);

  bool get _canUpdate {
    if (_sku.isEmpty || _sku.length > 100) return false;
    if (_skuDuplicate || _barcodeDuplicate) return false;
    return true;
  }

  void _focusBarcodeForScan() {
    _barcodeFocus.requestFocus();
    final text = _barcodeController.text;
    _barcodeController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: text.length,
    );
  }

  void _onUpdate() {
    if (!_formKey.currentState!.validate()) return;
    if (!_canUpdate) return;
    final barcode = _barcode;
    widget.onUpdate(Step5VariantIdentifierDto(
      productVariantId: widget.variantDto.productVariantId,
      sku: _sku.isEmpty ? null : _sku,
      barcode: barcode.isEmpty ? null : barcode,
      barcodeType: barcode.isEmpty ? null : _barcodeType,
    ));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: TenantAdminColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _StatusBanner(
                      icon: Icons.info_outline,
                      background: _infoBlueSurface,
                      border: _infoBlueBorder,
                      iconColor: _infoBlue,
                      textColor: TenantAdminColors.bodyText,
                      message:
                          'Update the SKU or barcode for this variant. Ensure the barcode is unique across all variants.',
                    ),
                    const SizedBox(height: 20),
                    const _FieldLabel('Variant (Read-only)'),
                    const SizedBox(height: 6),
                    TextFormField(
                      initialValue: widget.displayLabel,
                      readOnly: true,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(TenantAdminRadius.sm),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(TenantAdminRadius.sm),
                          borderSide:
                              const BorderSide(color: TenantAdminColors.border),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        suffixIcon: const Icon(Icons.lock_outline,
                            size: 20, color: TenantAdminColors.mutedText),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const _FieldLabel('SKU', required: true),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _skuController,
                      decoration: _inputDecoration(),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'SKU is required';
                        }
                        if (val.trim().length > 100) {
                          return 'SKU cannot exceed 100 characters';
                        }
                        if (widget.existingSkus.contains(val.trim())) {
                          return 'This SKU is already used by another variant';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    const _FieldLabel('Barcode', required: true),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _barcodeController,
                      focusNode: _barcodeFocus,
                      inputFormatters: [
                        FilteringTextInputFormatter.deny(RegExp(r'[\n\r]')),
                      ],
                      decoration: _inputDecoration(
                        hintText: 'Type or scan barcode',
                        suffixIcon: IconButton(
                          tooltip: 'Focus for barcode scanner',
                          icon: const Icon(Icons.qr_code_scanner,
                              color: TenantAdminColors.posHomeAccentOrange),
                          onPressed: _focusBarcodeForScan,
                        ),
                      ),
                      onFieldSubmitted: (_) {
                        // HID wedge trailing Enter completes scan.
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _focusBarcodeForScan,
                        icon: const Icon(
                          Icons.qr_code_scanner,
                          color: TenantAdminColors.posHomeAccentOrange,
                        ),
                        label: const Text(
                          'Scan to Replace Barcode',
                          style: TextStyle(
                            color: TenantAdminColors.bodyText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: TenantAdminColors.surface,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: TenantAdminColors.border),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(TenantAdminRadius.sm),
                          ),
                        ),
                      ),
                    ),
                    if (_barcode.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _barcodeDuplicate
                          ? const _StatusBanner(
                              icon: Icons.error_outline,
                              background: TenantAdminColors.dangerSurface,
                              border: TenantAdminColors.dangerBorder,
                              iconColor: TenantAdminColors.danger,
                              textColor: TenantAdminColors.bodyText,
                              title: 'Barcode is already in use.',
                              message:
                                  'This barcode is assigned to another variant. Enter a unique barcode.',
                            )
                          : const _StatusBanner(
                              icon: Icons.check_circle,
                              background: TenantAdminColors.successSurface,
                              border: TenantAdminColors.successBorder,
                              iconColor: TenantAdminColors.success,
                              textColor: TenantAdminColors.bodyText,
                              title: 'Barcode is valid and unique.',
                              message:
                                  'This barcode is not used by any other variant.',
                            ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          _buildFooter(context),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({String? hintText, Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hintText,
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
        borderSide: const BorderSide(color: TenantAdminColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
        borderSide: const BorderSide(
          color: TenantAdminColors.posHomeAccentOrange,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 8, 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: TenantAdminColors.border)),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Edit Variant SKU & Barcode',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: TenantAdminColors.bodyText,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            color: TenantAdminColors.mutedText,
            tooltip: 'Close',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        border: Border(top: BorderSide(color: TenantAdminColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: TenantAdminColors.bodyText,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              side: const BorderSide(color: TenantAdminColors.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
              ),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _canUpdate ? _onUpdate : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: TenantAdminColors.posHomeAccentOrange,
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFFE5E7EB),
              disabledForegroundColor: const Color(0xFF9CA3AF),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
              ),
            ),
            child: const Text(
              'Update',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  final bool required;

  const _FieldLabel(this.text, {this.required = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: TenantAdminColors.bodyText,
          ),
        ),
        if (required)
          const Text(
            ' *',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: TenantAdminColors.danger,
            ),
          ),
      ],
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final IconData icon;
  final Color background;
  final Color border;
  final Color iconColor;
  final Color textColor;
  final String message;
  final String? title;

  const _StatusBanner({
    required this.icon,
    required this.background,
    required this.border,
    required this.iconColor,
    required this.textColor,
    required this.message,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: title == null
                ? Text(
                    message,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title!,
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.35,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        message,
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
