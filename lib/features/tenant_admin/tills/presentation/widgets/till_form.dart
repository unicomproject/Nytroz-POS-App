import 'package:flutter/material.dart';

import 'package:nytroz_pos/features/tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_buttons.dart';
import '../../../presentation/widgets/tenant_admin_responsive_form_grid.dart';
import '../../domain/entities/till.dart';
import 'till_review_section.dart';
import 'till_wizard_stepper.dart';

class TillForm extends StatefulWidget {
  const TillForm({
    super.key,
    required this.outlets,
    required this.backendErrors,
    required this.submitting,
    required this.onSubmit,
    this.initialValue,
    this.submitLabel = 'Create Till',
    this.showHardwareSection = true,
    this.hardwareReadOnly = false,
  });

  final List<OutletOption> outlets;
  final Map<String, String> backendErrors;
  final bool submitting;
  final Future<void> Function(TillFormData form) onSubmit;
  final TillFormData? initialValue;
  final String submitLabel;
  final bool showHardwareSection;
  final bool hardwareReadOnly;

  @override
  State<TillForm> createState() => _TillFormState();
}

class _TillFormState extends State<TillForm> {
  static const _steps = [
    (title: 'Till Details', subtitle: 'Basic information'),
    (title: 'Hardware Details', subtitle: 'Device configuration'),
    (title: 'Review', subtitle: 'Verify information'),
    (title: 'Create', subtitle: 'Finish & save'),
  ];

  final _formKey = GlobalKey<FormState>();
  var _step = 0;
  var _submitted = false;

  late final TextEditingController _nameController;
  late final TextEditingController _codeController;
  late final TextEditingController _deviceNameController;
  late final TextEditingController _printerNameController;
  late final TextEditingController _scannerNameController;
  late final TextEditingController _cashDrawerNameController;
  late final TextEditingController _cardReaderNameController;
  late final TextEditingController _noteController;

  String? _selectedOutletId;
  String _status = 'active';

