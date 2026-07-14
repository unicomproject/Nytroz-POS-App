import 'package:flutter/material.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_buttons.dart';
import '../../domain/entities/till.dart';

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
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _deviceNameController = TextEditingController();
  final _printerNameController = TextEditingController();
  final _scannerNameController = TextEditingController();
  final _cashDrawerNameController = TextEditingController();
  final _cardReaderNameController = TextEditingController();
  final _noteController = TextEditingController();
  String? _selectedOutletId;
  String _status = 'active';

  @override
  void initState() {
    super.initState();
    final initial = widget.initialValue;
    if (initial != null) {
      _nameController.text = initial.name;
      _codeController.text = initial.code;
      _selectedOutletId = initial.outletId;
      _status = initial.status;
      _deviceNameController.text = initial.deviceName ?? '';
      _printerNameController.text = initial.printerName ?? '';
      _scannerNameController.text = initial.scannerName ?? '';
      _cashDrawerNameController.text = initial.cashDrawerName ?? '';
      _cardReaderNameController.text = initial.cardReaderName ?? '';
      _noteController.text = initial.internalNote ?? '';
    }
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
      child: Container(
        padding: const EdgeInsets.all(TenantAdminSpacing.xl),
        decoration: BoxDecoration(
          color: TenantAdminColors.surface,
          borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
          border: Border.all(color: TenantAdminColors.border),
          boxShadow: TenantAdminShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(
              icon: Icons.point_of_sale_outlined,
              title: 'Till Details',
            ),
            const SizedBox(height: TenantAdminSpacing.lg),
            _twoColumnRow(
              _field(
                key: 'name',
                label: 'Till Name',
                hint: 'Enter till name',
                controller: _nameController,
                icon: Icons.person_outline,
                requiredMessage: 'Till name is required.',
              ),
              _field(
                key: 'code',
                label: 'Till Code',
                hint: 'Enter till code',
                controller: _codeController,
                icon: Icons.tag,
                requiredMessage: 'Till code is required.',
              ),
            ),
            const SizedBox(height: TenantAdminSpacing.lg),
            _twoColumnRow(_outletDropdown(), _statusDropdown()),
            if (widget.showHardwareSection) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: TenantAdminSpacing.xl),
                child: Divider(height: 1, color: TenantAdminColors.border),
              ),
              _sectionHeader(
                icon: Icons.devices_outlined,
                title: 'Hardware Details',
                subtitle: 'Add hardware information if available for this till.',
              ),
              const SizedBox(height: TenantAdminSpacing.lg),
              _twoColumnRow(
                _field(
                  key: 'deviceName',
                  label: 'Device Name',
                  hint: 'Enter device name',
                  controller: _deviceNameController,
                  icon: Icons.tablet_mac_outlined,
                  readOnly: widget.hardwareReadOnly,
                ),
                _field(
                  key: 'printerName',
                  label: 'Printer Name',
                  hint: 'Enter printer name',
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
                  hint: 'Enter scanner name',
                  controller: _scannerNameController,
                  icon: Icons.qr_code_scanner_outlined,
                  readOnly: widget.hardwareReadOnly,
                ),
                _field(
                  key: 'cashDrawerName',
                  label: 'Cash Drawer Name',
                  hint: 'Enter cash drawer name',
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
                  hint: 'Enter card reader name',
                  controller: _cardReaderNameController,
                  icon: Icons.credit_card_outlined,
                  readOnly: widget.hardwareReadOnly,
                ),
                _field(
                  key: 'internalNote',
                  label: 'Internal Note',
                  hint: 'Enter any note...',
                  controller: _noteController,
                  icon: Icons.sticky_note_2_outlined,
                  maxLength: 500,
                  readOnly: widget.hardwareReadOnly,
                ),
              ),
            ],
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
                  label: widget.submitLabel,
                  icon: Icons.save_outlined,
                  loading: widget.submitting,
                  onPressed: widget.submitting ? null : _submit,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader({
    required IconData icon,
    required String title,
    String? subtitle,
  }) {
    return Row(
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
              Text(title, style: TenantAdminTextStyles.sectionTitle(context)),
              if (subtitle != null) ...[
                const SizedBox(height: TenantAdminSpacing.xs),
                Text(subtitle, style: TenantAdminTextStyles.muted(context)),
              ],
            ],
          ),
        ),
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
    int? maxLength,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      maxLength: maxLength,
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 18),
        errorText: widget.backendErrors[key],
        counterText: maxLength == null ? null : '',
      ),
      validator: requiredMessage == null
          ? null
          : (value) {
              if (value == null || value.trim().isEmpty) {
                return requiredMessage;
              }
              return null;
            },
    );
  }

  Widget _outletDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedOutletId,
      decoration: InputDecoration(
        labelText: 'Assign Outlet',
        hintText: 'Select outlet',
        prefixIcon: const Icon(Icons.location_on_outlined, size: 18),
        errorText: widget.backendErrors['outletId'],
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
    );
  }

  Widget _statusDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _status,
      decoration: InputDecoration(
        labelText: 'Status',
        prefixIcon: const Icon(Icons.circle, size: 12),
        errorText: widget.backendErrors['status'],
      ),
      items: const [
        DropdownMenuItem(value: 'active', child: Text('Active')),
        DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
        DropdownMenuItem(value: 'maintenance', child: Text('Maintenance')),
      ],
      onChanged: widget.submitting
          ? null
          : (value) => setState(() => _status = value ?? 'active'),
    );
  }

  Widget _twoColumnRow(Widget first, Widget second) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 720) {
          return Column(
            children: [
              first,
              const SizedBox(height: TenantAdminSpacing.lg),
              second,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: first),
            const SizedBox(width: TenantAdminSpacing.xl),
            Expanded(child: second),
          ],
        );
      },
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

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
