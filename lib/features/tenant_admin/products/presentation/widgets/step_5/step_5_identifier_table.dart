import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../data/models/step5_barcode_dtos.dart';
import '../../../domain/entities/step4_variant_configuration_state.dart';
import '../../../domain/entities/step5_barcode_sku_state.dart';

/// Step 5 identifier grid.
/// VARIANT: [checkbox] | Variant | SKU | Barcode | Status | Actions
/// SIMPLE / BUNDLE: green selected dot | Variant | SKU | Barcode | Scan | Status | pencil
class Step5IdentifierTable extends StatelessWidget {
  final List<BarcodeSkuAssignmentDto> assignments;
  final List<GeneratedVariantRow> allVariants;
  final String productName;
  final String productStructure;
  final Set<String> selectedClientKeys;
  final void Function(String clientCombinationKey)? onToggleSelect;
  final void Function(BarcodeSkuAssignmentDto assignment, int index) onEdit;
  final void Function(BarcodeSkuAssignmentDto assignment)? onClear;
  final void Function(BarcodeSkuAssignmentDto assignment, String barcode)?
      onBarcodeChanged;
  final void Function(BarcodeSkuAssignmentDto assignment, String sku)?
      onSkuChanged;
  final void Function(BarcodeSkuAssignmentDto assignment, String barcode)?
      onScanComplete;

  /// When true, SKU/Barcode cells are inline editable (VARIANT table-first).
  final bool inlineEditable;

  /// When true with [inlineEditable], only selected rows accept input.
  final bool editOnlyWhenSelected;

  /// Uncommitted SKU drafts keyed by clientCombinationKey (status stays Incomplete until Apply).
  final Map<String, String> draftSkus;

  /// Uncommitted barcode drafts keyed by clientCombinationKey.
  final Map<String, String> draftBarcodes;

  const Step5IdentifierTable({
    super.key,
    required this.assignments,
    required this.allVariants,
    required this.productName,
    required this.productStructure,
    required this.onEdit,
    this.selectedClientKeys = const {},
    this.onToggleSelect,
    this.onClear,
    this.onBarcodeChanged,
    this.onSkuChanged,
    this.onScanComplete,
    this.inlineEditable = false,
    this.editOnlyWhenSelected = false,
    this.draftSkus = const {},
    this.draftBarcodes = const {},
  });

  String _variantLabel(BarcodeSkuAssignmentDto assignment) {
    if (productStructure == 'SIMPLE' || productStructure == 'BUNDLE') {
      return productName.isNotEmpty ? productName : 'Base Product';
    }
    if (assignment.clientCombinationKey == 'SIMPLE_DEFAULT') {
      return productName.isNotEmpty ? productName : 'Base Product';
    }
    if (assignment.displayName != null &&
        assignment.displayName!.trim().isNotEmpty) {
      return assignment.displayName!;
    }
    final variant = allVariants.where(
      (v) => v.clientCombinationKey == assignment.clientCombinationKey,
    );
    if (variant.isNotEmpty) {
      return variant.first.displayLabel ?? variant.first.combinationLabel;
    }
    return assignment.clientCombinationKey;
  }

  String? _optionLabel(BarcodeSkuAssignmentDto assignment) {
    final variant = allVariants.where(
      (v) => v.clientCombinationKey == assignment.clientCombinationKey,
    );
    if (variant.isEmpty) return null;
    final combo = variant.first.combinationLabel;
    final display = variant.first.displayLabel;
    if (display != null &&
        display.trim().isNotEmpty &&
        combo.trim().isNotEmpty &&
        display != combo) {
      return combo;
    }
    return combo.trim().isEmpty ? null : combo;
  }

  String? _imageUrl(BarcodeSkuAssignmentDto assignment) {
    final variant = allVariants.where(
      (v) => v.clientCombinationKey == assignment.clientCombinationKey,
    );
    if (variant.isEmpty) return null;
    return variant.first.effectiveImageUrl;
  }

