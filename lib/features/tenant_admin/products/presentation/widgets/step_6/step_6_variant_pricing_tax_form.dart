import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../presentation/theme/tenant_admin_theme.dart';
import '../../../domain/entities/add_product_wizard_state.dart';
import '../../../domain/entities/tenant_product_create_options.dart';
import '../../providers/tenant_product_providers.dart';
import '../../utils/step_6_variant_pricing.dart';
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
  final Map<String, FocusNode> _rowFocusNodes = {};
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
    for (final f in _rowFocusNodes.values) {
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
      final identityKey = row.identityKey;
      final clientKey = row.clientCombinationKey;
      final variantId = row.productVariantId;
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
    }
    final stale = _rowControllers.keys
        .where((k) => !liveKeys.contains(k))
        .toList(growable: false);
    for (final k in stale) {
      _rowControllers.remove(k)?.dispose();
      _rowFocusNodes.remove(k)?.dispose();
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
    final status = deriveVariantPricingStatus(rows);
    final selectedTax = _selectedTax(state, widget.taxOptions);
    final effectiveRateLabel = _effectiveRateLabel(selectedTax, state);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(TenantAdminSpacing.md),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : MediaQuery.sizeOf(context).width;
          final wide = width >= TenantAdminBreakpoints.smallTablet;

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
              if (wide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _productSummaryCard(state, status.total)),
                    const SizedBox(width: TenantAdminSpacing.md),
                    Expanded(child: _pricingStatusCard(status, currency)),
                  ],
                )
              else ...[
                _productSummaryCard(state, status.total),
                const SizedBox(height: TenantAdminSpacing.md),
                _pricingStatusCard(status, currency),
              ],
              const SizedBox(height: TenantAdminSpacing.md),
              _bulkPriceCard(currency),
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

          final sideColumn = Column(
            children: [
              _taxSettingsCard(state, widget.taxOptions, effectiveRateLabel),
              const SizedBox(height: TenantAdminSpacing.md),
              _importantNoteCard(),
            ],
          );

          if (!wide) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                mainColumn,
                const SizedBox(height: TenantAdminSpacing.md),
                sideColumn,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 4, child: mainColumn),
              const SizedBox(width: TenantAdminSpacing.md),
              Expanded(flex: 1, child: sideColumn),
            ],
          );
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

  Widget _productSummaryCard(AddProductWizardState state, int total) {
    final thumb = state.productImages.isNotEmpty
        ? state.productImages.first.imageUrl
        : null;
    return _card(
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 48,
              height: 48,
              color: TenantAdminColors.secondary,
              child: thumb != null && thumb.isNotEmpty
                  ? Image.network(thumb, fit: BoxFit.cover)
                  : const Icon(Icons.inventory_2_outlined,
                      color: TenantAdminColors.mutedText),
            ),
          ),
          const SizedBox(width: TenantAdminSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.productName.trim().isEmpty
                      ? 'Untitled Product'
                      : state.productName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: TenantAdminColors.bodyText,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color:
                            TenantAdminColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Variant Product',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: TenantAdminColors.primary,
                        ),
                      ),
                    ),
                    Text(
                      '$total Variants',
                      style: const TextStyle(
                        fontSize: 12,
                        color: TenantAdminColors.mutedText,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pricingStatusCard(
    VariantPricingDerivedStatus status,
    String currency,
  ) {
    return _card(
      child: Row(
        children: [
          Expanded(
            child: _stat(
              'Priced Variants',
              '${status.priced} / ${status.total}',
            ),
          ),
          Expanded(
            child: _stat(
              'Pending Variants',
              '${status.pending} / ${status.total}',
            ),
          ),
          Expanded(
            child: _stat(
              'Price Range',
              status.priceRangeLabel(currency),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: TenantAdminColors.mutedText,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: TenantAdminColors.bodyText,
          ),
        ),
      ],
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
                    hintText: '0.00',
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: TenantAdminSpacing.sm),
              FilledButton.icon(
                onPressed: _onApplyToAll,
                icon: const Icon(Icons.copy_all_outlined, size: 18),
                label: const Text('Apply to All'),
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
                  dataRowMaxHeight: 64,
                  columns: [
                    const DataColumn(label: Text('Variant')),
                    const DataColumn(label: Text('SKU')),
                    DataColumn(
                      label: Text(
                        currency.isEmpty
                            ? 'Selling Price'
                            : 'Selling Price ($currency)',
                      ),
                    ),
                    const DataColumn(label: Text('Status')),
                    const DataColumn(label: Text('')),
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
                            width: 260,
                            child: Text(
                              row.displayLabel,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        DataCell(Text(row.sku?.trim().isNotEmpty == true
                            ? row.sku!
                            : '—')),
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
                                errorText: error,
                                border: const OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ),
                        DataCell(_statusChip(row.isPriced)),
                        DataCell(
                          IconButton(
                            tooltip: 'Edit selling price',
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            onPressed: () => focus.requestFocus(),
                          ),
                        ),
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

  Widget _taxSettingsCard(
    AddProductWizardState state,
    List<ProductTaxOption> taxOptions,
    String effectiveRateLabel,
  ) {
    return _card(
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
          const SizedBox(height: TenantAdminSpacing.sm),
          ProductOptionDropdown(
            label: 'Tax Class *',
            hint: 'Select tax class',
            icon: Icons.description_outlined,
            value: state.taxId,
            items: [
              for (final t in taxOptions)
                DropdownMenuItem(
                  value: t.id,
                  child: Text(t.dropdownLabel, overflow: TextOverflow.ellipsis),
                ),
            ],
            enabled: !state.isSubmitting && !state.isSavingDraft,
            onChanged: (id) {
              ProductTaxOption? selected;
              for (final t in taxOptions) {
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
          const SizedBox(height: TenantAdminSpacing.sm),
          const Text(
            'Effective Tax Rate',
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
          const SizedBox(height: TenantAdminSpacing.sm),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(TenantAdminSpacing.sm),
            decoration: BoxDecoration(
              color: TenantAdminColors.secondary,
              borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
            ),
            child: const Text(
              'Tax will be calculated based on the selected tax class and applied to each variant price.',
              style:
                  TextStyle(fontSize: 12, color: TenantAdminColors.mutedText),
            ),
          ),
          const SizedBox(height: TenantAdminSpacing.md),
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
                  subtitle: 'Tax added at checkout',
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
                  subtitle: 'Tax included in price',
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

  Widget _importantNoteCard() {
    return _card(
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Important Note',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: TenantAdminColors.bodyText,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Each variant can have its own selling price. Use Apply to All only when you want the same starting price for every variant, then adjust individual variants if needed.',
            style: TextStyle(
              fontSize: 12,
              color: TenantAdminColors.mutedText,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
