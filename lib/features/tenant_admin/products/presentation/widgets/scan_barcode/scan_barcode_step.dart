import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nytroz_pos/features/sale/application/services/pos_hid_scanner_input_service.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/theme/tenant_admin_theme.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/add_product_wizard_state.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/scan_barcode_step_state.dart';
import 'package:nytroz_pos/features/tenant_admin/products/presentation/controllers/add_product_wizard_controller.dart';
import 'package:nytroz_pos/features/tenant_admin/products/presentation/widgets/product_form_fields.dart';
import 'package:nytroz_pos/features/tenant_admin/products/presentation/widgets/product_wizard_action_buttons.dart';

/// Global Step 1 — Scan Barcode internal panels (S1-A … S1-R3).
/// Visual family matches supplied Product Setup screens (cards, orange accent,
/// compact density). Journey logic stays in [AddProductWizardController].
class ScanBarcodeStep extends ConsumerStatefulWidget {
  const ScanBarcodeStep({
    super.key,
    required this.state,
    required this.controller,
  });

  final AddProductWizardState state;
  final AddProductWizardController controller;

  @override
  ConsumerState<ScanBarcodeStep> createState() => _ScanBarcodeStepState();
}

class _ManualBarcodeFeedback {
  final String primaryStatus;
  final String secondaryInstruction;
  final bool isValidLength;
  final bool isError;

  _ManualBarcodeFeedback({
    required this.primaryStatus,
    required this.secondaryInstruction,
    required this.isValidLength,
    this.isError = false,
  });

  factory _ManualBarcodeFeedback.from(int length) {
    if (length == 0) {
      return _ManualBarcodeFeedback(
        primaryStatus: 'Auto-detected',
        secondaryInstruction: 'Must be 8, 12, 13 or 14 digits',
        isValidLength: false,
      );
    }
    if (length > 14) {
      return _ManualBarcodeFeedback(
        primaryStatus: 'Unsupported barcode length',
        secondaryInstruction: 'GTIN must contain 8, 12, 13 or 14 digits.',
        isValidLength: false,
        isError: true,
      );
    }
    if (length < 8) {
      return _ManualBarcodeFeedback(
        primaryStatus: 'Detecting...',
        secondaryInstruction: 'Minimum 8 digits required',
        isValidLength: false,
      );
    }
    if (length > 8 && length < 12) {
      return _ManualBarcodeFeedback(
        primaryStatus: 'Detecting...',
        secondaryInstruction: 'Continue to 12, 13 or 14 digits',
        isValidLength: false,
      );
    }
    switch (length) {
      case 8:
        return _ManualBarcodeFeedback(
          primaryStatus: 'Possible GTIN-8',
          secondaryInstruction: 'Supported length',
          isValidLength: true,
        );
      case 12:
        return _ManualBarcodeFeedback(
          primaryStatus: 'Possible GTIN-12 / UPC',
          secondaryInstruction: 'Supported length',
          isValidLength: true,
        );
      case 13:
        return _ManualBarcodeFeedback(
          primaryStatus: 'Possible GTIN-13 / EAN',
          secondaryInstruction: 'Supported length',
          isValidLength: true,
        );
      case 14:
        return _ManualBarcodeFeedback(
          primaryStatus: 'Possible GTIN-14',
          secondaryInstruction: 'Supported length',
          isValidLength: true,
        );
    }
    return _ManualBarcodeFeedback(
      primaryStatus: 'Detecting...',
      secondaryInstruction: '',
      isValidLength: false,
    );
  }
}

class _ScanBarcodeStepState extends ConsumerState<ScanBarcodeStep> {
  late final TextEditingController _manualBarcodeController;
  late final TextEditingController _noBarcodeNameController;
  PosHidScannerInputService? _hid;
  bool _hidListening = false;

  @override
  void initState() {
    super.initState();
    _manualBarcodeController = TextEditingController(
      text: widget.state.scanStepState.candidateBarcode,
    );
    _noBarcodeNameController = TextEditingController(
      text: widget.state.scanStepState.noBarcodeProductName,
    );
    _attachHidIfNeeded();
  }

  @override
  void didUpdateWidget(covariant ScanBarcodeStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    _attachHidIfNeeded();
    final scan = widget.state.scanStepState;
    if (scan.panel == ScanBarcodePanel.manualEntry &&
        _manualBarcodeController.text != scan.candidateBarcode &&
        !scan.isBusy) {
      _manualBarcodeController.text = scan.candidateBarcode;
    }
  }

  void _attachHidIfNeeded() {
    final shouldListen =
        widget.state.scanStepState.panel == ScanBarcodePanel.scanReady &&
            !widget.state.scanStepState.isBusy;
    if (shouldListen && !_hidListening) {
      _hid ??= PosHidScannerInputService(
        configuration: PosHidScannerConfiguration(),
        onScan: (barcode) async {
          await widget.controller.submitScanCandidate(barcode);
        },
      );
      _hid!.attach();
      _hidListening = true;
    } else if (!shouldListen && _hidListening) {
      _hid?.detach();
      _hidListening = false;
    }
  }

