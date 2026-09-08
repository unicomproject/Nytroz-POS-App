import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:nytroz_pos/features/tenant_admin/presentation/theme/tenant_admin_theme.dart';
import 'package:nytroz_pos/shared/presentation/app_modal.dart';

import '../../domain/entities/till.dart';
import '../../domain/entities/till_create_options.dart';
import '../providers/till_providers.dart';
import 'add_till_details_section.dart';
import 'add_till_hardware_section.dart';
import 'till_review_section.dart';
import 'till_wizard_stepper.dart';

class AddTillSetupWizard extends ConsumerStatefulWidget {
  const AddTillSetupWizard({
    super.key,
    required this.options,
    required this.canViewHardware,
    required this.canManageHardware,
  });

  final TillCreateOptions options;
  final bool canViewHardware;
  final bool canManageHardware;

  @override
  ConsumerState<AddTillSetupWizard> createState() => _AddTillSetupWizardState();
}

class _AddTillSetupWizardState extends ConsumerState<AddTillSetupWizard> {
  static const _steps = [
    (title: 'Till Details', subtitle: 'Identity & ownership'),
    (title: 'Hardware Setup', subtitle: 'Connect devices'),
    (title: 'Review & Create', subtitle: 'Confirm readiness'),
  ];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _codeController;
  late final TextEditingController _floatController;
  final _posDeviceNameController = TextEditingController();
  final _scannerNameController = TextEditingController();
  final _printerNameController = TextEditingController();
  final _cashDrawerNameController = TextEditingController();
  final _cardReaderNameController = TextEditingController();