  @override
  void initState() {
    super.initState();
    final initial = widget.initialValue;
    _nameController = TextEditingController(text: initial?.name ?? '');
    _codeController = TextEditingController(text: initial?.code ?? '');
    _selectedOutletId = initial?.outletId;
    _status = initial?.status ?? 'active';
    _deviceNameController =
        TextEditingController(text: initial?.deviceName ?? '');
    _printerNameController =
        TextEditingController(text: initial?.printerName ?? '');
    _scannerNameController =
        TextEditingController(text: initial?.scannerName ?? '');
    _cashDrawerNameController =
        TextEditingController(text: initial?.cashDrawerName ?? '');
    _cardReaderNameController =
        TextEditingController(text: initial?.cardReaderName ?? '');
    _noteController = TextEditingController(text: initial?.internalNote ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _deviceNameController.dispose();
    _printerNameController.dispose();
    _scannerNameController.dispose();
    _cashDrawerNameController.dispose();
    _cardReaderNameController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      autovalidateMode: _submitted
          ? AutovalidateMode.onUserInteraction
          : AutovalidateMode.disabled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TillWizardStepper(
            steps: widget.showHardwareSection
                ? _steps
                : _steps.where((s) => s.title != 'Hardware Details').toList(),
            currentStep: _step,
            onStepSelected: (step) => setState(() => _step = step),
          ),
          const SizedBox(height: TenantAdminSpacing.xl),
          _buildStep(),
          const SizedBox(height: TenantAdminSpacing.xl),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TenantAdminSecondaryButton(
                label: 'Cancel',
                icon: Icons.close,
                onPressed: widget.submitting
                    ? null
                    : () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(width: TenantAdminSpacing.md),
              TenantAdminPrimaryButton(
                label: _step >= (widget.showHardwareSection ? 2 : 1)
                    ? widget.submitLabel
                    : 'Next',
                icon: _step >= (widget.showHardwareSection ? 2 : 1)
                    ? Icons.save_outlined
                    : Icons.arrow_forward,
                loading: widget.submitting,
                onPressed: widget.submitting ? null : _handleNext,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep() {
    final effectiveSteps = widget.showHardwareSection
        ? _steps
        : _steps.where((s) => s.title != 'Hardware Details').toList();

    final currentTitle = effectiveSteps[_step].title;

    switch (currentTitle) {
      case 'Till Details':
        return _buildTillDetails();
      case 'Hardware Details':
        return _buildHardwareDetails();
      case 'Review':
      case 'Create':
        return _buildReview();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildTillDetails() {
    return _buildSectionCard(
      title: 'Till Details',
      icon: Icons.point_of_sale_outlined,
      children: [
        _twoColumnRow(
          _field(
            key: 'name',
            label: 'Till Name *',
            hint: 'Enter till name',
            controller: _nameController,
            icon: Icons.person_outline,
            requiredMessage: 'Till name is required.',
            subtitle: '2 - 100 characters',
          ),
          _field(
            key: 'code',
            label: 'Till Code *',
            hint: 'Enter till code',
            controller: _codeController,
            icon: Icons.tag,
            requiredMessage: 'Till code is required.',
            subtitle: 'Unique code to identify this till.',
          ),
        ),
        const SizedBox(height: TenantAdminSpacing.lg),
        _twoColumnRow(
          _outletDropdown(),
          _statusDropdown(),
        ),
      ],
    );
  }

  Widget _buildHardwareDetails() {
    return _buildSectionCard(
      title: 'Hardware Details',
      icon: Icons.devices_outlined,
      subtitle: 'Add hardware information if available for this till.',
      optional: true,
      children: [
        _twoColumnRow(
          _field(
            key: 'deviceName',
            label: 'Device Name',
            hint: 'e.g. POS Device',
            controller: _deviceNameController,
            icon: Icons.tablet_mac_outlined,
            readOnly: widget.hardwareReadOnly,
          ),
          _field(
            key: 'printerName',
            label: 'Printer Name',
            hint: 'e.g. Receipt Printer',
            controller: _printerNameController,
            icon: Icons.print_outlined,
            readOnly: widget.hardwareReadOnly,
          ),
        ),
        const SizedBox(height: TenantAdminSpacing.lg),
        _twoColumnRow(
          _field(
            key: 'scannerName',
            label: 'Scanner Name',
            hint: 'e.g. Barcode Scanner',
            controller: _scannerNameController,
            icon: Icons.qr_code_scanner_outlined,
            readOnly: widget.hardwareReadOnly,
          ),
          _field(
            key: 'cashDrawerName',
            label: 'Cash Drawer Name',
            hint: 'e.g. Cash Drawer',
            controller: _cashDrawerNameController,
            icon: Icons.inventory_2_outlined,
            readOnly: widget.hardwareReadOnly,
          ),
        ),
        const SizedBox(height: TenantAdminSpacing.lg),
        _twoColumnRow(
          _field(
            key: 'cardReaderName',
            label: 'Card Reader Name',
            hint: 'e.g. Card Reader',
            controller: _cardReaderNameController,
            icon: Icons.credit_card_outlined,
            readOnly: widget.hardwareReadOnly,
          ),
          _field(
            key: 'internalNote',
            label: 'Internal Note',
            hint: 'Add any internal note (optional)',
            controller: _noteController,
            icon: Icons.sticky_note_2_outlined,
            maxLength: 500,
            readOnly: widget.hardwareReadOnly,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
    String? subtitle,
    bool optional = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(TenantAdminSpacing.xl),
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
        border: Border.all(color: TenantAdminColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: TenantAdminColors.secondary,
                  borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
                ),
                child: Icon(icon, size: 18, color: TenantAdminColors.primary),
              ),
              const SizedBox(width: TenantAdminSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: TenantAdminTextStyles.sectionTitle(context),
                        ),
                        if (optional)
                          const Text(
                            ' (Optional)',
                            style: TextStyle(
                              color: TenantAdminColors.mutedText,
                              fontSize: 14,
                            ),
                          ),
                      ],
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: TenantAdminSpacing.xs),
                      Text(
                        subtitle,
                        style: TenantAdminTextStyles.muted(context),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: TenantAdminSpacing.xl),
          ...children,
        ],
      ),
    );
  }

  Widget _buildReview() {
    final outletName = widget.outlets
        .firstWhere(
          (o) => o.id == _selectedOutletId,
          orElse: () =>
              const OutletOption(id: '', name: 'Unknown', code: '', status: ''),
        )
        .name;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TillReviewSection(
          title: 'Till Details',
          icon: Icons.point_of_sale_outlined,
          onEdit: () => setState(() => _step = 0),
          items: [
            TillReviewItem('Name', _nameController.text),
            TillReviewItem('Code', _codeController.text),
            TillReviewItem('Outlet', outletName),
            TillReviewItem('Status', _status),
          ],
        ),
        if (widget.showHardwareSection) ...[
          const SizedBox(height: TenantAdminSpacing.lg),
          TillReviewSection(
            title: 'Hardware Details',
            icon: Icons.devices_outlined,
            onEdit: () => setState(() => _step = 1),
            items: [
              TillReviewItem('Device Name', _deviceNameController.text),
              TillReviewItem('Printer Name', _printerNameController.text),
              TillReviewItem('Scanner Name', _scannerNameController.text),
              TillReviewItem(
                  'Cash Drawer Name', _cashDrawerNameController.text),
              TillReviewItem(
                  'Card Reader Name', _cardReaderNameController.text),
              TillReviewItem('Internal Note', _noteController.text),
            ],
          ),
        ],
      ],
    );
  }

  Widget _field({
    required String key,
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    String? requiredMessage,
    String? subtitle,
    int? maxLength,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: TenantAdminSpacing.xs),
        TextFormField(
          controller: controller,
          maxLength: maxLength,
          readOnly: readOnly,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 18),
            errorText: widget.backendErrors[key],
            counterText: maxLength == null ? null : '',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
              borderSide: const BorderSide(color: TenantAdminColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
              borderSide: const BorderSide(color: TenantAdminColors.border),
            ),
          ),
          validator: requiredMessage == null
              ? null
              : (value) {
                  if (value == null || value.trim().isEmpty) {
                    return requiredMessage;
                  }
                  return null;
                },
        ),
        if (subtitle != null) ...[
          const SizedBox(height: TenantAdminSpacing.xs),
          Text(
            subtitle,
            style: const TextStyle(
              color: TenantAdminColors.mutedText,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }

  Widget _outletDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Assign Outlet *',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: TenantAdminSpacing.xs),
        DropdownButtonFormField<String>(
          initialValue: _selectedOutletId,
          decoration: InputDecoration(
            hintText: 'Select outlet',
            prefixIcon: const Icon(Icons.location_on_outlined, size: 18),
            errorText: widget.backendErrors['outletId'],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
              borderSide: const BorderSide(color: TenantAdminColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
              borderSide: const BorderSide(color: TenantAdminColors.border),
            ),
          ),
          items: [
            for (final outlet in widget.outlets)
              DropdownMenuItem<String>(
                value: outlet.id,
                child: Text(outlet.name),
              ),
          ],
          onChanged: widget.submitting
              ? null
              : (value) => setState(() => _selectedOutletId = value),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Outlet is required.';
            }
            return null;
          },
        ),
        const SizedBox(height: TenantAdminSpacing.xs),
        const Text(
          'Choose the outlet this till belongs to.',
          style: TextStyle(
            color: TenantAdminColors.mutedText,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _statusDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Status *',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: TenantAdminSpacing.xs),
        DropdownButtonFormField<String>(
          initialValue: _status,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.circle, size: 12),
            errorText: widget.backendErrors['status'],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
              borderSide: const BorderSide(color: TenantAdminColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
              borderSide: const BorderSide(color: TenantAdminColors.border),
            ),
          ),
          items: const [
            DropdownMenuItem(value: 'active', child: Text('Active')),
            DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
            DropdownMenuItem(value: 'maintenance', child: Text('Maintenance')),
          ],
          onChanged: widget.submitting
              ? null
              : (value) => setState(() => _status = value ?? 'active'),
        ),
        const SizedBox(height: TenantAdminSpacing.xs),
        const Text(
          'Select current status of this till.',
          style: TextStyle(
            color: TenantAdminColors.mutedText,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _twoColumnRow(Widget first, Widget second) {
    return TenantAdminResponsiveFormGrid(
      children: [first, second],
    );
  }

  void _handleNext() {
    if (!_formKey.currentState!.validate()) {
      setState(() => _submitted = true);
      return;
    }

    final effectiveSteps = widget.showHardwareSection
        ? _steps
        : _steps.where((s) => s.title != 'Hardware Details').toList();

    // If on the last step, submit
    if (_step >= effectiveSteps.length - 2) {
      // effectiveSteps is 4 items. length-2 is index 2 ("Review"). Wait.
      // 0: Till Details
      // 1: Hardware Details
      // 2: Review
      // 3: Create
      // Actually index 2 and index 3 are both Review screen?
      // Wait, in my build step I have case 'Create': return _buildReview().
      // This means we should just submit when at index 2 (Review) if clicking Next?
      // Let's just say if _step == length - 2 (Review step), pressing Next submits.
      // But wait! The UI stepper has 4 steps, index 3 is "Create".
      // If _step is 2 (Review), and user clicks Next (which says Create Till), it should submit, and maybe advance to step 3 while submitting?
      _submit();
    } else {
      setState(() => _step++);
    }
  }

  Future<void> _submit() async {
    try {
      await widget.onSubmit(
        TillFormData(
          name: _nameController.text.trim(),
          code: _codeController.text.trim(),
          outletId: _selectedOutletId ?? '',
          status: _status,
          deviceName: _deviceNameController.text.trim(),
          printerName: _printerNameController.text.trim(),
          scannerName: _scannerNameController.text.trim(),
          cashDrawerName: _cashDrawerNameController.text.trim(),
          cardReaderName: _cardReaderNameController.text.trim(),
          internalNote: _noteController.text.trim(),
        ),
      );
    } catch (_) {
      // Errors are handled by the screen callback.
    }
  }
}
