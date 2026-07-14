import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/inventory_entities.dart';
import '../../../products/domain/entities/tenant_product.dart';
import '../../../products/presentation/providers/tenant_product_providers.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_buttons.dart';
import '../../../presentation/widgets/tenant_admin_search_field.dart';
import '../providers/inventory_providers.dart';

final stockInProductSearchTermProvider = StateProvider<String>((ref) => '');

final stockInProductSearchProvider =
    FutureProvider.autoDispose<List<TenantProduct>>((ref) async {
  final search = ref.watch(stockInProductSearchTermProvider);
  if (search.trim().length < 2) {
    return const [];
  }

  final result = await ref.read(tenantProductRepositoryProvider).getProducts(
        query: TenantProductListQuery(
          search: search.trim(),
          page: 1,
          pageSize: 20,
        ),
      );

  return result.items;
});

class StockInLineItemsPanel extends ConsumerWidget {
  const StockInLineItemsPanel({
    super.key,
    required this.fieldErrors,
    required this.isMobile,
  });

  final Map<String, String> fieldErrors;
  final bool isMobile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.watch(stockInFormProvider);
    final notifier = ref.read(stockInFormProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(TenantAdminSpacing.lg),
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
        border: Border.all(color: TenantAdminColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Line items',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: TenantAdminColors.bodyText,
                  ),
                ),
              ),
              TenantAdminSecondaryButton(
                label: 'Add item',
                icon: Icons.add,
                onPressed: notifier.addLine,
              ),
            ],
          ),
          if (fieldErrors['items'] != null) ...[
            const SizedBox(height: TenantAdminSpacing.sm),
            Text(
              fieldErrors['items']!,
              style: const TextStyle(color: TenantAdminColors.danger),
            ),
          ],
          const SizedBox(height: TenantAdminSpacing.lg),
          ...List.generate(form.items.length, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: TenantAdminSpacing.lg),
              child: _StockInLineEditor(
                index: index,
                line: form.items[index],
                fieldErrors: fieldErrors,
                isMobile: isMobile,
                canRemove: form.items.length > 1,
                onChanged: (line) => notifier.updateLine(index, line),
                onRemove: () => notifier.removeLine(index),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _StockInLineEditor extends ConsumerStatefulWidget {
  const _StockInLineEditor({
    required this.index,
    required this.line,
    required this.fieldErrors,
    required this.isMobile,
    required this.canRemove,
    required this.onChanged,
    required this.onRemove,
  });

  final int index;
  final StockInLineInput line;
  final Map<String, String> fieldErrors;
  final bool isMobile;
  final bool canRemove;
  final ValueChanged<StockInLineInput> onChanged;
  final VoidCallback onRemove;

  @override
  ConsumerState<_StockInLineEditor> createState() => _StockInLineEditorState();
}

class _StockInLineEditorState extends ConsumerState<_StockInLineEditor> {
  String? _selectedProductId;

  @override
  void initState() {
    super.initState();
    _selectedProductId = widget.line.productId;
  }

  String _fieldError(String field) {
    return widget.fieldErrors['items[${widget.index}].$field'] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final productSearch = ref.watch(stockInProductSearchProvider);
    final variantsState = _selectedProductId == null
        ? const AsyncValue<VariantLookup?>.data(null)
        : ref.watch(variantLookupProvider(_selectedProductId!));

    return Container(
      padding: const EdgeInsets.all(TenantAdminSpacing.md),
      decoration: BoxDecoration(
        color: TenantAdminColors.background,
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        border: Border.all(color: TenantAdminColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Item ${widget.index + 1}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              if (widget.canRemove)
                IconButton(
                  onPressed: widget.onRemove,
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Remove item',
                ),
            ],
          ),
          const SizedBox(height: TenantAdminSpacing.md),
          TenantAdminSearchField(
            hint: 'Search products',
            onChanged: (value) {
              ref.read(stockInProductSearchTermProvider.notifier).state = value;
            },
          ),
          if (productSearch.isLoading)
            const Padding(
              padding: EdgeInsets.only(top: TenantAdminSpacing.sm),
              child: LinearProgressIndicator(),
            ),
          if (productSearch.hasValue && productSearch.value!.isNotEmpty) ...[
            const SizedBox(height: TenantAdminSpacing.sm),
            ...productSearch.value!.map((product) {
              return ListTile(
                dense: true,
                title: Text(product.name),
                subtitle: Text(product.sku),
                onTap: () {
                  setState(() => _selectedProductId = product.id);
                  widget.onChanged(
                    widget.line.copyWith(
                      productId: product.id,
                      productName: product.name,
                      clearVariant: true,
                    ),
                  );
                  ref.read(stockInProductSearchTermProvider.notifier).state =
                      '';
                },
              );
            }),
          ],
          if (widget.line.productName != null) ...[
            const SizedBox(height: TenantAdminSpacing.sm),
            Text(
              'Selected: ${widget.line.productName}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
          const SizedBox(height: TenantAdminSpacing.md),
          variantsState.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const Text('Unable to load variants.'),
            data: (lookup) {
              if (lookup == null || lookup.variants.isEmpty) {
                return Text(
                  _fieldError('productVariantId').isEmpty
                      ? 'Select a product to load variants.'
                      : _fieldError('productVariantId'),
                  style: TextStyle(
                    color: _fieldError('productVariantId').isEmpty
                        ? TenantAdminColors.mutedText
                        : TenantAdminColors.danger,
                  ),
                );
              }

              return DropdownButtonFormField<String?>(
                initialValue: widget.line.productVariantId,
                decoration: InputDecoration(
                  labelText: 'Variant *',
                  border: const OutlineInputBorder(),
                  errorText: _fieldError('productVariantId').isEmpty
                      ? null
                      : _fieldError('productVariantId'),
                ),
                items: lookup.variants
                    .map(
                      (variant) => DropdownMenuItem<String?>(
                        value: variant.id,
                        child: Text(variant.displayLabel),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  final variant = lookup.variants.firstWhere(
                    (item) => item.id == value,
                  );
                  widget.onChanged(
                    widget.line.copyWith(
                      productVariantId: variant.id,
                      variantName: variant.displayLabel,
                      isBatchTracked: variant.isBatchTracked,
                      isExpiryTracked: variant.isExpiryTracked,
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: TenantAdminSpacing.md),
          if (widget.line.isBatchTracked)
            TextFormField(
              initialValue: widget.line.batchNumber,
              decoration: InputDecoration(
                labelText: 'Batch number *',
                border: const OutlineInputBorder(),
                errorText: _fieldError('batchNumber').isEmpty
                    ? null
                    : _fieldError('batchNumber'),
              ),
              onChanged: (value) =>
                  widget.onChanged(widget.line.copyWith(batchNumber: value)),
            ),
          if (widget.line.isBatchTracked)
            const SizedBox(height: TenantAdminSpacing.md),
          if (widget.line.isExpiryTracked) ...[
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Manufactured date'),
              subtitle: Text(
                widget.line.manufacturedDate?.toLocal().toString().split(' ').first ??
                    'Not set',
              ),
              trailing: IconButton(
                icon: const Icon(Icons.calendar_today_outlined),
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: widget.line.manufacturedDate ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (date != null) {
                    widget.onChanged(
                      widget.line.copyWith(manufacturedDate: date),
                    );
                  }
                },
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Expiry date *'),
              subtitle: Text(
                widget.line.expiryDate?.toLocal().toString().split(' ').first ??
                    'Not set',
              ),
              trailing: IconButton(
                icon: const Icon(Icons.event_outlined),
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: widget.line.expiryDate ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (date != null) {
                    widget.onChanged(widget.line.copyWith(expiryDate: date));
                  }
                },
              ),
            ),
            if (_fieldError('expiryDate').isNotEmpty)
              Text(
                _fieldError('expiryDate'),
                style: const TextStyle(color: TenantAdminColors.danger),
              ),
            const SizedBox(height: TenantAdminSpacing.md),
          ],
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue:
                      widget.line.quantity?.toString() ?? '',
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Quantity *',
                    border: const OutlineInputBorder(),
                    errorText: _fieldError('quantity').isEmpty
                        ? null
                        : _fieldError('quantity'),
                  ),
                  onChanged: (value) {
                    final quantity = double.tryParse(value);
                    widget.onChanged(widget.line.copyWith(quantity: quantity));
                  },
                ),
              ),
              const SizedBox(width: TenantAdminSpacing.md),
              Expanded(
                child: TextFormField(
                  initialValue: widget.line.unitCost?.toString() ?? '',
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Unit cost',
                    border: const OutlineInputBorder(),
                    errorText: _fieldError('unitCost').isEmpty
                        ? null
                        : _fieldError('unitCost'),
                  ),
                  onChanged: (value) {
                    final unitCost = double.tryParse(value);
                    widget.onChanged(widget.line.copyWith(unitCost: unitCost));
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: TenantAdminSpacing.md),
          TextFormField(
            initialValue: widget.line.barcode,
            decoration: const InputDecoration(
              labelText: 'Barcode',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) =>
                widget.onChanged(widget.line.copyWith(barcode: value)),
          ),
        ],
      ),
    );
  }
}