  int _currentStep = 0;
  String? _selectedOutletId;
  String? _selectedStatus;
  String? _selectedCashierId;
  String? _selectedPosDeviceId;
  String? _selectedScannerId;
  String? _selectedPrinterId;
  String? _selectedCashDrawerId;
  String? _selectedCardReaderId;
  bool _configureHardwareNow = false;
  bool _isDirty = false;
  bool _isSubmitting = false;
  Map<String, String> _backendErrors = const {};

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController()..addListener(_markDirty);
    _codeController = TextEditingController()..addListener(_markDirty);
    _floatController = TextEditingController(text: '0.00')
      ..addListener(_markDirty);
    _configureHardwareNow = widget.canManageHardware;
    _selectedStatus = widget.options.statuses.cast<String?>().firstWhere(
          (status) => status?.toUpperCase() == 'ACTIVE',
          orElse: () => widget.options.statuses.isEmpty
              ? null
              : widget.options.statuses.first,
        );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _floatController.dispose();
    _posDeviceNameController.dispose();
    _scannerNameController.dispose();
    _printerNameController.dispose();
    _cashDrawerNameController.dispose();
    _cardReaderNameController.dispose();
    super.dispose();
  }

  void _markDirty() {
    if (!mounted) return;
    setState(() {
      _isDirty = true;
      _backendErrors = const {};
    });
  }

  @override
  Widget build(BuildContext context) {
    final scopedOptionsState =
        ref.watch(tillCreateOptionsProvider(_selectedOutletId));
    final scopedOptions = scopedOptionsState.valueOrNull;
    final effectiveOptions = TillCreateOptions(
      outlets: widget.options.outlets,
      statuses: widget.options.statuses,
      currencyCode: widget.options.currencyCode,
      cashiers: scopedOptions?.cashiers ?? const [],
      posDevices: scopedOptions?.posDevices ?? const [],
      hardwareDevices: scopedOptions?.hardwareDevices ?? const [],
    );

    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _confirmDiscard();
      },
      child: Form(
        key: _formKey,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: TenantAdminColors.surface,
            border: Border.all(color: TenantAdminColors.border),
            borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
            boxShadow: TenantAdminShadows.card,
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  TenantAdminSpacing.xl,
                  TenantAdminSpacing.lg,
                  TenantAdminSpacing.xl,
                  0,
                ),
                child: TillWizardStepper(
                  steps: _steps,
                  currentStep: _currentStep,
                  onStepSelected: (step) => setState(() => _currentStep = step),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(TenantAdminSpacing.xl),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: KeyedSubtree(
                    key: ValueKey(_currentStep),
                    child: switch (_currentStep) {
                      0 => _detailsStep(
                          effectiveOptions,
                          scopedOptionsState.isLoading,
                        ),
                      1 => _hardwareStep(effectiveOptions),
                      _ => _reviewStep(effectiveOptions),
                    },
                  ),
                ),
              ),
              _footer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailsStep(TillCreateOptions options, bool loadingCashiers) {
    return _WizardCard(
      child: AddTillDetailsSection(
        nameController: _nameController,
        codeController: _codeController,
        floatController: _floatController,
        selectedOutletId: _selectedOutletId,
        selectedStatus: _selectedStatus,
        selectedCashierId: _selectedCashierId,
        options: options,
        onOutletChanged: (value) {
          setState(() {
            _selectedOutletId = value;
            _selectedCashierId = null;
            _clearHardwareSelection();
            _isDirty = true;
            _backendErrors = const {};
          });
        },
        onStatusChanged: (value) => setState(() {
          _selectedStatus = value;
          _isDirty = true;
        }),
        onCashierChanged: loadingCashiers
            ? (_) {}
            : (value) => setState(() {
                  _selectedCashierId = value;
                  _isDirty = true;
                }),
        backendErrors: _backendErrors,
      ),
    );
  }

  Widget _hardwareStep(TillCreateOptions options) {
    if (!widget.canViewHardware) {
      return const _HardwareAccessNotice(
        icon: Icons.lock_outline,
        title: 'Hardware access is not available',
        message:
            'You can create this till without devices. A user with Hardware View and Hardware Manage permissions can configure it later.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Choose how hardware should be configured',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: TenantAdminColors.bodyText,
                    ),
              ),
            ),
            TextButton.icon(
              onPressed: _selectedOutletId == null
                  ? null
                  : () => ref.invalidate(
                        tillCreateOptionsProvider(_selectedOutletId),
                      ),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Refresh devices'),
            ),
          ],
        ),
        const SizedBox(height: TenantAdminSpacing.md),
        LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < 720;
            final configure = _HardwareModeCard(
              icon: Icons.devices_other_outlined,
              title: 'Configure hardware now',
              description:
                  'Assign registered devices from the selected outlet.',
              selected: _configureHardwareNow,
              enabled: widget.canManageHardware,
              onTap: () => setState(() {
                _configureHardwareNow = true;
                _isDirty = true;
              }),
            );
            final later = _HardwareModeCard(
              icon: Icons.schedule_outlined,
              title: 'Set up later',
              description:
                  'Create the till now and assign devices later from Hardware Management.',
              selected: !_configureHardwareNow,
              enabled: true,
              onTap: () => setState(() {
                _configureHardwareNow = false;
                _isDirty = true;
              }),
            );
            return narrow
                ? Column(
                    children: [
                      configure,
                      const SizedBox(height: TenantAdminSpacing.md),
                      later,
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: configure),
                      const SizedBox(width: TenantAdminSpacing.md),
                      Expanded(child: later),
                    ],
                  );
          },
        ),
        const SizedBox(height: TenantAdminSpacing.lg),
        if (_configureHardwareNow && widget.canManageHardware)
          _WizardCard(
            child: AddTillHardwareSection(
              options: options,
              selectedOutletId: _selectedOutletId,
              selectedPosDeviceId: _selectedPosDeviceId,
              selectedScannerId: _selectedScannerId,
              selectedPrinterId: _selectedPrinterId,
              selectedCashDrawerId: _selectedCashDrawerId,
              selectedCardReaderId: _selectedCardReaderId,
              posDeviceNameController: _posDeviceNameController,
              scannerNameController: _scannerNameController,
              printerNameController: _printerNameController,
              cashDrawerNameController: _cashDrawerNameController,
              cardReaderNameController: _cardReaderNameController,
              onPosDeviceChanged: (value) => setState(() {
                _selectedPosDeviceId = value;
                _isDirty = true;
              }),
              onScannerChanged: (value) => setState(() {
                _selectedScannerId = value;
                _isDirty = true;
              }),
              onPrinterChanged: (value) => setState(() {
                _selectedPrinterId = value;
                _isDirty = true;
              }),
              onCashDrawerChanged: (value) => setState(() {
                _selectedCashDrawerId = value;
                _isDirty = true;
              }),
              onCardReaderChanged: (value) => setState(() {
                _selectedCardReaderId = value;
                _isDirty = true;
              }),
            ),
          )
        else if (!widget.canManageHardware)
          const _HardwareAccessNotice(
            icon: Icons.admin_panel_settings_outlined,
            title: 'Hardware assignment requires permission',
            message:
                'Hardware devices are visible, but Hardware Manage permission is required to assign them to a new till.',
          )
        else
          const _HardwareAccessNotice(
            icon: Icons.event_available_outlined,
            title: 'Hardware setup can be completed later',
            message:
                'The till will be created without device assignments. Its readiness status will remain Not Configured until hardware is connected.',
          ),
        const SizedBox(height: TenantAdminSpacing.md),
        const _HardwareAccessNotice(
          icon: Icons.verified_outlined,
          title: 'Testing happens after creation',
          message:
              'A Till ID and an active device assignment are required before connection checks, test printing or cash drawer tests can run.',
          compact: true,
        ),
      ],
    );
  }

  Widget _reviewStep(TillCreateOptions options) {
    final outletName = _findOutletName(options, _selectedOutletId);
    final cashierName = _findCashierName(options, _selectedCashierId);
    final devices = _selectedDeviceNames(options);
    final hardwareSummary = !_configureHardwareNow
        ? 'Not configured — setup later'
        : devices.isEmpty
            ? 'No registered devices selected'
            : '${devices.length} device${devices.length == 1 ? '' : 's'} selected';

    final details = TillReviewSection(
      title: 'Till details',
      icon: Icons.point_of_sale_outlined,
      onEdit: () => setState(() => _currentStep = 0),
      items: [
        TillReviewItem('Till name', _nameController.text.trim()),
        TillReviewItem('Till code', _codeController.text.trim().toUpperCase()),
        TillReviewItem('Outlet', outletName),
        TillReviewItem('Default cashier', cashierName),
        TillReviewItem('Status', _selectedStatus ?? ''),
        TillReviewItem(
          'Opening float',
          '${options.currencyCode} ${_floatController.text.trim()}',
        ),
      ],
    );
    final hardware = TillReviewSection(
      title: 'Hardware readiness',
      icon: Icons.devices_other_outlined,
      onEdit: () => setState(() => _currentStep = 1),
      items: [
        TillReviewItem('Setup status', hardwareSummary),
        if (_configureHardwareNow)
          for (final device in devices)
            TillReviewItem(device.type, '${device.name} (${device.code})'),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: TenantAdminColors.secondary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.fact_check_outlined,
                color: TenantAdminColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: TenantAdminSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Review & Create',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const Text(
                    'Confirm the till identity, ownership and hardware readiness.',
                    style: TextStyle(color: TenantAdminColors.mutedText),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: TenantAdminSpacing.lg),
        LayoutBuilder(
          builder: (context, constraints) => constraints.maxWidth < 820
              ? Column(
                  children: [
                    details,
                    const SizedBox(height: TenantAdminSpacing.lg),
                    hardware,
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: details),
                    const SizedBox(width: TenantAdminSpacing.lg),
                    Expanded(child: hardware),
                  ],
                ),
        ),
        const SizedBox(height: TenantAdminSpacing.lg),
        _HardwareAccessNotice(
          icon:
              devices.isEmpty ? Icons.info_outline : Icons.check_circle_outline,
          title: devices.isEmpty
              ? 'Till will require hardware setup'
              : 'Ready to create with device assignments',
          message: devices.isEmpty
              ? 'Sales setup can continue, but hardware-dependent operations require device configuration after creation.'
              : 'The backend will validate outlet ownership, device availability and assignment conflicts before creating the till.',
          compact: true,
          success: devices.isNotEmpty,
        ),
      ],
    );
  }

  Widget _footer() {
    return Container(
      padding: const EdgeInsets.all(TenantAdminSpacing.lg),
      decoration: const BoxDecoration(
        color: TenantAdminColors.surface,
        border: Border(top: BorderSide(color: TenantAdminColors.border)),
      ),
      child: Row(
        children: [
          OutlinedButton.icon(
            onPressed: _isSubmitting
                ? null
                : _currentStep == 0
                    ? _handleCancel
                    : () => setState(() => _currentStep--),
            icon: Icon(
              _currentStep == 0 ? Icons.close : Icons.arrow_back,
              size: 18,
            ),
            label: Text(_currentStep == 0 ? 'Cancel' : 'Back'),
          ),
          const Spacer(),
          FilledButton.icon(
            onPressed: _isSubmitting
                ? null
                : _currentStep == 2
                    ? _submit
                    : _next,
            icon: _isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(
                    _currentStep == 2
                        ? Icons.add_business_outlined
                        : Icons.arrow_forward,
                    size: 18,
                  ),
            label: Text(_currentStep == 2 ? 'Create Till' : 'Continue'),
            style: FilledButton.styleFrom(
              backgroundColor: TenantAdminColors.primary,
              foregroundColor: TenantAdminColors.surface,
              padding: const EdgeInsets.symmetric(
                horizontal: TenantAdminSpacing.xl,
                vertical: TenantAdminSpacing.lg,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _next() {
    if (_currentStep == 0 && !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _currentStep++);
  }

  Future<void> _submit() async {
    setState(() {
      _isSubmitting = true;
      _backendErrors = const {};
    });
    try {
      final assignments = <TillHardwareSelection>[];
      if (_configureHardwareNow && widget.canManageHardware) {
        for (final id in {
          _selectedScannerId,
          _selectedPrinterId,
          _selectedCashDrawerId,
          _selectedCardReaderId,
        }.whereType<String>()) {
          assignments.add(
            TillHardwareSelection(hardwareDeviceId: id, isPrimary: true),
          );
        }
      }
      final posDeviceId = _configureHardwareNow && widget.canManageHardware
          ? _selectedPosDeviceId
          : null;
      final created = await ref.read(createTillSetupProvider)(
        AddTillFormData(
          name: _nameController.text.trim(),
          code: _codeController.text.trim(),
          outletId: _selectedOutletId!,
          status: _selectedStatus!,
          defaultCashierTenantUserId: _selectedCashierId!,
          defaultOpeningFloatAmount: _floatController.text.trim(),
          posDeviceId: posDeviceId,
          hardwareAssignments: assignments,
          deviceName:
              posDeviceId == null ? null : _posDeviceNameController.text.trim(),
          printerName: _nameForSelection(
            _selectedPrinterId,
            _printerNameController,
          ),
          scannerName: _nameForSelection(
            _selectedScannerId,
            _scannerNameController,
          ),
          cashDrawerName: _nameForSelection(
            _selectedCashDrawerId,
            _cashDrawerNameController,
          ),
          cardReaderName: _nameForSelection(
            _selectedCardReaderId,
            _cardReaderNameController,
          ),
        ),
      );
      if (!mounted) return;
      ref.invalidate(tillListResultFutureProvider);
      _showSuccessDialog(created);
    } catch (error) {
      if (!mounted) return;
      final parsed = _parseError(error);
      setState(() {
        _backendErrors = parsed;
        if (parsed.containsKey('tillCode')) _currentStep = 0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            parsed['general'] ?? parsed['tillCode'] ?? 'Failed to create till.',
          ),
          backgroundColor: TenantAdminColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String? _nameForSelection(
    String? selectedId,
    TextEditingController controller,
  ) {
    if (!_configureHardwareNow || !widget.canManageHardware) return null;
    return selectedId == null ? null : controller.text.trim();
  }

  Map<String, String> _parseError(Object error) {
    if (error is DioException && error.response?.data is Map) {
      final data = Map<String, dynamic>.from(error.response!.data as Map);
      final code = data['code']?.toString() ?? '';
      final message = data['message']?.toString() ?? '';
      if (code == 'till.duplicate_code') {
        return const {'tillCode': 'This till code is already in use.'};
      }
      if (code.contains('subscription_limit')) {
        return {'general': 'Subscription limit reached: $message'};
      }
      if (message.isNotEmpty) return {'general': message};
    }
    return const {'general': 'An error occurred while creating the till.'};
  }

  Future<void> _handleCancel() async {
    if (!_isDirty) {
      context.pop();
      return;
    }
    await _confirmDiscard();
  }

  Future<void> _confirmDiscard() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Discard till setup?'),
        content:
            const Text('Your till details and device selections will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Continue setup'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    if (discard == true && mounted) context.pop();
  }

  void _clearHardwareSelection() {
    _selectedPosDeviceId = null;
    _selectedScannerId = null;
    _selectedPrinterId = null;
    _selectedCashDrawerId = null;
    _selectedCardReaderId = null;
    _posDeviceNameController.clear();
    _scannerNameController.clear();
    _printerNameController.clear();
    _cashDrawerNameController.clear();
    _cardReaderNameController.clear();
  }

  String _findOutletName(TillCreateOptions options, String? id) {
    for (final outlet in options.outlets) {
      if (outlet.id == id) return outlet.name;
    }
    return '';
  }

  String _findCashierName(TillCreateOptions options, String? id) {
    for (final cashier in options.cashiers) {
      if (cashier.id == id) return cashier.displayName;
    }
    return '';
  }

  List<({String type, String name, String code})> _selectedDeviceNames(
    TillCreateOptions options,
  ) {
    if (!_configureHardwareNow || !widget.canManageHardware) return const [];
    final result = <({String type, String name, String code})>[];
    for (final device in options.posDevices) {
      if (device.id == _selectedPosDeviceId) {
        result.add((type: 'POS device', name: device.name, code: device.code));
      }
    }
    final selected = <String, String?>{
      'Barcode scanner': _selectedScannerId,
      'Receipt printer': _selectedPrinterId,
      'Cash drawer': _selectedCashDrawerId,
      'Card terminal': _selectedCardReaderId,
    };
    for (final entry in selected.entries) {
      for (final device in options.hardwareDevices) {
        if (device.id == entry.value) {
          result.add((type: entry.key, name: device.name, code: device.code));
        }
      }
    }
    return result;
  }

  void _showSuccessDialog(CreatedTill created) {
    final hasHardware =
        created.posDevice != null || created.hardwareAssignments.isNotEmpty;
    showAppDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(
            color: TenantAdminColors.successSurface,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle,
            color: TenantAdminColors.success,
            size: 36,
          ),
        ),
        title: const Text('Till created successfully'),
        content: Text(
          hasHardware
              ? 'The till and its device assignments are saved. Open Till Details to verify hardware readiness.'
              : 'The till is ready. An administrator can assign devices later from Hardware Management.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.go('/tenant-admin/tills');
            },
            child: const Text('Back to tills'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.go('/tenant-admin/tills/${created.id}');
            },
            child: const Text('View Till'),
          ),
        ],
      ),
    );
  }
}

class _WizardCard extends StatelessWidget {
  const _WizardCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(TenantAdminSpacing.xl),
        decoration: BoxDecoration(
          color: TenantAdminColors.surface,
          border: Border.all(color: TenantAdminColors.border),
          borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
          boxShadow: TenantAdminShadows.card,
        ),
        child: child,
      );
}

class _HardwareModeCard extends StatelessWidget {
  const _HardwareModeCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: enabled,
        selected: selected,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(TenantAdminRadius.md),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.all(TenantAdminSpacing.lg),
            decoration: BoxDecoration(
              color: selected
                  ? TenantAdminColors.secondary
                  : TenantAdminColors.surface,
              border: Border.all(
                color: selected
                    ? TenantAdminColors.primary
                    : TenantAdminColors.border,
                width: selected ? 1.5 : 1,
              ),
              borderRadius: BorderRadius.circular(TenantAdminRadius.md),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: selected
                        ? TenantAdminColors.primary.withValues(alpha: 0.12)
                        : TenantAdminColors.subtleBackground,
                    borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
                  ),
                  child: Icon(
                    enabled ? icon : Icons.lock_outline,
                    color: selected
                        ? TenantAdminColors.primary
                        : TenantAdminColors.mutedText,
                  ),
                ),
                const SizedBox(width: TenantAdminSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TenantAdminTextStyles.cardTitle(context),
                      ),
                      const SizedBox(height: TenantAdminSpacing.xs),
                      Text(
                        enabled
                            ? description
                            : 'Hardware Manage permission required.',
                        style: TenantAdminTextStyles.muted(context),
                      ),
                    ],
                  ),
                ),
                Icon(
                  selected ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: selected
                      ? TenantAdminColors.primary
                      : TenantAdminColors.mutedText,
                ),
              ],
            ),
          ),
        ),
      );
}

class _HardwareAccessNotice extends StatelessWidget {
  const _HardwareAccessNotice({
    required this.icon,
    required this.title,
    required this.message,
    this.compact = false,
    this.success = false,
  });

  final IconData icon;
  final String title;
  final String message;
  final bool compact;
  final bool success;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: EdgeInsets.all(
          compact ? TenantAdminSpacing.md : TenantAdminSpacing.xl,
        ),
        decoration: BoxDecoration(
          color: success
              ? TenantAdminColors.successSurface
              : TenantAdminColors.subtleBackground,
          border: Border.all(
            color: success
                ? TenantAdminColors.successBorder
                : TenantAdminColors.border,
          ),
          borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: success
                  ? TenantAdminColors.success
                  : TenantAdminColors.primary,
            ),
            const SizedBox(width: TenantAdminSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TenantAdminTextStyles.cardTitle(context),
                  ),
                  const SizedBox(height: TenantAdminSpacing.xs),
                  Text(message, style: TenantAdminTextStyles.muted(context)),
                ],
              ),
            ),
          ],
        ),
      );
}
