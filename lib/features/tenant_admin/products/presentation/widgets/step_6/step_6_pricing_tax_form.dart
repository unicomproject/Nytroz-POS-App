import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../presentation/theme/tenant_admin_theme.dart';
import '../../../domain/entities/add_product_wizard_state.dart';
import '../../../domain/entities/tenant_product_create_options.dart';
import '../../providers/tenant_product_providers.dart';
import '../../utils/step_6_tax_preview.dart';
import '../product_form_fields.dart';
import 'step_6_variant_pricing_tax_form.dart';

class Step6PricingTaxForm extends ConsumerStatefulWidget {
  const Step6PricingTaxForm({super.key});

  @override
  ConsumerState<Step6PricingTaxForm> createState() =>
      _Step6PricingTaxFormState();
}

class _Step6PricingTaxFormState extends ConsumerState<Step6PricingTaxForm> {
  late final TextEditingController _costPriceController;
  late final TextEditingController _sellingPriceController;
  late final TextEditingController _discountPriceController;
  late final FocusNode _sellingPriceFocus;
  bool _syncingFromState = false;

  /// Tax Preview uses this only after price is committed (blur / Done),
  /// not while the user is still typing.
  double? _previewSellingPrice;

  @override
  void initState() {
    super.initState();
    final state = ref.read(addProductWizardControllerProvider);
    _costPriceController = TextEditingController(
      text: state.costPrice?.toString() ?? '',
    );
    _sellingPriceController = TextEditingController(
      text: state.standardSellingPrice?.toString() ?? '',
    );
    _discountPriceController = TextEditingController(
      text: state.discountPrice?.toString() ?? '',
    );
    _sellingPriceFocus = FocusNode();
    _sellingPriceFocus.addListener(() {
      if (!_sellingPriceFocus.hasFocus) {
        _commitSellingPriceForPreview();
      }
    });

    final initialSell = state.standardSellingPrice?.toDouble();
    if (initialSell != null && initialSell > 0) {
      _previewSellingPrice = initialSell;
    }

    _costPriceController.addListener(() {
      if (_syncingFromState) return;
      final val = num.tryParse(_costPriceController.text);
      ref
          .read(addProductWizardControllerProvider.notifier)
          .updateCostPrice(val);
    });
    _sellingPriceController.addListener(() {
      if (_syncingFromState) return;
      final val = num.tryParse(_sellingPriceController.text);
      ref
          .read(addProductWizardControllerProvider.notifier)
          .updateStandardSellingPrice(val);
      // Do not refresh Tax Preview on every keystroke.
    });
    _discountPriceController.addListener(() {
      if (_syncingFromState) return;
      final val = num.tryParse(_discountPriceController.text);
      ref
          .read(addProductWizardControllerProvider.notifier)
          .updateDiscountPrice(val);
    });
  }

  void _commitSellingPriceForPreview() {
    final val = num.tryParse(_sellingPriceController.text)?.toDouble();
    final next = (val != null && val > 0) ? val : null;
    if (_previewSellingPrice == next) return;
    setState(() => _previewSellingPrice = next);
  }

  void _syncControllersFromState() {
    final state = ref.read(addProductWizardControllerProvider);
    _syncingFromState = true;
    final cost = state.costPrice?.toString() ?? '';
    final sell = state.standardSellingPrice?.toString() ?? '';
    final discount = state.discountPrice?.toString() ?? '';
    if (_costPriceController.text != cost) {
      _costPriceController.text = cost;
    }
    if (_sellingPriceController.text != sell) {
      _sellingPriceController.text = sell;
    }
    if (_discountPriceController.text != discount) {
      _discountPriceController.text = discount;
    }
    _syncingFromState = false;
    final committed = state.standardSellingPrice?.toDouble();
    if (!_sellingPriceFocus.hasFocus) {
      _previewSellingPrice =
          (committed != null && committed > 0) ? committed : null;
    }
  }

  @override
  void dispose() {
    _sellingPriceFocus.dispose();
    _costPriceController.dispose();
    _sellingPriceController.dispose();
    _discountPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addProductWizardControllerProvider);
    final taxOptions = _resolveTaxOptions(
      state.createOptions?.taxes ?? const [],
      state,
    );
    final isSimpleLike = state.productStructure == 'SIMPLE' ||
        state.productStructure == 'BUNDLE';

    ref.listen(addProductWizardControllerProvider, (previous, next) {
      if (previous?.costPrice != next.costPrice ||
          previous?.standardSellingPrice != next.standardSellingPrice ||
          previous?.discountPrice != next.discountPrice) {
        _syncControllersFromState();
      }
    });