  @override
  void dispose() {
    _hid?.dispose();
    _manualBarcodeController.dispose();
    _noBarcodeNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scan = widget.state.scanStepState;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_titleFor(scan.panel) != null)
          Text(
            _titleFor(scan.panel)!,
            style: TenantAdminTextStyles.sectionTitle(context),
          ),
        if (_subtitleFor(scan.panel) != null) ...[
          const SizedBox(height: TenantAdminSpacing.xs),
          Text(
            _subtitleFor(scan.panel)!,
            style: TenantAdminTextStyles.muted(context),
          ),
        ],
        const SizedBox(height: TenantAdminSpacing.lg),
        if (scan.lastError != null) ...[
          _ErrorBanner(message: scan.lastError!),
          const SizedBox(height: TenantAdminSpacing.md),
        ],
        switch (scan.panel) {
          ScanBarcodePanel.scanReady => _buildScanReady(context, scan),
          ScanBarcodePanel.validating => _buildValidating(context, scan),
          ScanBarcodePanel.localMatch => _buildLocalMatch(context, scan),
          ScanBarcodePanel.noLocalMatch => _buildNoLocalMatch(context, scan),
          ScanBarcodePanel.externalLookup =>
            _buildExternalLookup(context, scan),
          ScanBarcodePanel.externalFound => _buildExternalFound(context, scan),
          ScanBarcodePanel.externalNoMatch =>
            _buildExternalNoMatch(context, scan),
          ScanBarcodePanel.manualEntry => _buildManualEntry(context, scan),
          ScanBarcodePanel.invalid => _buildInvalid(context, scan),
          ScanBarcodePanel.noBarcode => _buildNoBarcode(context, scan),
        },
      ],
    );
  }

  String? _titleFor(ScanBarcodePanel panel) {
    return switch (panel) {
      ScanBarcodePanel.scanReady => 'Scan Product Barcode',
      ScanBarcodePanel.validating => 'Barcode Detected',
      ScanBarcodePanel.localMatch => 'Existing Product Found',
      ScanBarcodePanel.noLocalMatch => 'No local match found',
      ScanBarcodePanel.externalLookup => 'Searching Product Data',
      ScanBarcodePanel.externalFound => 'Product Found',
      ScanBarcodePanel.externalNoMatch => null,
      ScanBarcodePanel.manualEntry => 'Enter Barcode Manually',
      ScanBarcodePanel.invalid => 'Invalid Barcode',
      ScanBarcodePanel.noBarcode => 'Create Product Without Barcode',
    };
  }

  String? _subtitleFor(ScanBarcodePanel panel) {
    return switch (panel) {
      ScanBarcodePanel.scanReady =>
        'Scan a barcode to search your catalogue, or enter details manually.',
      ScanBarcodePanel.validating =>
        'Validating format and checking your catalogue.',
      ScanBarcodePanel.localMatch =>
        'This barcode already exists in your catalogue.',
      ScanBarcodePanel.noLocalMatch =>
        'Barcode is valid but not in your catalogue yet.',
      ScanBarcodePanel.externalLookup =>
        'Looking up product data for this barcode.',
      ScanBarcodePanel.externalFound => null,
      ScanBarcodePanel.externalNoMatch => null,
      ScanBarcodePanel.manualEntry =>
        'Enter the barcode digits. Leading zeros are preserved.',
      ScanBarcodePanel.invalid =>
        'This barcode could not be validated. Try again or continue without one.',
      ScanBarcodePanel.noBarcode =>
        'Select a reason and enter the minimum details to continue.',
    };
  }

  Widget _buildScanReady(BuildContext context, ScanBarcodeStepState scan) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _PanelCard(
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: TenantAdminSpacing.lg,
                        horizontal: TenantAdminSpacing.xl,
                      ),
                      decoration: BoxDecoration(
                        color: TenantAdminColors.subtleBackground,
                        borderRadius:
                            BorderRadius.circular(TenantAdminRadius.md),
                        border: Border.all(color: TenantAdminColors.border),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              color: TenantAdminColors.secondary,
                              borderRadius:
                                  BorderRadius.circular(TenantAdminRadius.lg),
                              border: Border.all(
                                color: TenantAdminColors.primary.withValues(
                                  alpha: 0.35,
                                ),
                              ),
                            ),
                            child: const Icon(
                              Icons.qr_code_scanner,
                              size: 44,
                              color: TenantAdminColors.primary,
                            ),
                          ),
                          const SizedBox(height: TenantAdminSpacing.md),
                          Text(
                            'Point your scanner at a product barcode',
                            style: TenantAdminTextStyles.body(context).copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: TenantAdminSpacing.sm),
                          Text(
                            'HID scanner input is ready on this screen.',
                            style: TenantAdminTextStyles.muted(context),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: TenantAdminSpacing.lg),
                          _StatusChip(
                            label: 'Waiting for scan',
                            tone: _ChipTone.active,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: TenantAdminSpacing.lg),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _ShortcutCard(
                            onTap: scan.isBusy
                                ? null
                                : () =>
                                    widget.controller.openManualBarcodeEntry(),
                            icon: Icons.keyboard_outlined,
                            title: 'Enter barcode manually',
                          ),
                        ),
                        const SizedBox(width: TenantAdminSpacing.md),
                        Expanded(
                          child: _ShortcutCard(
                            onTap: scan.isBusy
                                ? null
                                : () => widget.controller.openNoBarcodeFlow(),
                            icon: Icons.add,
                            title: 'Product has no barcode',
                            subtitle: 'Create manually',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValidating(BuildContext context, ScanBarcodeStepState scan) {
    return _PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _BarcodeHero(value: scan.candidateBarcode),
          const SizedBox(height: TenantAdminSpacing.lg),
          _StatusRow(
            label: 'Barcode Format',
            value: scan.barcodeType ?? 'Detecting…',
            tone: scan.barcodeType == null ? _ChipTone.pending : _ChipTone.ok,
          ),
          const SizedBox(height: TenantAdminSpacing.sm),
          _StatusRow(
            label: 'GTIN Check Digit',
            value: 'Validating',
            tone: _ChipTone.pending,
          ),
          const SizedBox(height: TenantAdminSpacing.sm),
          _StatusRow(
            label: 'Checking Your Catalogue',
            value: 'In progress',
            tone: _ChipTone.pending,
          ),
          const SizedBox(height: TenantAdminSpacing.lg),
          const LinearProgressIndicator(
            minHeight: 3,
            color: TenantAdminColors.primary,
            backgroundColor: TenantAdminColors.border,
          ),
        ],
      ),
    );
  }

  Widget _buildLocalMatch(BuildContext context, ScanBarcodeStepState scan) {
    final match = scan.localMatch;
    if (match == null) {
      return const Text('Local match data missing.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PanelCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if ((match.imageUrl ?? '').isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(TenantAdminRadius.md),
                      child: Image.network(
                        match.imageUrl!,
                        width: 96,
                        height: 96,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                  const Spacer(),
                  if (match.canViewProduct || match.canEditProduct)
                    Wrap(
                      spacing: TenantAdminSpacing.sm,
                      children: [
                        if (match.canViewProduct)
                          FilledButton(
                            onPressed: () => context.go(
                              '/tenant-admin/products/${match.productId}',
                            ),
                            child: const Text('View Product'),
                          ),
                        if (match.canEditProduct)
                          OutlinedButton(
                            onPressed: () => context.go(
                              '/tenant-admin/products/draft/${match.productId}',
                            ),
                            child: const Text('Edit Existing Product'),
                          ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: TenantAdminSpacing.md),
              _LabelValue('Product Name', match.productName),
              if ((match.variantLabel ?? '').isNotEmpty)
                _LabelValue('Variant', match.variantLabel!),
              if ((match.brand ?? '').isNotEmpty)
                _LabelValue('Brand', match.brand!),
              if ((match.category ?? '').isNotEmpty)
                _LabelValue('Category', match.category!),
              if (match.sellingPrice != null)
                _LabelValue(
                  'Selling Price',
                  '${match.currency ?? ''} ${match.sellingPrice}'.trim(),
                ),
              _LabelValue('Primary GTIN / Barcode', scan.candidateBarcode),
              if (scan.barcodeType != null)
                _LabelValue('Barcode Type', scan.barcodeType!),
              if ((match.sku ?? '').isNotEmpty) _LabelValue('SKU', match.sku!),
              _LabelValue('Status', match.status),
            ],
          ),
        ),
        const SizedBox(height: TenantAdminSpacing.lg),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            OutlinedButton(
              onPressed: () {
                if (scan.inputMode == 'MANUAL') {
                  widget.controller.openManualBarcodeEntry();
                } else {
                  widget.controller.backToScan();
                }
              },
              child: const Text('Back'),
            ),
            FilledButton.tonal(
              onPressed: scan.isBusy
                  ? null
                  : () => widget.controller.createDuplicateFromLocalMatch(),
              child: scan.isBusy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Create Duplicate'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNoLocalMatch(BuildContext context, ScanBarcodeStepState scan) {
    final isTempFailure =
        (scan.externalStatus ?? '').toUpperCase() == 'TEMPORARY_FAILURE' ||
            (scan.lastError ?? '').toLowerCase().contains('temporarily');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PanelCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _BarcodeHero(value: scan.candidateBarcode),
              const SizedBox(height: TenantAdminSpacing.md),
              Text(
                isTempFailure
                    ? 'External lookup is temporarily unavailable. Retry search or continue manually.'
                    : 'This barcode is valid, but no matching product was found in your catalogue.',
                style: TenantAdminTextStyles.muted(context),
              ),
              if (scan.identifierStandard != null) ...[
                const SizedBox(height: TenantAdminSpacing.md),
                _LabelValue('Identifier standard', scan.identifierStandard!),
              ],
            ],
          ),
        ),
        const SizedBox(height: TenantAdminSpacing.lg),
        Wrap(
          spacing: TenantAdminSpacing.md,
          runSpacing: TenantAdminSpacing.sm,
          children: [
            FilledButton(
              onPressed: scan.isBusy
                  ? null
                  : () => widget.controller.runExternalLookup(),
              child: Text(
                isTempFailure
                    ? 'Retry Search Product Data'
                    : 'Search Product Data',
              ),
            ),
            OutlinedButton(
              onPressed: scan.isBusy
                  ? null
                  : () => widget.controller.continueCreateManually(
                        applyExternalPrefill: false,
                      ),
              child: const Text('Enter details manually'),
            ),
            OutlinedButton(
              onPressed: () =>
                  widget.controller.backToScan(clearValidatedCandidate: false),
              child: const Text('Back'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExternalLookup(
    BuildContext context,
    ScanBarcodeStepState scan,
  ) {
    return _PanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _BarcodeHero(value: scan.candidateBarcode),
          const SizedBox(height: TenantAdminSpacing.lg),
          Row(
            children: [
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: TenantAdminColors.primary,
                ),
              ),
              const SizedBox(width: TenantAdminSpacing.md),
              Expanded(
                child: Text(
                  'Searching product data…',
                  style: TenantAdminTextStyles.body(context).copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: TenantAdminSpacing.md),
          const LinearProgressIndicator(
            minHeight: 3,
            color: TenantAdminColors.primary,
            backgroundColor: TenantAdminColors.border,
          ),
        ],
      ),
    );
  }

  Widget _buildExternalFound(BuildContext context, ScanBarcodeStepState scan) {
    final s = scan.externalSuggestion;

    final imageSection = Container(
      width: double.infinity,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: TenantAdminColors.subtleBackground,
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
      ),
      child: (s?.imageCandidate ?? '').isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(TenantAdminRadius.md),
              child: Image.network(
                s!.imageCandidate!,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(Icons.image_not_supported, size: 48, color: TenantAdminColors.border),
                ),
              ),
            )
          : const Center(
              child: Icon(Icons.image_not_supported, size: 48, color: TenantAdminColors.border),
            ),
    );

    // Middle side: details
    final detailsSection = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                s?.productName ?? 'Unknown Product',
                style: TenantAdminTextStyles.sectionTitle(context).copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5EF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFD3EADD)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: TenantAdminColors.primary, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Verified',
                    style: TenantAdminTextStyles.body(context).copyWith(
                      color: TenantAdminColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: TenantAdminSpacing.sm),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: TenantAdminSpacing.sm, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F0FE), // Light blue
            borderRadius: BorderRadius.circular(TenantAdminRadius.md),
            border: Border.all(color: const Color(0xFFD2E3FC)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Color(0xFF1967D2), size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Please review the details before importing.',
                  style: TenantAdminTextStyles.body(context).copyWith(
                    color: const Color(0xFF1967D2),
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (s?.brandText != null) _CompactLabelValue('Brand', s!.brandText!),
        if (s?.categoryText != null) _CompactLabelValue('Category', s!.categoryText!),
        if (s?.unitText != null) _CompactLabelValue('Unit', s!.unitText!),
        if (s?.countryCode != null) _CompactLabelValue('Country', s!.countryCode!),
        if (s?.shortDescription != null) _CompactLabelValue('Description', s!.shortDescription!),
        if (s?.primaryGtin != null) _CompactLabelValue('Primary GTIN', s!.primaryGtin!),
        if (scan.barcodeType != null) _CompactLabelValue('Barcode Type', scan.barcodeType!),
      ],
    );

    // Right card: What's next
    final whatsNextCard = Container(
      padding: const EdgeInsets.all(TenantAdminSpacing.xl),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        border: Border.all(color: TenantAdminColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "What's next?",
            style: TenantAdminTextStyles.sectionTitle(context).copyWith(
              fontSize: 18,
            ),
          ),
          const SizedBox(height: TenantAdminSpacing.md),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFFFFF7F2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.assignment_outlined, color: Color(0xFFFF6B00), size: 32),
          ),
          const SizedBox(height: TenantAdminSpacing.md),
          Text(
            "We'll pre-fill the next steps using this information.",
            style: TenantAdminTextStyles.body(context).copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: TenantAdminSpacing.sm),
          Text(
            "You can review and edit anything before completing the setup.",
            style: TenantAdminTextStyles.muted(context),
          ),
          const SizedBox(height: TenantAdminSpacing.xl),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: TenantAdminColors.border),
                foregroundColor: TenantAdminColors.bodyText,
              ),
              onPressed: scan.isBusy
                  ? null
                  : () => widget.controller.backToNoLocalMatch(),
              child: const Text('Search Again', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left main card
                Expanded(
                  flex: 7,
                  child: _PanelCard(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: imageSection,
                        ),
                        const SizedBox(width: TenantAdminSpacing.xl),
                        Expanded(
                          flex: 5,
                          child: detailsSection,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: TenantAdminSpacing.lg),
                // Right card
                Expanded(
                  flex: 3,
                  child: whatsNextCard,
                ),
              ],
            ),
          ),
          const SizedBox(height: TenantAdminSpacing.lg),
          Row(
            children: [
              ProductWizardBackButton(
                onPressed: () => widget.controller.backToNoLocalMatch(),
                label: 'Back',
              ),
              const SizedBox(width: TenantAdminSpacing.md),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: TenantAdminColors.bodyText,
                  side: const BorderSide(color: TenantAdminColors.border),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
                  ),
                ),
                onPressed: scan.isBusy
                    ? null
                    : () => widget.controller.continueCreateManually(
                          applyExternalPrefill: false,
                        ),
                icon: const Icon(Icons.add_circle_outline, size: 18),
                label: const Text('Create Manually', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
              const Spacer(),
              ProductWizardContinueButton(
                onPressed: scan.isBusy
                    ? null
                    : () => widget.controller.continueUseThisProduct(),
                label: 'Use This Product',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExternalNoMatch(
    BuildContext context,
    ScanBarcodeStepState scan,
  ) {
    return Expanded(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Green Card
            Container(
              padding: const EdgeInsets.all(TenantAdminSpacing.xl),
              decoration: BoxDecoration(
                color: const Color(0xFFF7FBF9),
                border: Border.all(color: const Color(0xFFD3EADD)),
                borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
              ),
              child: Row(
                children: [
                  // Barcode Icon Stack
                  Stack(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE8F5EF),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.qr_code_scanner,
                            color: TenantAdminColors.primary,
                            size: 40,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: TenantAdminColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: TenantAdminSpacing.xl),
                  // Barcode Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          scan.inputMode == 'MANUAL'
                              ? 'Manually entered barcode'
                              : 'Scanned barcode',
                          style: TenantAdminTextStyles.muted(context),
                        ),
                        const SizedBox(height: TenantAdminSpacing.xs),
                        Text(
                          scan.candidateBarcode,
                          style: TenantAdminTextStyles.sectionTitle(context)
                              .copyWith(
                            fontSize: 32,
                            letterSpacing: 2.0,
                          ),
                        ),
                        const SizedBox(height: TenantAdminSpacing.sm),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5EF),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle_outline,
                                      color: TenantAdminColors.primary,
                                      size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Valid barcode',
                                    style: TenantAdminTextStyles.body(context)
                                        .copyWith(
                                      color: TenantAdminColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: TenantAdminSpacing.md),
                            const Text('|',
                                style:
                                    TextStyle(color: TenantAdminColors.border)),
                            const SizedBox(width: TenantAdminSpacing.md),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                border:
                                    Border.all(color: TenantAdminColors.border),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                scan.identifierStandard ??
                                    scan.barcodeType ??
                                    'GTIN',
                                style: TenantAdminTextStyles.body(context)
                                    .copyWith(
                                  color: TenantAdminColors.bodyText,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: TenantAdminSpacing.lg),
            // Middle Orange Card
            Container(
              padding: const EdgeInsets.all(TenantAdminSpacing.xl),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7F2),
                border: Border.all(color: const Color(0xFFFFE0CC)),
                borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left text section
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.error_outline,
                                color: Color(0xFFFF6B00), size: 28),
                            const SizedBox(width: TenantAdminSpacing.sm),
                            Expanded(
                              child: Text(
                                'Product data not found',
                                style: TenantAdminTextStyles.sectionTitle(context)
                                    .copyWith(
                                  fontSize: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: TenantAdminSpacing.md),
                        Text(
                          "We couldn't find product information for this barcode in your catalogue or external product sources.",
                          style: TenantAdminTextStyles.body(context).copyWith(
                            color: const Color(0xFF4A4A4A),
                          ),
                        ),
                        const SizedBox(height: TenantAdminSpacing.md),
                        Text(
                          "The barcode is valid, but no matching product data was found.\nYou can continue and enter the product details manually.",
                          style: TenantAdminTextStyles.muted(context).copyWith(
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: TenantAdminSpacing.xl),
                  // Right actionable card
                  Expanded(
                    flex: 4,
                    child: Container(
                      padding: const EdgeInsets.all(TenantAdminSpacing.xl),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(TenantAdminRadius.md),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFFF7F2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.edit_outlined,
                                    color: Color(0xFFFF6B00), size: 24),
                              ),
                              const SizedBox(width: TenantAdminSpacing.sm),
                              Expanded(
                                child: Text(
                                  'Continue with this barcode and create manually',
                                  style: TenantAdminTextStyles.body(context)
                                      .copyWith(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: TenantAdminSpacing.sm),
                          Text(
                            'Use this valid barcode and enter the product details yourself.',
                            style:
                                TenantAdminTextStyles.muted(context).copyWith(
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: TenantAdminSpacing.lg),
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton(
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 20),
                                    backgroundColor: const Color(0xFFFF6B00),
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: scan.isBusy
                                      ? null
                                      : () => widget.controller
                                          .continueWithBarcode(),
                                  child: scan.isBusy
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white),
                                        )
                                      : const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              'Continue',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            SizedBox(width: 4),
                                            Icon(Icons.chevron_right, size: 20),
                                          ],
                                        ),
                                ),
                              ),
                              const SizedBox(width: TenantAdminSpacing.sm),
                              Expanded(
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 20),
                                    side: const BorderSide(
                                        color: TenantAdminColors.border),
                                    foregroundColor: TenantAdminColors.bodyText,
                                  ),
                                  onPressed: () {
                                    if (scan.inputMode == 'MANUAL') {
                                      widget.controller
                                          .openManualBarcodeEntry();
                                    } else {
                                      widget.controller.backToScan();
                                    }
                                  },
                                  child: const Text(
                                    'Cancel',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: TenantAdminSpacing.lg),
            // Bottom Blue Tip
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: TenantAdminSpacing.lg,
                  vertical: TenantAdminSpacing.md),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F8FF),
                border: Border.all(color: const Color(0xFFCCE4FF)),
                borderRadius: BorderRadius.circular(TenantAdminRadius.md),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline,
                      color: Color(0xFF0066CC), size: 20),
                  const SizedBox(width: TenantAdminSpacing.sm),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: TenantAdminTextStyles.body(context).copyWith(
                          color: const Color(0xFF0066CC),
                          fontSize: 13,
                        ),
                        children: const [
                          TextSpan(
                              text: 'Tip: ',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                          TextSpan(
                              text:
                                  "The barcode will be retained when you continue. You'll be taken to the Basic Details step to enter the product information manually."),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManualEntry(BuildContext context, ScanBarcodeStepState scan) {
    final val = _manualBarcodeController.text;
    final len = val.length;
    final feedback = _ManualBarcodeFeedback.from(len);

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _PanelCard(
              child: LayoutBuilder(builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 600;

                final mainArea = Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _manualBarcodeController,
                      keyboardType: TextInputType.number,
                      style:
                          TenantAdminTextStyles.sectionTitle(context).copyWith(
                        fontSize: 28,
                        letterSpacing: 2.0,
                      ),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(
                          Icons.qr_code,
                          color: TenantAdminColors.bodyText,
                          size: 28,
                        ),
                        suffixIcon: _manualBarcodeController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  _manualBarcodeController.clear();
                                  widget.controller
                                      .updateManualBarcodeDraft('');
                                  setState(() {});
                                },
                              )
                            : null,
                        focusedBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(TenantAdminRadius.md),
                          borderSide: const BorderSide(
                            color: TenantAdminColors.primary,
                            width: 2,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(TenantAdminRadius.md),
                          borderSide: const BorderSide(
                            color: TenantAdminColors.primary,
                            width: 1,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: TenantAdminSpacing.lg,
                          vertical: TenantAdminSpacing.md,
                        ),
                      ),
                      onChanged: (val) {
                        widget.controller.updateManualBarcodeDraft(val);
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: TenantAdminSpacing.sm),
                    _BarcodeStatusRow(
                      feedback: feedback,
                      digitCount: len,
                    ),
                    const SizedBox(height: TenantAdminSpacing.sm),
                    Expanded(
                      child: _NumericBarcodeKeypad(
                        onDigit: (digit) {
                          if (_manualBarcodeController.text.length < 14) {
                            _manualBarcodeController.text += digit;
                            widget.controller.updateManualBarcodeDraft(
                                _manualBarcodeController.text);
                            setState(() {});
                          }
                        },
                        onBackspace: () {
                          if (_manualBarcodeController.text.isNotEmpty) {
                            _manualBarcodeController.text =
                                _manualBarcodeController.text.substring(0,
                                    _manualBarcodeController.text.length - 1);
                            widget.controller.updateManualBarcodeDraft(
                                _manualBarcodeController.text);
                            setState(() {});
                          }
                        },
                      ),
                    ),
                  ],
                );

                final quickEntry = _QuickGtinLengthSelector(
                  selectedLength: len,
                  onLengthSelected: (l) {
                    final current = _manualBarcodeController.text;
                    final padded = current.padLeft(l, '0');
                    _manualBarcodeController.text = padded;
                    widget.controller.updateManualBarcodeDraft(padded);
                    setState(() {});
                  },
                  onClearAll: () {
                    _manualBarcodeController.clear();
                    widget.controller.updateManualBarcodeDraft('');
                    setState(() {});
                  },
                );

                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(flex: 7, child: mainArea),
                      const SizedBox(width: TenantAdminSpacing.xl),
                      Expanded(
                        flex: 4,
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: quickEntry,
                        ),
                      ),
                    ],
                  );
                } else {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: mainArea),
                      const SizedBox(height: TenantAdminSpacing.lg),
                      quickEntry,
                    ],
                  );
                }
              }),
            ),
          ),
          const SizedBox(height: TenantAdminSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlinedButton.icon(
                onPressed: () => widget.controller.backToScan(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back to Scan'),
              ),
              TextButton(
                onPressed: () => widget.controller.openNoBarcodeFlow(),
                style: TextButton.styleFrom(
                  foregroundColor: TenantAdminColors.primary,
                  textStyle:
                      const TextStyle(decoration: TextDecoration.underline),
                ),
                child: const Text('Product has no barcode'),
              ),
              FilledButton(
                onPressed: scan.isBusy || !feedback.isValidLength
                    ? null
                    : () => widget.controller.validateManualBarcode(),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: TenantAdminSpacing.xl,
                    vertical: TenantAdminSpacing.md,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Validate Barcode'),
                    SizedBox(width: TenantAdminSpacing.sm),
                    Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInvalid(BuildContext context, ScanBarcodeStepState scan) {
    final isManual = scan.inputMode == 'MANUAL';
    return Expanded(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Red Card (Invalid Status)
            Container(
              padding: const EdgeInsets.all(TenantAdminSpacing.xl),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7F7),
                border: Border.all(color: const Color(0xFFFFD6D6)),
                borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
              ),
              child: Row(
                children: [
                  // Barcode Icon Stack
                  Stack(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFEBEB),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.qr_code_scanner,
                            color: Color(0xFFE53935),
                            size: 40,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0xFFE53935),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: TenantAdminSpacing.xl),
                  // Barcode Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isManual
                              ? 'Manually entered barcode'
                              : 'Scanned barcode',
                          style: TenantAdminTextStyles.muted(context),
                        ),
                        const SizedBox(height: TenantAdminSpacing.xs),
                        Text(
                          scan.candidateBarcode.isEmpty
                              ? 'Unknown'
                              : scan.candidateBarcode,
                          style: TenantAdminTextStyles.sectionTitle(context)
                              .copyWith(
                            fontSize: 32,
                            letterSpacing: 2.0,
                          ),
                        ),
                        const SizedBox(height: TenantAdminSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEBEB),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.cancel_outlined,
                                  color: Color(0xFFE53935), size: 16),
                              const SizedBox(width: 4),
                              Text(
                                'Invalid barcode',
                                style: TenantAdminTextStyles.body(context)
                                    .copyWith(
                                  color: const Color(0xFFE53935),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: TenantAdminSpacing.lg),
            // Middle Orange/Warning Card
            Container(
              padding: const EdgeInsets.all(TenantAdminSpacing.xl),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7F2),
                border: Border.all(color: const Color(0xFFFFE0CC)),
                borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left text section
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded,
                                color: Color(0xFFFF6B00), size: 28),
                            const SizedBox(width: TenantAdminSpacing.sm),
                            Text(
                              'Invalid Barcode',
                              style: TenantAdminTextStyles.sectionTitle(context)
                                  .copyWith(
                                fontSize: 20,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: TenantAdminSpacing.md),
                        Text(
                          'This barcode could not be validated due to a structural or checksum error.',
                          style: TenantAdminTextStyles.body(context).copyWith(
                            color: const Color(0xFF4A4A4A),
                          ),
                        ),
                        const SizedBox(height: TenantAdminSpacing.md),
                        Text(
                          'Reason: ${scan.invalidReason ?? "Unknown Error"}',
                          style: TenantAdminTextStyles.muted(context).copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: TenantAdminSpacing.xl),
                  // Right actionable card
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.all(TenantAdminSpacing.lg),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(TenantAdminRadius.md),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFFF7F2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.refresh,
                                    color: Color(0xFFFF6B00), size: 20),
                              ),
                              const SizedBox(width: TenantAdminSpacing.sm),
                              Expanded(
                                child: Text(
                                  'Recovery Options',
                                  style: TenantAdminTextStyles.body(context)
                                      .copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: TenantAdminSpacing.sm),
                          Text(
                            'You can try again, rescan, or proceed without a barcode.',
                            style:
                                TenantAdminTextStyles.muted(context).copyWith(
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: TenantAdminSpacing.lg),
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFFFF6B00),
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: () => widget.controller
                                      .openManualBarcodeEntry(),
                                  child: const Text('Try Again'),
                                ),
                              ),
                              const SizedBox(width: TenantAdminSpacing.sm),
                              Expanded(
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                        color: TenantAdminColors.border),
                                    foregroundColor: TenantAdminColors.bodyText,
                                  ),
                                  onPressed: () =>
                                      widget.controller.backToScan(),
                                  child: const Text('Rescan'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: TenantAdminSpacing.sm),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                    color: TenantAdminColors.border),
                                foregroundColor: TenantAdminColors.bodyText,
                              ),
                              onPressed: () =>
                                  widget.controller.openNoBarcodeFlow(),
                              child: const Text('Create Without Barcode'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoBarcode(BuildContext context, ScanBarcodeStepState scan) {
    Widget reasonCard({
      required String code,
      required String title,
      required String subtitle,
      required IconData icon,
    }) {
      final selected = scan.noBarcodeReason == code;
      return InkWell(
        onTap: () => widget.controller.setNoBarcodeReason(code),
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        child: Container(
          width: 220,
          padding: const EdgeInsets.all(TenantAdminSpacing.md),
          decoration: BoxDecoration(
            color: selected
                ? TenantAdminColors.secondary
                : TenantAdminColors.surface,
            borderRadius: BorderRadius.circular(TenantAdminRadius.md),
            border: Border.all(
              color: selected
                  ? TenantAdminColors.primary
                  : TenantAdminColors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                size: 22,
                color: selected
                    ? TenantAdminColors.primary
                    : TenantAdminColors.mutedText,
              ),
              const SizedBox(height: TenantAdminSpacing.sm),
              Text(title, style: TenantAdminTextStyles.cardTitle(context)),
              const SizedBox(height: 2),
              Text(subtitle, style: TenantAdminTextStyles.muted(context)),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: TenantAdminSpacing.md,
          runSpacing: TenantAdminSpacing.md,
          children: [
            reasonCard(
              code: 'OWN_MADE',
              title: 'Own-made Product',
              subtitle: 'Prepared or produced in-house.',
              icon: Icons.restaurant_outlined,
            ),
            reasonCard(
              code: 'SERVICE_FEE',
              title: 'Service / Fee',
              subtitle: 'Non-physical chargeable item.',
              icon: Icons.miscellaneous_services_outlined,
            ),
            reasonCard(
              code: 'UNLABELLED',
              title: 'Unlabelled Product',
              subtitle: 'Sold without a printed barcode.',
              icon: Icons.inventory_2_outlined,
            ),
          ],
        ),
        const SizedBox(height: TenantAdminSpacing.lg),
        _PanelCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _noBarcodeNameController,
                decoration: const InputDecoration(labelText: 'Product Name'),
                onChanged: widget.controller.updateNoBarcodeProductName,
              ),
              const SizedBox(height: TenantAdminSpacing.md),
              ProductOptionDropdown(
                label: 'Category *',
                hint: 'Select category',
                icon: Icons.category_outlined,
                value: scan.noBarcodeCategoryId ?? widget.state.categoryId,
                items: buildOptionItems(
                  options: (widget.state.createOptions?.categories ?? const [])
                      .map((item) => (id: item.id, label: item.name))
                      .toList(),
                  emptyLabel: 'No categories available',
                ),
                onChanged: widget.controller.setNoBarcodeCategoryId,
              ),
              const SizedBox(height: TenantAdminSpacing.md),
              Material(
                color: Colors.transparent,
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Auto-generate Internal SKU'),
                  value: scan.autoGenerateSku,
                  activeTrackColor: TenantAdminColors.success,
                  onChanged: (v) => widget.controller.setAutoGenerateSku(v),
                ),
              ),
              if (scan.autoGenerateSku &&
                  (scan.generatedSkuCandidate ?? '').isNotEmpty) ...[
                const Divider(height: 1, color: TenantAdminColors.border),
                const SizedBox(height: TenantAdminSpacing.md),
                _LabelValue('SKU candidate', scan.generatedSkuCandidate!),
                const SizedBox(height: TenantAdminSpacing.xs),
                Text(
                  'Preview only — not reserved until draft is created.',
                  style: TenantAdminTextStyles.muted(context),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: TenantAdminSpacing.lg),
        Wrap(
          spacing: TenantAdminSpacing.md,
          children: [
            FilledButton(
              onPressed: scan.isBusy
                  ? null
                  : () => widget.controller.continueNoBarcodeBootstrap(),
              child: const Text('Continue to Basic Details'),
            ),
            OutlinedButton(
              onPressed: () => widget.controller.backToScan(),
              child: const Text('Back'),
            ),
          ],
        ),
      ],
    );
  }

  List<Widget> _interleave(List<Widget> children, double gap) {
    if (children.isEmpty) return children;
    final out = <Widget>[children.first];
    for (var i = 1; i < children.length; i++) {
      out.add(SizedBox(height: gap));
      out.add(children[i]);
    }
    return out;
  }
}

