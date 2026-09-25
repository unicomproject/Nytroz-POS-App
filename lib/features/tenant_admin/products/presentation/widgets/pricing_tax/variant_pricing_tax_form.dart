import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../presentation/theme/tenant_admin_theme.dart';
import '../../../domain/entities/add_product_wizard_state.dart';
import '../../../domain/entities/tenant_product_create_options.dart';
import '../../providers/tenant_product_providers.dart';
import '../../utils/variant_pricing.dart';
import '../product_form_fields.dart';

/// VARIANT Product Setup Step 6 — per-variant selling prices + common tax.
class Step6VariantPricingTaxForm extends ConsumerStatefulWidget {
  const Step6VariantPricingTaxForm({
    super.key,
    required this.taxOptions,
  });

  final List<ProductTaxOption> taxOptions;

  @override
  ConsumerState<Step6VariantPricingTaxForm> createState() =>
      _Step6VariantPricingTaxFormState();
}

class _Step6VariantPricingTaxFormState
    extends ConsumerState<Step6VariantPricingTaxForm> {
  final TextEditingController _bulkPriceController = TextEditingController();
  final Map<String, TextEditingController> _rowControllers = {};
  final Map<String, TextEditingController> _costControllers = {};
  final Map<String, FocusNode> _rowFocusNodes = {};
  final Map<String, FocusNode> _costFocusNodes = {};
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(addProductWizardControllerProvider.notifier)
          .reconcileVariantPricesWithVariants();
      _syncRowControllers();
    });
  }

  @override
  void dispose() {
    _bulkPriceController.dispose();
    for (final c in _rowControllers.values) {
      c.dispose();
    }
    for (final c in _costControllers.values) {
      c.dispose();
    }
    for (final f in _rowFocusNodes.values) {
      f.dispose();
    }
    for (final f in _costFocusNodes.values) {
      f.dispose();
    }
    super.dispose();
  }

  void _syncRowControllers() {
    final state = ref.read(addProductWizardControllerProvider);
    final rows = buildVariantPricingRows(state: state);
    _syncing = true;
    final liveKeys = <String>{};
    for (final row in rows) {
      liveKeys.add(row.identityKey);
      final text = row.sellingPrice?.toString() ?? '';
      final costText = row.costPrice?.toString() ?? '';
      final identityKey = row.identityKey;
      final clientKey = row.clientCombinationKey;
      final variantId = row.productVariantId;
      
      // Sync Selling Price
      final controller = _rowControllers.putIfAbsent(
        identityKey,
        () {
          final c = TextEditingController(text: text);
          c.addListener(() {
            if (_syncing) return;
            final liveRows = buildVariantPricingRows(
              state: ref.read(addProductWizardControllerProvider),
            );
            VariantPricingRowView? current;
            for (final r in liveRows) {
              if (r.identityKey == identityKey) {
                current = r;
                break;
              }
            }
            final val = num.tryParse(c.text);
            ref
                .read(addProductWizardControllerProvider.notifier)
                .updateVariantSellingPrice(
                  clientCombinationKey:
                      current?.clientCombinationKey ?? clientKey,
                  productVariantId: current?.productVariantId ?? variantId,
                  sellingPrice: c.text.trim().isEmpty ? null : val,
                );
          });
          return c;
        },
      );
      _rowFocusNodes.putIfAbsent(identityKey, FocusNode.new);
      if (!_rowFocusNodes[identityKey]!.hasFocus && controller.text != text) {
        controller.text = text;
      }
      
      // Sync Cost Price
      final costController = _costControllers.putIfAbsent(
        identityKey,
        () {
          final c = TextEditingController(text: costText);
          c.addListener(() {
            if (_syncing) return;
            final liveRows = buildVariantPricingRows(
              state: ref.read(addProductWizardControllerProvider),
            );
            VariantPricingRowView? current;
            for (final r in liveRows) {
              if (r.identityKey == identityKey) {
                current = r;
                break;
              }
            }
            final val = num.tryParse(c.text);
            ref
                .read(addProductWizardControllerProvider.notifier)
                .updateVariantCostPrice(
                  clientCombinationKey:
                      current?.clientCombinationKey ?? clientKey,
                  productVariantId: current?.productVariantId ?? variantId,
                  costPrice: c.text.trim().isEmpty ? null : val,
                );
          });
          return c;
        },
      );
      _costFocusNodes.putIfAbsent(identityKey, FocusNode.new);
      if (!_costFocusNodes[identityKey]!.hasFocus && costController.text != costText) {
        costController.text = costText;
      }
    }
    final stale = _rowControllers.keys
        .where((k) => !liveKeys.contains(k))
        .toList(growable: false);
    for (final k in stale) {
      _rowControllers.remove(k)?.dispose();
      _costControllers.remove(k)?.dispose();
      _rowFocusNodes.remove(k)?.dispose();
      _costFocusNodes.remove(k)?.dispose();
    }
    _syncing = false;
  }

  Future<void> _onApplyToAll() async {
    final raw = num.tryParse(_bulkPriceController.text.trim());
    if (raw == null || raw <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid price to apply to all variants.'),
        ),
      );
      return;
    }

    final state = ref.read(addProductWizardControllerProvider);
    final rows = buildVariantPricingRows(state: state);
    final hasExisting = rows.any((r) => r.isPriced);
    if (hasExisting) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Apply price to all variants?'),
          content: const Text(
            'This will replace existing variant prices.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Apply to All'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    setState(() {});
    ref
        .read(addProductWizardControllerProvider.notifier)
        .applyBulkSellingPriceToAllVariants(raw);
    _syncRowControllers();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addProductWizardControllerProvider);
    ref.listen(addProductWizardControllerProvider, (prev, next) {
      if (prev?.variantPrices != next.variantPrices ||
          prev?.step4State.generatedVariants !=
              next.step4State.generatedVariants ||
          prev?.step5State.assignments != next.step5State.assignments) {
        _syncRowControllers();
      }
    });

    final currency =
        (state.createOptions?.currencyCode.trim().isNotEmpty ?? false)
            ? state.createOptions!.currencyCode.toUpperCase()
            : '';
    final rows = buildVariantPricingRows(state: state);
    if (rows.any((r) => !_rowControllers.containsKey(r.identityKey))) {
      _syncRowControllers();
    }
    final selectedTax = _selectedTax(state, widget.taxOptions);
    final effectiveRateLabel = _effectiveRateLabel(selectedTax, state);

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(TenantAdminSpacing.md),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final mainColumn = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pricing & Tax — Variant Product',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: TenantAdminColors.bodyText,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Set pricing and tax details for each variant. Prices are managed at variant level.',
                style: TextStyle(
                  fontSize: 13,
                  color: TenantAdminColors.mutedText,
                ),
              ),
              const SizedBox(height: TenantAdminSpacing.md),
              _bulkPriceCard(currency),
              const SizedBox(height: TenantAdminSpacing.md),
              _taxSettingsHorizontalCard(state, effectiveRateLabel),
              const SizedBox(height: TenantAdminSpacing.md),
              _variantTable(state, rows, currency),
              if (state.fieldErrors['variantPrices'] != null) ...[
                const SizedBox(height: TenantAdminSpacing.sm),
                Text(
                  state.fieldErrors['variantPrices']!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          );

          return mainColumn;
        },
      ),
    );
  }

  ProductTaxOption? _selectedTax(
    AddProductWizardState state,
    List<ProductTaxOption> options,
  ) {
    if (state.taxId == null) return null;
    for (final t in options) {
      if (t.id == state.taxId) return t;
    }
    return null;
  }

  String _effectiveRateLabel(
    ProductTaxOption? selected,
    AddProductWizardState state,
  ) {
    if (selected == null && state.taxRate == null) return '—';
    if (selected?.isExempt == true) return 'Exempt';
    final rate = selected?.currentRate ?? state.taxRate;
    if (rate == null) return '—';
    return '${rate.toStringAsFixed(2)}%';
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(TenantAdminSpacing.md),
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        border: Border.all(color: TenantAdminColors.border),
      ),
      child: child,
    );
  }



  Widget _bulkPriceCard(String currency) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Set Same Price for All Variants',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: TenantAdminColors.bodyText,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Set the same starting price for every variant. You can adjust individual prices below.',
            style: TextStyle(fontSize: 12, color: TenantAdminColors.mutedText),
          ),
          const SizedBox(height: TenantAdminSpacing.sm),
          const SizedBox(height: TenantAdminSpacing.sm),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _bulkPriceController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  decoration: InputDecoration(
                    prefixText: currency.isEmpty ? null : '$currency ',
                    hintText: 'Selling Price',
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: TenantAdminSpacing.sm),
              FilledButton.icon(
                onPressed: _onApplyToAll,
                icon: const Icon(Icons.copy_all_outlined, size: 18),
                label: const Text('Apply Price'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _variantTable(
    AddProductWizardState state,
    List<VariantPricingRowView> rows,
    String currency,
  ) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Variant Pricing',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: TenantAdminColors.bodyText,
            ),
          ),
          const SizedBox(height: TenantAdminSpacing.sm),
          if (rows.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No included variants. Configure variants in Step 4.',
                  style: TextStyle(color: TenantAdminColors.mutedText),
                ),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 640),
                child: DataTable(
                  headingRowHeight: 40,
                  dataRowMinHeight: 52,
                  dataRowMaxHeight: 80,
                  columnSpacing: 24,
                  columns: [
                    const DataColumn(label: Text('Variant')),
                    DataColumn(
                      label: Text(
                        currency.isEmpty
                            ? 'Cost Price'
                            : 'Cost Price ($currency)',
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        currency.isEmpty
                            ? 'Selling Price'
                            : 'Selling Price ($currency)',
                      ),
                    ),
                    const DataColumn(label: Text('Tax Class')),
                    const DataColumn(label: Text('Status')),
                  ],
                  rows: rows.map((row) {
                    final controller = _rowControllers[row.identityKey]!;
                    final focus = _rowFocusNodes[row.identityKey]!;
                    final error =
                        state.fieldErrors['variantPrice:${row.identityKey}'];
                    return DataRow(
                      cells: [
                        DataCell(
                          SizedBox(
                            width: 180,
                            child: Text(
                              row.displayLabel,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        DataCell(
                          SizedBox(
                            width: 140,
                            child: TextField(
                              controller: _costControllers[row.identityKey],
                              focusNode: _costFocusNodes[row.identityKey],
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9.]'),
                                ),
                              ],
                              decoration: InputDecoration(
                                isDense: true,
                                hintText: 'Enter cost',
                                hintStyle: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 12,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 10,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  borderSide: const BorderSide(
                                    color: TenantAdminColors.posHomeAccentOrange,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          SizedBox(
                            width: 140,
                            child: TextField(
                              controller: controller,
                              focusNode: focus,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9.]'),
                                ),
                              ],
                              decoration: InputDecoration(
                                isDense: true,
                                hintText: 'Enter price',
                                hintStyle: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 12,
                                ),
                                errorText: error,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 10,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  borderSide: const BorderSide(
                                    color: TenantAdminColors.posHomeAccentOrange,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          SizedBox(
                            width: 180,
                            child: state.applySameTaxToAllVariants
                              ? Text(row.taxName ?? state.taxName ?? 'None')
                              : ProductOptionDropdown(
                                  label: null,
                                  hint: 'Select tax',
                                  icon: Icons.description_outlined,
                                  value: row.taxId,
                                  items: [
                                    for (final t in widget.taxOptions)
                                      DropdownMenuItem(
                                        value: t.id,
                                        child: Text(t.dropdownLabel, overflow: TextOverflow.ellipsis),
                                      ),
                                  ],
                                  onChanged: (id) {
                                    ProductTaxOption? selected;
                                    for (final t in widget.taxOptions) {
                                      if (t.id == id) selected = t;
                                    }
                                    ref
                                        .read(addProductWizardControllerProvider.notifier)
                                        .updateVariantTaxId(
                                          row.identityKey,
                                          id,
                                          taxRate: selected?.currentRate,
                                          taxName: selected?.name,
                                        );
                                  },
                                ),
                          ),
                        ),
                        DataCell(_statusChip(row.isPriced)),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _statusChip(bool priced) {
    final bg = priced ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0);
    final fg = priced ? const Color(0xFF2E7D32) : const Color(0xFFE65100);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        priced ? 'Priced' : 'Pending',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }

  Widget _taxSettingsHorizontalCard(
    AddProductWizardState state,
    String effectiveRateLabel,
  ) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tax Settings',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: TenantAdminColors.bodyText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Configure how tax is calculated and presented.',
                      style: TextStyle(fontSize: 12, color: TenantAdminColors.mutedText),
                    ),
                  ],
                ),
              ),
              CheckboxMenuButton(
                value: state.applySameTaxToAllVariants,
                onChanged: (v) {
                  if (v != null) {
                    ref.read(addProductWizardControllerProvider.notifier).updateApplySameTaxToAllVariants(v);
                  }
                },
                child: const Text('Apply same tax to all variants'),
              ),
            ],
          ),
          const SizedBox(height: TenantAdminSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ProductOptionDropdown(
                  label: 'Global Tax Class',
                  hint: 'Select tax class',
                  icon: Icons.description_outlined,
                  value: state.taxId,
                  items: [
                    for (final t in widget.taxOptions)
                      DropdownMenuItem(
                        value: t.id,
                        child: Text(t.dropdownLabel, overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  enabled: state.applySameTaxToAllVariants && !state.isSubmitting && !state.isSavingDraft,
                  onChanged: (id) {
                    ProductTaxOption? selected;
                    for (final t in widget.taxOptions) {
                      if (t.id == id) selected = t;
                    }
                    ref.read(addProductWizardControllerProvider.notifier).updateTaxId(
                          id,
                          taxRate: selected?.currentRate,
                          taxName: selected?.name,
                        );
                  },
                  errorText: state.fieldErrors['taxId'],
                ),
              ),
              const SizedBox(width: TenantAdminSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Global Effective Tax Rate',
                      style: TextStyle(
                        fontSize: 12,
                        color: TenantAdminColors.mutedText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      effectiveRateLabel,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: TenantAdminColors.bodyText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: TenantAdminSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tax Presentation *',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: TenantAdminColors.bodyText,
                      ),
                    ),
                    const SizedBox(height: TenantAdminSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: _taxModeCard(
                            title: 'Tax Exclusive',
                            subtitle: 'Added at checkout',
                            selected: state.taxExclusive,
                            onTap: () => ref
                                .read(addProductWizardControllerProvider.notifier)
                                .updateTaxExclusive(true),
                          ),
                        ),
                        const SizedBox(width: TenantAdminSpacing.sm),
                        Expanded(
                          child: _taxModeCard(
                            title: 'Tax Inclusive',
                            subtitle: 'Included in price',
                            selected: !state.taxExclusive,
                            onTap: () => ref
                                .read(addProductWizardControllerProvider.notifier)
                                .updateTaxExclusive(false),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _taxModeCard({
    required String title,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
      child: Container(
        padding: const EdgeInsets.all(TenantAdminSpacing.sm),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
          border: Border.all(
            color:
                selected ? TenantAdminColors.primary : TenantAdminColors.border,
            width: selected ? 1.5 : 1,
          ),
          color: selected
              ? TenantAdminColors.primary.withValues(alpha: 0.06)
              : TenantAdminColors.surface,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: selected
                    ? TenantAdminColors.primary
                    : TenantAdminColors.bodyText,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: TenantAdminColors.mutedText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