    if (isSimpleLike) {
      return _buildSimpleForm(state, taxOptions);
    }
    return Step6VariantPricingTaxForm(taxOptions: taxOptions);
  }

  Widget _buildSimpleForm(
    AddProductWizardState state,
    List<ProductTaxOption> taxOptions,
  ) {
    final currency =
        (state.createOptions?.currencyCode.trim().isNotEmpty ?? false)
            ? state.createOptions!.currencyCode.toUpperCase()
            : '';
    final selling = _previewSellingPrice ?? 0;
    ProductTaxOption? selected;
    for (final option in taxOptions) {
      if (option.id == state.taxId) {
        selected = option;
        break;
      }
    }
    final rate = selected?.currentRate ?? state.taxRate?.toDouble();
    final hasTaxClass = state.taxId != null && state.taxId!.trim().isNotEmpty;
    final hasEffectiveRate = hasTaxClass &&
        (selected?.isExempt == true ||
            selected?.isZeroRated == true ||
            rate != null);
    final canShowPreview = selling > 0 && hasTaxClass && hasEffectiveRate;
    final preview = computeStep6TaxPreview(
      sellingPrice: selling,
      ratePercent: rate ?? 0,
      taxExclusive: state.taxExclusive,
      isExempt: selected?.isExempt ?? false,
    );

    return LayoutBuilder(
      builder: (context, outerConstraints) {
        final content = Container(
          width: double.infinity,
          padding: const EdgeInsets.all(TenantAdminSpacing.md),
          decoration: BoxDecoration(
            color: TenantAdminColors.surface,
            borderRadius: BorderRadius.circular(TenantAdminRadius.md),
            border: Border.all(color: TenantAdminColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Pricing & Tax',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: TenantAdminColors.bodyText,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Set the selling price and tax details for this product.',
                style: TextStyle(
                  fontSize: 13,
                  color: TenantAdminColors.mutedText,
                ),
              ),
              const SizedBox(height: TenantAdminSpacing.md),
              LayoutBuilder(
                builder: (context, constraints) {
                  final twoCol = constraints.maxWidth >=
                      TenantAdminBreakpoints.smallTablet;
                  final fields =
                      _buildSimpleFields(state, taxOptions, currency);
                  final previewCard = _TaxPreviewCard(
                    currencyCode: currency,
                    preview: preview,
                    selectedTax: selected,
                    canShowPreview: canShowPreview,
                  );
                  if (!twoCol) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        fields,
                        const SizedBox(height: TenantAdminSpacing.md),
                        previewCard,
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: fields),
                      const SizedBox(width: TenantAdminSpacing.lg),
                      Expanded(flex: 2, child: previewCard),
                    ],
                  );
                },
              ),
            ],
          ),
        );

        return Padding(
          padding: const EdgeInsets.all(TenantAdminSpacing.sm),
          child: outerConstraints.maxHeight.isFinite
              ? SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: content,
                )
              : content,
        );
      },
    );
  }

  Widget _buildSimpleFields(
    AddProductWizardState state,
    List<ProductTaxOption> taxOptions,
    String currency,
  ) {
    final disabled = state.isSubmitting || state.isSavingDraft;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _RequiredLabel('Standard Selling Price'),
        const SizedBox(height: 6),
        TextField(
          controller: _sellingPriceController,
          focusNode: _sellingPriceFocus,
          enabled: !disabled,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textInputAction: TextInputAction.done,
          onEditingComplete: () {
            _commitSellingPriceForPreview();
            _sellingPriceFocus.unfocus();
          },
          onSubmitted: (_) => _commitSellingPriceForPreview(),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: TenantAdminColors.bodyText,
          ),
          decoration: InputDecoration(
            hintText: '',
            prefixIcon: currency.isEmpty
                ? null
                : Padding(
                    padding: const EdgeInsets.only(left: 12, right: 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      widthFactor: 1,
                      child: Text(
                        currency,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: TenantAdminColors.mutedText,
                        ),
                      ),
                    ),
                  ),
            prefixIconConstraints: const BoxConstraints(minWidth: 0),
            errorText: state.fieldErrors['standardSellingPrice'],
            filled: true,
            fillColor: TenantAdminColors.surface,
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
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
        const SizedBox(height: TenantAdminSpacing.md),
        ProductOptionDropdown(
          label: 'Tax Class *',
          hint: 'Select tax class',
          icon: Icons.description_outlined,
          value: state.taxId,
          items: taxOptions
              .map(
                (t) => DropdownMenuItem<String>(
                  value: t.id,
                  child: Text(_simpleTaxClassLabel(t)),
                ),
              )
              .toList(),
          errorText: state.fieldErrors['taxId'],
          enabled: !disabled,
          onChanged: (val) {
            if (val != null) {
              final selectedTax = taxOptions.firstWhere((t) => t.id == val);
              ref.read(addProductWizardControllerProvider.notifier).updateTaxId(
                    val,
                    taxRate: selectedTax.currentRate,
                    taxName: selectedTax.name,
                  );
            } else {
              ref
                  .read(addProductWizardControllerProvider.notifier)
                  .updateTaxId(null);
            }
          },
        ),
        const SizedBox(height: 4),
        const Text(
          'Select the tax class applicable to this product.',
          style: TextStyle(fontSize: 11, color: TenantAdminColors.mutedText),
        ),
        const SizedBox(height: TenantAdminSpacing.md),
        const _RequiredLabel('Tax Presentation'),
        const SizedBox(height: TenantAdminSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _priceModeCard(
                state: state,
                title: 'Tax Exclusive',
                subtitle: 'Tax will be added at checkout',
                icon: Icons.inventory_2_outlined,
                selected: state.taxExclusive,
                onTap: () => ref
                    .read(addProductWizardControllerProvider.notifier)
                    .updateTaxExclusive(true),
              ),
            ),
            const SizedBox(width: TenantAdminSpacing.sm),
            Expanded(
              child: _priceModeCard(
                state: state,
                title: 'Tax Inclusive',
                subtitle: 'Tax is included in the price',
                icon: Icons.pie_chart_outline,
                selected: !state.taxExclusive,
                onTap: () => ref
                    .read(addProductWizardControllerProvider.notifier)
                    .updateTaxExclusive(false),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _priceModeCard({
    required AddProductWizardState state,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: state.isSubmitting || state.isSavingDraft ? null : onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFF5F3) : TenantAdminColors.surface,
          border: Border.all(
            color:
                selected ? TenantAdminColors.primary : TenantAdminColors.border,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: selected
                  ? Colors.brown.shade700
                  : TenantAdminColors.mutedText,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: selected
                          ? Colors.brown.shade800
                          : TenantAdminColors.bodyText,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: selected
                          ? Colors.blueGrey.shade400
                          : TenantAdminColors.mutedText,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(
                Icons.check_circle,
                color: TenantAdminColors.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  List<ProductTaxOption> _resolveTaxOptions(
    List<ProductTaxOption> activeOptions,
    AddProductWizardState state,
  ) {
    final options = List<ProductTaxOption>.from(activeOptions);
    final currentTaxId = state.taxId;
    if (currentTaxId == null || currentTaxId.isEmpty) {
      return options;
    }
    if (options.any((t) => t.id == currentTaxId)) {
      return options;
    }

    options.insert(
      0,
      ProductTaxOption(
        id: currentTaxId,
        code: '',
        name: (state.taxName?.trim().isNotEmpty ?? false)
            ? '${state.taxName} — Inactive'
            : 'Current tax — Inactive',
        taxTreatment: 'TAXABLE',
        currentRate: state.taxRate?.toDouble(),
      ),
    );
    return options;
  }

  String _simpleTaxClassLabel(ProductTaxOption tax) {
    if (tax.isExempt) return '${tax.name} (Exempt)';
    if (tax.isZeroRated) return '${tax.name} (0%)';
    final rate = tax.currentRate;
    if (rate == null) return tax.name;
    final rateText = rate.truncateToDouble() == rate
        ? rate.toStringAsFixed(0)
        : rate.toString();
    return '${tax.name} ($rateText%)';
  }
}

class _RequiredLabel extends StatelessWidget {
  final String text;
  final bool required;

  const _RequiredLabel(this.text) : required = true;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          text,
          style: const TextStyle(
            color: TenantAdminColors.bodyText,
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (required)
          const Text(
            ' *',
            style: TextStyle(
              color: TenantAdminColors.danger,
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    );
  }
}

class _TaxPreviewCard extends StatelessWidget {
  final String currencyCode;
  final Step6TaxPreview preview;
  final ProductTaxOption? selectedTax;
  final bool canShowPreview;

  const _TaxPreviewCard({
    required this.currencyCode,
    required this.preview,
    required this.selectedTax,
    required this.canShowPreview,
  });

  String _money(double value) {
    if (!canShowPreview) return '—';
    if (currencyCode.isEmpty) return value.toStringAsFixed(2);
    return '$currencyCode ${value.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final modeLabel = preview.taxExclusive ? 'Tax Exclusive' : 'Tax Inclusive';
    final rateLabel = !canShowPreview || selectedTax == null
        ? '—'
        : selectedTax!.isExempt
            ? 'Exempt'
            : '${preview.ratePercent.truncateToDouble() == preview.ratePercent ? preview.ratePercent.toStringAsFixed(0) : preview.ratePercent}%';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TenantAdminColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calculate_outlined,
                  color: TenantAdminColors.success, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tax Preview ($modeLabel)',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: TenantAdminColors.bodyText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _previewRow(
            'Net Price (Excl. Tax)',
            _money(preview.netPrice),
          ),
          const SizedBox(height: 8),
          _previewRow(
            'Estimated Tax ($rateLabel)',
            _money(preview.taxAmount),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Final Display Price (Incl. Tax)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: TenantAdminColors.bodyText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _money(preview.finalPrice),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: canShowPreview
                        ? TenantAdminColors.success
                        : TenantAdminColors.mutedText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            canShowPreview
                ? 'This is the amount customers will pay.'
                : 'Enter selling price, select a tax class, then leave the price field to calculate the balance.',
            style: const TextStyle(
              fontSize: 11,
              color: TenantAdminColors.mutedText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _previewRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              color: TenantAdminColors.mutedText,
            ),
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: TenantAdminColors.bodyText,
            ),
          ),
        ),
      ],
    );
  }
}