  @override
  Widget build(BuildContext context) {
    if (assignments.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 32),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey.shade50,
        ),
        child: const Center(
          child: Column(
            children: [
              Icon(Icons.qr_code_2_outlined, size: 40, color: Colors.grey),
              SizedBox(height: 8),
              Text(
                'No variants available for SKU & barcode setup.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              SizedBox(height: 4),
              Text(
                'Include at least one variant in Step 4 Product Configuration.',
                style: TextStyle(color: Colors.grey, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final bounded = constraints.hasBoundedHeight;
        final list = ListView.separated(
          shrinkWrap: !bounded,
          itemCount: assignments.length,
          separatorBuilder: (_, __) =>
              Divider(height: 1, color: Colors.grey.shade100),
          itemBuilder: (context, index) =>
              _buildDataRow(context, assignments[index], index),
        );

        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(8),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: bounded ? MainAxisSize.max : MainAxisSize.min,
            children: [
              _buildHeader(),
              if (bounded)
                Expanded(child: list)
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 280),
                  child: list,
                ),
            ],
          ),
        );
      },
    );
  }

  bool get _showSelectionCheckbox => onToggleSelect != null;

  /// SIMPLE / BUNDLE assignment row: green selected dot, Scan column, pencil.
  bool get _useCompactSelectedRow => !_showSelectionCheckbox;

  Widget _buildHeader() {
    return Container(
      color: Colors.grey.shade50,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (_showSelectionCheckbox) const SizedBox(width: _selectWidth),
          Expanded(flex: 3, child: _headerLabel('Variant')),
          Expanded(
            flex: 2,
            child: _headerLabel(_useCompactSelectedRow ? 'SKU' : 'SKU *'),
          ),
          Expanded(flex: 2, child: _headerLabel('Barcode')),
          if (_useCompactSelectedRow)
            SizedBox(width: _scanWidth, child: _headerLabel('Scan')),
          SizedBox(width: _statusWidth, child: _headerLabel('Status')),
          SizedBox(
            width: _actionsWidth + (_useCompactSelectedRow ? 0 : 28),
            child: _headerLabel(
              'Actions',
              align: _useCompactSelectedRow ? TextAlign.left : TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _headerLabel(String text, {TextAlign align = TextAlign.left}) {
    return Text(
      text,
      style: _headerStyle,
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.ellipsis,
      textAlign: align,
    );
  }

  static const _selectWidth = 36.0;
  static const _scanWidth = 56.0;
  static const _statusWidth = 132.0;
  static const _actionsWidth = 72.0;

  static const _headerStyle = TextStyle(
    fontWeight: FontWeight.w600,
    fontSize: 12,
    color: Color(0xFF6B7280),
    height: 1.2,
  );

  Widget _buildDataRow(
    BuildContext context,
    BarcodeSkuAssignmentDto assignment,
    int index,
  ) {
    final variantLabel = _variantLabel(assignment);
    final optionLabel = _optionLabel(assignment);
    final imageUrl = _imageUrl(assignment);
    final effectiveStatus = assignment.effectiveStatus;
    final selected = _useCompactSelectedRow ||
        selectedClientKeys.contains(assignment.clientCombinationKey);
    final canEditInline = inlineEditable &&
        onSkuChanged != null &&
        (!editOnlyWhenSelected || selected);
    final isComplete = effectiveStatus == 'COMPLETE';
    final showCompleteFieldStyle = isComplete && !canEditInline;
    const accent = TenantAdminColors.posHomeAccentOrange;
    const completeGreen = Color(0xFF22C55E);
    final displaySku =
        draftSkus[assignment.clientCombinationKey] ?? assignment.sku ?? '';
    final displayBarcode = draftBarcodes[assignment.clientCombinationKey] ??
        assignment.barcode ??
        '';
    final hasSku = assignment.sku?.trim().isNotEmpty == true;
    final hasBarcode = assignment.barcode?.trim().isNotEmpty == true;

    final primaryLabel = (!_useCompactSelectedRow && productName.trim().isNotEmpty)
        ? productName.trim()
        : variantLabel;
    final secondaryLabel = (!_useCompactSelectedRow &&
            productName.trim().isNotEmpty &&
            (optionLabel ?? variantLabel).trim().isNotEmpty)
        ? (optionLabel ?? variantLabel)
        : (!_useCompactSelectedRow &&
                optionLabel != null &&
                optionLabel != variantLabel)
            ? optionLabel
            : null;

    return Container(
      color: effectiveStatus == 'DUPLICATE' || effectiveStatus == 'INVALID'
          ? const Color(0xFFFFF5F5)
          : _useCompactSelectedRow
              ? Colors.white
              : selected
                  ? const Color(0xFFFFF7ED)
                  : isComplete
                      ? const Color(0xFFF0FDF4)
                      : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (_showSelectionCheckbox)
            SizedBox(
              width: _selectWidth,
              child: isComplete && !selected
                  ? IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 28,
                        minHeight: 28,
                      ),
                      tooltip: 'Select to edit',
                      onPressed: () =>
                          onToggleSelect!(assignment.clientCombinationKey),
                      icon: const Icon(
                        Icons.check_circle,
                        size: 22,
                        color: completeGreen,
                      ),
                    )
                  : Checkbox(
                      value: selected,
                      activeColor: accent,
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      onChanged: (_) =>
                          onToggleSelect!(assignment.clientCombinationKey),
                    ),
            ),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                if (_useCompactSelectedRow)
                  const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: _SelectedDot(),
                  )
                else ...[
                  _VariantThumb(imageUrl: imageUrl),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        primaryLabel,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (secondaryLabel != null)
                        Text(
                          secondaryLabel,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: canEditInline
                ? _InlineField(
                    initialValue: displaySku,
                    hint: 'SKU',
                    enabled: true,
                    onChanged: (v) => onSkuChanged!(assignment, v),
                  )
                : inlineEditable && editOnlyWhenSelected
                    ? _InlineField(
                        initialValue: displaySku,
                        hint: selected ? 'SKU' : 'Select row to edit',
                        enabled: false,
                        isComplete: showCompleteFieldStyle,
                        onChanged: (_) {},
                      )
                    : Text(
                        hasSku ? assignment.sku! : '—',
                        style: TextStyle(
                          fontSize: 13,
                          color: hasSku ? accent : Colors.grey,
                          fontFamily: 'monospace',
                        ),
                      ),
          ),
          Expanded(
            flex: 2,
            child: canEditInline && onBarcodeChanged != null
                ? _InlineField(
                    initialValue: displayBarcode,
                    hint: 'Barcode',
                    enabled: true,
                    onChanged: (v) => onBarcodeChanged!(assignment, v),
                    onSubmitted: onScanComplete == null
                        ? null
                        : (v) => onScanComplete!(assignment, v),
                  )
                : inlineEditable &&
                        editOnlyWhenSelected &&
                        onBarcodeChanged != null
                    ? _InlineField(
                        initialValue: displayBarcode,
                        hint: selected ? 'Barcode' : 'Select row to edit',
                        enabled: false,
                        isComplete: showCompleteFieldStyle,
                        onChanged: (_) {},
                      )
                    : Text(
                        hasBarcode ? assignment.barcode! : '—',
                        style: TextStyle(
                          fontSize: 13,
                          color: hasBarcode
                              ? const Color(0xFF1D4ED8)
                              : Colors.grey,
                          fontFamily: 'monospace',
                        ),
                      ),
          ),
          if (_useCompactSelectedRow)
            SizedBox(
              width: _scanWidth,
              child: Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  tooltip: 'Scan to replace barcode',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 36, minHeight: 36),
                  icon: Icon(
                    Icons.crop_free,
                    size: 20,
                    color: Colors.grey.shade600,
                  ),
                  onPressed: () => onEdit(assignment, index),
                ),
              ),
            ),
          SizedBox(
            width: _statusWidth,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _StatusChip(status: effectiveStatus),
            ),
          ),
          SizedBox(
            width: _actionsWidth + (_useCompactSelectedRow ? 0 : 28),
            child: Align(
              alignment: _useCompactSelectedRow
                  ? Alignment.centerLeft
                  : Alignment.centerRight,
              child: _useCompactSelectedRow
                  ? IconButton(
                      tooltip: 'Edit SKU & Barcode',
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 36, minHeight: 36),
                      icon: Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: Colors.grey.shade700,
                      ),
                      onPressed: () => onEdit(assignment, index),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Scan barcode',
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          icon: Icon(
                            Icons.crop_free,
                            size: 18,
                            color: isComplete
                                ? const Color(0xFF2563EB)
                                : Colors.grey.shade600,
                          ),
                          onPressed: () => onEdit(assignment, index),
                        ),
                        PopupMenuButton<String>(
                          tooltip: 'Row actions',
                          icon: Icon(
                            Icons.more_vert,
                            size: 18,
                            color: Colors.grey.shade700,
                          ),
                          onSelected: (value) {
                            if (value == 'edit') {
                              onEdit(assignment, index);
                            } else if (value == 'clear' && onClear != null) {
                              onClear!(assignment);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Text('Edit SKU & Barcode'),
                            ),
                            const PopupMenuItem(
                              value: 'clear',
                              child: Text('Clear identifiers'),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectedDot extends StatelessWidget {
  const _SelectedDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: Color(0xFF22C55E),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _VariantThumb extends StatelessWidget {
  final String? imageUrl;

  const _VariantThumb({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl != null && imageUrl!.isNotEmpty
          ? Image.network(
              imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Icon(
                Icons.image_outlined,
                size: 18,
                color: Colors.grey.shade400,
              ),
            )
          : Icon(Icons.image_outlined, size: 18, color: Colors.grey.shade400),
    );
  }
}

class _InlineField extends StatefulWidget {
  final String initialValue;
  final String hint;
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;
  final bool isComplete;

  const _InlineField({
    required this.initialValue,
    required this.hint,
    required this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.isComplete = false,
  });

  @override
  State<_InlineField> createState() => _InlineFieldState();
}

class _InlineFieldState extends State<_InlineField> {
  late final TextEditingController _controller;
  late final FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _focus = FocusNode();
  }

  @override
  void didUpdateWidget(covariant _InlineField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focus.hasFocus && widget.initialValue != _controller.text) {
      _controller.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const completeGreen = Color(0xFF22C55E);
    const completeBorder = Color(0xFF86EFAC);
    const completeFill = Color(0xFFF0FDF4);
    final complete = widget.isComplete && widget.initialValue.trim().isNotEmpty;

    return TextField(
      controller: _controller,
      focusNode: _focus,
      enabled: widget.enabled,
      readOnly: complete && !widget.enabled,
      style: TextStyle(
        fontSize: 13,
        fontFamily: 'monospace',
        fontWeight: complete ? FontWeight.w600 : FontWeight.w400,
        color: widget.enabled || complete
            ? TenantAdminColors.bodyText
            : Colors.grey.shade500,
      ),
      decoration: InputDecoration(
        isDense: true,
        hintText: widget.hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
        filled: !widget.enabled || complete,
        fillColor: complete
            ? completeFill
            : (widget.enabled ? null : Colors.grey.shade100),
        suffixIcon: complete
            ? const Icon(
                Icons.check_circle,
                size: 18,
                color: completeGreen,
              )
            : null,
        suffixIconConstraints: complete
            ? const BoxConstraints(minWidth: 32, minHeight: 28)
            : null,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(
            color: complete ? completeBorder : Colors.grey.shade200,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(
            color: complete ? completeBorder : Colors.grey.shade200,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(
            color: complete ? completeBorder : Colors.grey.shade200,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(
            color: complete
                ? completeGreen
                : TenantAdminColors.posHomeAccentOrange,
          ),
        ),
      ),
      inputFormatters: [
        // Preserve leading zeros — never coerce to number.
        FilteringTextInputFormatter.deny(RegExp(r'[\n\r]')),
      ],
      onChanged: widget.enabled ? widget.onChanged : null,
      onSubmitted: widget.enabled ? widget.onSubmitted : null,
      textInputAction: TextInputAction.done,
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final isDuplicate = status == 'DUPLICATE';
    final isInvalid = status == 'INVALID';
    final isComplete = status == 'COMPLETE';
    final isError = isDuplicate || isInvalid;

    final bgColor = isError
        ? const Color(0xFFFEE2E2)
        : isComplete
            ? const Color(0xFFDCFCE7)
            : const Color(0xFFFEF3C7);
    final fgColor = isError
        ? const Color(0xFFDC2626)
        : isComplete
            ? const Color(0xFF16A34A)
            : const Color(0xFFB45309);
    final label = isDuplicate
        ? 'Duplicate'
        : isInvalid
            ? 'Invalid'
            : isComplete
                ? 'Complete'
                : 'Incomplete';

    final icon = isError
        ? Icons.error_outline
        : isComplete
            ? Icons.check_circle
            : Icons.radio_button_unchecked;

    return Semantics(
      label: 'Status $label',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: fgColor),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: fgColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Step5VariantIdentifierToolbar extends StatefulWidget {
  final String searchQuery;
  final Step5StatusFilter statusFilter;
  final int completeCount;
  final int totalCount;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<Step5StatusFilter> onFilterChanged;

  const Step5VariantIdentifierToolbar({
    super.key,
    required this.searchQuery,
    required this.statusFilter,
    required this.completeCount,
    required this.totalCount,
    required this.onSearchChanged,
    required this.onFilterChanged,
  });

  @override
  State<Step5VariantIdentifierToolbar> createState() =>
      _Step5VariantIdentifierToolbarState();
}

class _Step5VariantIdentifierToolbarState
    extends State<Step5VariantIdentifierToolbar> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.searchQuery);
  }

  @override
  void didUpdateWidget(covariant Step5VariantIdentifierToolbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchQuery != _searchController.text) {
      _searchController.text = widget.searchQuery;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search Variants',
              prefixIcon: const Icon(Icons.search, size: 18),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            onChanged: widget.onSearchChanged,
          ),
        ),
        const SizedBox(width: 12),
        PopupMenuButton<Step5StatusFilter>(
          tooltip: 'Filter by status',
          initialValue: widget.statusFilter,
          onSelected: widget.onFilterChanged,
          itemBuilder: (_) => const [
            PopupMenuItem(value: Step5StatusFilter.all, child: Text('All')),
            PopupMenuItem(
                value: Step5StatusFilter.complete, child: Text('Complete')),
            PopupMenuItem(
                value: Step5StatusFilter.incomplete,
                child: Text('Incomplete')),
            PopupMenuItem(value: Step5StatusFilter.error, child: Text('Error')),
          ],
          child: OutlinedButton.icon(
            onPressed: null,
            icon: const Icon(Icons.filter_list, size: 16),
            label: Text(_filterLabel(widget.statusFilter)),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: widget.completeCount == widget.totalCount &&
                    widget.totalCount > 0
                ? const Color(0xFFDCFCE7)
                : const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${widget.completeCount} of ${widget.totalCount} complete',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: widget.completeCount == widget.totalCount &&
                      widget.totalCount > 0
                  ? const Color(0xFF16A34A)
                  : const Color(0xFFB45309),
            ),
          ),
        ),
      ],
    );
  }

  String _filterLabel(Step5StatusFilter filter) {
    switch (filter) {
      case Step5StatusFilter.all:
        return 'Filter';
      case Step5StatusFilter.complete:
        return 'Complete';
      case Step5StatusFilter.incomplete:
        return 'Incomplete';
      case Step5StatusFilter.error:
        return 'Error';
    }
  }
}