class _BarcodeStatusRow extends StatelessWidget {
  const _BarcodeStatusRow({
    required this.feedback,
    required this.digitCount,
  });

  final _ManualBarcodeFeedback feedback;
  final int digitCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Barcode Type: ${feedback.primaryStatus}',
          style: TenantAdminTextStyles.muted(context).copyWith(
            color: feedback.isError ? TenantAdminColors.warning : null,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (feedback.isValidLength)
              const Icon(Icons.check,
                  size: 16, color: TenantAdminColors.success),
            if (feedback.isValidLength) const SizedBox(width: 4),
            Text(
              '$digitCount digits entered',
              style: TenantAdminTextStyles.muted(context).copyWith(
                color: feedback.isError ? TenantAdminColors.warning : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          feedback.secondaryInstruction,
          style: TenantAdminTextStyles.muted(context).copyWith(
            color: feedback.isError ? TenantAdminColors.warning : null,
          ),
        ),
      ],
    );
  }
}

class _NumericBarcodeKeypad extends StatelessWidget {
  const _NumericBarcodeKeypad({
    required this.onDigit,
    required this.onBackspace,
  });

  final void Function(String) onDigit;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(
                  child: _KeypadButton(label: '1', onTap: () => onDigit('1'))),
              const SizedBox(width: TenantAdminSpacing.sm),
              Expanded(
                  child: _KeypadButton(label: '2', onTap: () => onDigit('2'))),
              const SizedBox(width: TenantAdminSpacing.sm),
              Expanded(
                  child: _KeypadButton(label: '3', onTap: () => onDigit('3'))),
            ],
          ),
        ),
        const SizedBox(height: TenantAdminSpacing.sm),
        Expanded(
          child: Row(
            children: [
              Expanded(
                  child: _KeypadButton(label: '4', onTap: () => onDigit('4'))),
              const SizedBox(width: TenantAdminSpacing.sm),
              Expanded(
                  child: _KeypadButton(label: '5', onTap: () => onDigit('5'))),
              const SizedBox(width: TenantAdminSpacing.sm),
              Expanded(
                  child: _KeypadButton(label: '6', onTap: () => onDigit('6'))),
            ],
          ),
        ),
        const SizedBox(height: TenantAdminSpacing.sm),
        Expanded(
          child: Row(
            children: [
              Expanded(
                  child: _KeypadButton(label: '7', onTap: () => onDigit('7'))),
              const SizedBox(width: TenantAdminSpacing.sm),
              Expanded(
                  child: _KeypadButton(label: '8', onTap: () => onDigit('8'))),
              const SizedBox(width: TenantAdminSpacing.sm),
              Expanded(
                  child: _KeypadButton(label: '9', onTap: () => onDigit('9'))),
            ],
          ),
        ),
        const SizedBox(height: TenantAdminSpacing.sm),
        Expanded(
          child: Row(
            children: [
              const Expanded(child: SizedBox.shrink()),
              const SizedBox(width: TenantAdminSpacing.sm),
              Expanded(
                  child: _KeypadButton(label: '0', onTap: () => onDigit('0'))),
              const SizedBox(width: TenantAdminSpacing.sm),
              Expanded(
                child: _KeypadButton(
                  icon: Icons.backspace_outlined,
                  onTap: onBackspace,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _KeypadButton extends StatelessWidget {
  const _KeypadButton({
    this.label,
    this.icon,
    required this.onTap,
  });

  final String? label;
  final IconData? icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: TenantAdminColors.border),
            borderRadius: BorderRadius.circular(TenantAdminRadius.md),
          ),
          alignment: Alignment.center,
          child: label != null
              ? Text(
                  label!,
                  style: TenantAdminTextStyles.sectionTitle(context)
                      .copyWith(fontSize: 20),
                )
              : Icon(icon, color: TenantAdminColors.bodyText),
        ),
      ),
    );
  }
}

class _QuickGtinLengthSelector extends StatelessWidget {
  const _QuickGtinLengthSelector({
    required this.selectedLength,
    required this.onLengthSelected,
    required this.onClearAll,
  });

  final int selectedLength;
  final ValueChanged<int> onLengthSelected;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    Widget formatBtn(String label, int length) {
      final selected = selectedLength == length;
      return OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor:
              selected ? TenantAdminColors.primary : TenantAdminColors.bodyText,
          backgroundColor: selected
              ? TenantAdminColors.primary.withValues(alpha: 0.1)
              : null,
          side: BorderSide(
            color:
                selected ? TenantAdminColors.primary : TenantAdminColors.border,
          ),
        ),
        onPressed: () => onLengthSelected(length),
        child: Text(label),
      );
    }

    return Container(
      padding: const EdgeInsets.all(TenantAdminSpacing.lg),
      decoration: BoxDecoration(
        color: TenantAdminColors.subtleBackground,
        borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Quick entry',
            style: TenantAdminTextStyles.cardTitle(context),
          ),
          const SizedBox(height: TenantAdminSpacing.xs),
          Text(
            'Enter common GTIN lengths instantly.',
            style: TenantAdminTextStyles.muted(context),
          ),
          const SizedBox(height: TenantAdminSpacing.lg),
          Row(
            children: [
              Expanded(child: formatBtn('8 digits', 8)),
              const SizedBox(width: TenantAdminSpacing.sm),
              Expanded(child: formatBtn('12 digits', 12)),
            ],
          ),
          const SizedBox(height: TenantAdminSpacing.sm),
          Row(
            children: [
              Expanded(child: formatBtn('13 digits', 13)),
              const SizedBox(width: TenantAdminSpacing.sm),
              Expanded(child: formatBtn('14 digits', 14)),
            ],
          ),
          const SizedBox(height: TenantAdminSpacing.lg),
          OutlinedButton.icon(
            onPressed: onClearAll,
            icon: const Icon(Icons.refresh),
            label: const Text('Clear all'),
          ),
        ],
      ),
    );
  }
}

enum _ChipTone { active, pending, ok, danger }

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.tone});

  final String label;
  final _ChipTone tone;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border) = switch (tone) {
      _ChipTone.active => (
          TenantAdminColors.secondary,
          TenantAdminColors.primary,
          TenantAdminColors.primary,
        ),
      _ChipTone.pending => (
          TenantAdminColors.warningSurface,
          TenantAdminColors.warning,
          TenantAdminColors.warningBorder,
        ),
      _ChipTone.ok => (
          TenantAdminColors.successSurface,
          TenantAdminColors.success,
          TenantAdminColors.successBorder,
        ),
      _ChipTone.danger => (
          TenantAdminColors.dangerSurface,
          TenantAdminColors.danger,
          TenantAdminColors.dangerBorder,
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: TenantAdminSpacing.md,
        vertical: TenantAdminSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: TenantAdminTextStyles.cardTitle(context).copyWith(color: fg),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.label,
    required this.value,
    required this.tone,
  });

  final String label;
  final String value;
  final _ChipTone tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: TenantAdminSpacing.md,
        vertical: TenantAdminSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: TenantAdminColors.subtleBackground,
        borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
        border: Border.all(color: TenantAdminColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: TenantAdminTextStyles.muted(context)),
          ),
          _StatusChip(label: value, tone: tone),
        ],
      ),
    );
  }
}

class _BarcodeHero extends StatelessWidget {
  const _BarcodeHero({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(TenantAdminSpacing.md),
      decoration: BoxDecoration(
        color: TenantAdminColors.subtleBackground,
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        border: Border.all(color: TenantAdminColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Barcode', style: TenantAdminTextStyles.muted(context)),
          const SizedBox(height: TenantAdminSpacing.xs),
          SelectableText(
            value.isEmpty ? '—' : value,
            style: TenantAdminTextStyles.sectionTitle(context).copyWith(
              fontSize: 20,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _PanelCard extends StatelessWidget {
  const _PanelCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(TenantAdminSpacing.lg),
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
        border: Border.all(color: TenantAdminColors.border),
        boxShadow: TenantAdminShadows.card,
      ),
      child: child,
    );
  }
}

class _LabelValue extends StatelessWidget {
  const _LabelValue(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: TenantAdminSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(label, style: TenantAdminTextStyles.muted(context)),
          ),
          Expanded(
            child: Text(value, style: TenantAdminTextStyles.body(context)),
          ),
        ],
      ),
    );
  }
}

class _CompactLabelValue extends StatelessWidget {
  const _CompactLabelValue(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: TenantAdminTextStyles.muted(context).copyWith(fontSize: 13)),
          ),
          Expanded(
            child: Text(value, style: TenantAdminTextStyles.body(context).copyWith(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(TenantAdminSpacing.md),
      decoration: BoxDecoration(
        color: TenantAdminColors.dangerSurface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        border: Border.all(color: TenantAdminColors.dangerBorder),
      ),
      child: Text(message, style: TenantAdminTextStyles.body(context)),
    );
  }
}

class _ShortcutCard extends StatelessWidget {
  const _ShortcutCard({
    required this.title,
    this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(TenantAdminRadius.md),
      child: Container(
        padding: const EdgeInsets.all(TenantAdminSpacing.md),
        decoration: BoxDecoration(
          color: TenantAdminColors.surface,
          borderRadius: BorderRadius.circular(TenantAdminRadius.md),
          border: Border.all(color: TenantAdminColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(TenantAdminSpacing.sm),
              decoration: BoxDecoration(
                color: TenantAdminColors.subtleBackground,
                borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
              ),
              child: Icon(
                icon,
                color: TenantAdminColors.bodyText,
              ),
            ),
            const SizedBox(width: TenantAdminSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TenantAdminTextStyles.cardTitle(context),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TenantAdminTextStyles.muted(context),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: TenantAdminColors.mutedText,
            ),
          ],
        ),
      ),
    );
  }
}
