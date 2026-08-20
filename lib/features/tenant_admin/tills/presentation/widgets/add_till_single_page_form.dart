import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:nytroz_pos/shared/presentation/app_modal.dart';

import 'package:nytroz_pos/features/tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_buttons.dart';
import '../../domain/entities/till_create_options.dart';
import '../../domain/entities/till.dart';
import '../providers/till_providers.dart';
import 'add_till_details_section.dart';
import 'add_till_hardware_section.dart';
import 'add_till_hardware_status_card.dart';
import 'add_till_quick_pair_panel.dart';

class AddTillSinglePageForm extends ConsumerStatefulWidget {
  const AddTillSinglePageForm({
    super.key,
    required this.options,
    required this.canViewHardware,
    required this.canManageHardware,
  });

  final TillCreateOptions options;
  final bool canViewHardware;
  final bool canManageHardware;

  @override
  ConsumerState<AddTillSinglePageForm> createState() =>
      _AddTillSinglePageFormState();
}

class _AddTillSinglePageFormState extends ConsumerState<AddTillSinglePageForm> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _codeController;
  late final TextEditingController _floatController;

  final _posDeviceNameController = TextEditingController();
  final _scannerNameController = TextEditingController();
  final _printerNameController = TextEditingController();
  final _cashDrawerNameController = TextEditingController();
  final _cardReaderNameController = TextEditingController();

  String? _selectedOutletId;
  String? _selectedStatus;
  String? _selectedCashierId;

  String? _selectedPosDeviceId;
  String? _selectedScannerId;
  String? _selectedPrinterId;
  String? _selectedCashDrawerId;
  String? _selectedCardReaderId;

  bool _isDirty = false;
  bool _isSubmitting = false;
  Map<String, String> _backendErrors = {};

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController()..addListener(_markDirty);
    _codeController = TextEditingController()..addListener(_markDirty);
    _floatController = TextEditingController(text: '0.00')
      ..addListener(_markDirty);

    final statuses = widget.options.statuses;
    for (final s in statuses) {
      if (s.toLowerCase() == 'active') {
        _selectedStatus = s;
        break;
      }
    }
    _selectedStatus ??= statuses.isNotEmpty ? statuses.first : null;
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
    setState(() {
      _isDirty = true;
      _backendErrors = {};
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _backendErrors = {};
    });

    try {
      final hardwareAssignments = <TillHardwareSelection>[];

      void addDevice(String? deviceId) {
        // Do not send dummy device IDs to the backend
        if (deviceId != null && !deviceId.startsWith('hw-')) {
          hardwareAssignments.add(TillHardwareSelection(
            hardwareDeviceId: deviceId,
            isPrimary: true,
          ));
        }
      }

      addDevice(_selectedScannerId);
      addDevice(_selectedPrinterId);
      addDevice(_selectedCashDrawerId);
      addDevice(_selectedCardReaderId);

      final realPosDeviceId = (_selectedPosDeviceId != null && !_selectedPosDeviceId!.startsWith('pos-'))
          ? _selectedPosDeviceId
          : null;

      final formData = AddTillFormData(
        name: _nameController.text.trim(),
        code: _codeController.text.trim(),
        outletId: _selectedOutletId!,
        status: _selectedStatus!,
        defaultCashierTenantUserId: _selectedCashierId!,
        defaultOpeningFloatAmount: _floatController.text.trim(),
        posDeviceId: realPosDeviceId,
        hardwareAssignments: hardwareAssignments,
        deviceName: _posDeviceNameController.text.trim(),
        scannerName: _scannerNameController.text.trim(),
        printerName: _printerNameController.text.trim(),
        cashDrawerName: _cashDrawerNameController.text.trim(),
        cardReaderName: _cardReaderNameController.text.trim(),
      );
      final createTillSetup = ref.read(createTillSetupProvider);
      await createTillSetup(formData);

      if (mounted) {
        ref.invalidate(tillListResultFutureProvider);
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _backendErrors = {};
          if (e is DioException && e.response?.data != null) {
            final data = e.response!.data;
            if (data is Map) {
              final code = data['code']?.toString() ?? '';
              final message = data['message']?.toString() ?? '';

              if (code == 'till.duplicate_code') {
                _backendErrors = {
                  'tillCode': 'This till code is already in use.'
                };
              } else if (code.contains('subscription_limit')) {
                _backendErrors = {
                  'general': 'Subscription limit reached: $message'
                };
              } else {
                _backendErrors = {
                  'general':
                      message.isNotEmpty ? message : 'Failed to create till.'
                };
              }
            }
          }

          if (_backendErrors.isEmpty) {
            final errorMsg = e.toString().toLowerCase();
            if (errorMsg.contains('till.duplicate_code') ||
                errorMsg.contains('already in use')) {
              _backendErrors = {
                'tillCode': 'This till code is already in use.'
              };
            } else {
              _backendErrors = {
                'general': 'An error occurred while creating till.'
              };
            }
          }
        });
        _formKey.currentState?.validate();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_backendErrors['general'] ??
                _backendErrors['tillCode'] ??
                'Failed to create till'),
            backgroundColor: TenantAdminColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Discard changes?'),
            content: const Text(
                'You have unsaved changes. Are you sure you want to discard them?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Discard'),
              ),
            ],
          ),
        );

        if (shouldPop == true && context.mounted) {
          context.pop();
        }
      },
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth > 900;

                final scopedOptionsState =
                    ref.watch(tillCreateOptionsProvider(_selectedOutletId));
                final scopedOptions = scopedOptionsState.valueOrNull;

                var hwDevices = scopedOptions?.hardwareDevices ?? [];
                var pDevices = scopedOptions?.posDevices ?? [];

                // Inject dummy devices for the selected outlet to allow UI testing of pairing flow
                if (_selectedOutletId != null) {
                  final dummyHw = [
                    TillHardwareDeviceOption(id: 'hw-1', code: 'SCN-01', name: 'Zebra Barcode Scanner', type: 'barcode_scanner', outletId: _selectedOutletId!, status: 'ACTIVE', isAssigned: false),
                    TillHardwareDeviceOption(id: 'hw-2', code: 'SCN-02', name: 'Honeywell Scanner', type: 'barcode_scanner', outletId: _selectedOutletId!, status: 'ACTIVE', isAssigned: false),
                    TillHardwareDeviceOption(id: 'hw-3', code: 'PRN-01', name: 'Epson Receipt Printer', type: 'receipt_printer', outletId: _selectedOutletId!, status: 'ACTIVE', isAssigned: false),
                    TillHardwareDeviceOption(id: 'hw-4', code: 'DRW-01', name: 'Star Cash Drawer', type: 'cash_drawer', outletId: _selectedOutletId!, status: 'ACTIVE', isAssigned: false),
                    TillHardwareDeviceOption(id: 'hw-5', code: 'CRD-01', name: 'Verifone Card Reader', type: 'payment_terminal', outletId: _selectedOutletId!, status: 'ACTIVE', isAssigned: false),
                  ];
                  hwDevices = [...hwDevices, ...dummyHw];

                  final dummyPos = [
                    TillPosDeviceOption(id: 'pos-1', code: 'POS-01', name: 'Main Register iPad', outletId: _selectedOutletId!, status: 'ACTIVE', isTrusted: true, isAssigned: false),
                    TillPosDeviceOption(id: 'pos-2', code: 'POS-02', name: 'Counter 2 Tablet', outletId: _selectedOutletId!, status: 'ACTIVE', isTrusted: true, isAssigned: false),
                  ];
                  pDevices = [...pDevices, ...dummyPos];
                }

                final effectiveOptions = TillCreateOptions(
                  outlets: widget.options.outlets,
                  statuses: widget.options.statuses,
                  currencyCode: widget.options.currencyCode,
                  cashiers: scopedOptions?.cashiers ?? [],
                  posDevices: pDevices,
                  hardwareDevices: hwDevices,
                );

                final detailsSection = AddTillDetailsSection(
                  nameController: _nameController,
                  codeController: _codeController,
                  floatController: _floatController,
                  selectedOutletId: _selectedOutletId,
                  selectedStatus: _selectedStatus,
                  selectedCashierId: _selectedCashierId,
                  options: effectiveOptions,
                  onOutletChanged: (value) {
                    setState(() {
                      _selectedOutletId = value;
                      _selectedCashierId = null;
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
                      _markDirty();
                    });
                  },
                  onStatusChanged: (value) {
                    setState(() {
                      _selectedStatus = value;
                      _markDirty();
                    });
                  },
                  onCashierChanged: scopedOptionsState.isLoading
                      ? (value) {}
                      : (value) {
                          setState(() {
                            _selectedCashierId = value;
                            _markDirty();
                          });
                        },
                  backendErrors: _backendErrors,
                );

                final hardwareSection = widget.canViewHardware
                    ? AddTillHardwareSection(
                        options: effectiveOptions,
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
                          _markDirty();
                        }),
                        onScannerChanged: (value) => setState(() {
                          _selectedScannerId = value;
                          _markDirty();
                        }),
                        onPrinterChanged: (value) => setState(() {
                          _selectedPrinterId = value;
                          _markDirty();
                        }),
                        onCashDrawerChanged: (value) => setState(() {
                          _selectedCashDrawerId = value;
                          _markDirty();
                        }),
                        onCardReaderChanged: (value) => setState(() {
                          _selectedCardReaderId = value;
                          _markDirty();
                        }),
                        quickPairPanel: const AddTillQuickPairPanel(),
                        hardwareStatusCards:
                            _buildHardwareStatusCards(effectiveOptions),
                      )
                    : const SizedBox.shrink();

                final detailsCard = Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border: Border.all(color: Colors.grey.shade100),
                  ),
                  padding: const EdgeInsets.all(TenantAdminSpacing.xl),
                  child: detailsSection,
                );

                final hardwareCard = Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border: Border.all(color: Colors.grey.shade100),
                  ),
                  padding: const EdgeInsets.all(TenantAdminSpacing.xl),
                  child: hardwareSection,
                );

                if (isDesktop) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: detailsCard,
                      ),
                      if (widget.canViewHardware) ...[
                        const SizedBox(width: TenantAdminSpacing.xl),
                        Expanded(
                          child: hardwareCard,
                        ),
                      ],
                    ],
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    detailsCard,
                    if (widget.canViewHardware) ...[
                      const SizedBox(height: TenantAdminSpacing.xl),
                      hardwareCard,
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: TenantAdminSpacing.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isSubmitting ? null : () => context.pop(),
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFF3F4F6),
                    foregroundColor: const Color(0xFF374151),
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Cancel',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15, letterSpacing: 0.3)),
                ),
                const SizedBox(width: TenantAdminSpacing.lg),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TenantAdminColors.posHomeAccentOrange,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: TenantAdminColors
                        .posHomeAccentOrange
                        .withValues(alpha: 0.45),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Create Till',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 15, letterSpacing: 0.3)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHardwareStatusCards(TillCreateOptions effectiveOptions) {
    final cards = <Widget>[];

    if (_selectedOutletId == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: TenantAdminSpacing.lg),
        child: Text(
          'Select an outlet to view hardware status.',
          style: TextStyle(color: TenantAdminColors.mutedText),
        ),
      );
    }

    final selectedIds = {
      _selectedScannerId,
      _selectedPrinterId,
      _selectedCashDrawerId,
      _selectedCardReaderId,
    }.where((id) => id != null).toSet();

    if (selectedIds.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: TenantAdminSpacing.lg),
        child: Text(
          'Select hardware devices above to pair them.',
          style: TextStyle(color: TenantAdminColors.mutedText),
        ),
      );
    }

    final outletDevices = effectiveOptions.hardwareDevices
        .where((d) => d.outletId == _selectedOutletId && selectedIds.contains(d.id))
        .toList();

    for (final hw in outletDevices) {
      IconData icon;
      String actionLabel;
      final type = hw.type.toLowerCase();
      if (type.contains('scanner')) {
        icon = Icons.qr_code_scanner;
        actionLabel = 'Test Scan';
      } else if (type.contains('printer')) {
        icon = Icons.print;
        actionLabel = 'Print Test';
      } else if (type.contains('drawer')) {
        icon = Icons.point_of_sale;
        actionLabel = 'Open Drawer';
      } else if (type.contains('terminal') || type.contains('card')) {
        icon = Icons.credit_card;
        actionLabel = 'Card Test';
      } else {
        icon = Icons.device_unknown;
        actionLabel = 'Test';
      }

      cards.add(AddTillHardwareStatusCard.fromOption(
        hw,
        icon,
        actionLabel,
        () {}, // Clickable callback
      ));
    }

    if (cards.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: TenantAdminSpacing.lg),
        child: Text(
          'No hardware devices registered for this outlet.',
          style: TextStyle(color: TenantAdminColors.mutedText),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          if (i > 0) const SizedBox(height: TenantAdminSpacing.md),
          cards[i],
        ],
        const SizedBox(height: TenantAdminSpacing.sm),
        const Row(
          children: [
            Icon(Icons.info_outline,
                size: 14, color: TenantAdminColors.mutedText),
            SizedBox(width: 4),
            Expanded(
              child: Text(
                'You can test hardware after saving.',
                style:
                    TextStyle(fontSize: 12, color: TenantAdminColors.mutedText),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showSuccessDialog() {
    showAppDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFFF0FDF4),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF22C55E),
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Till Created Successfully',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Your new Till and its hardware device assignments have been securely saved and are ready to use.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TenantAdminColors.posHomeAccentOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    context.pop();
                    context.pop(); // Back to list
                  },
                  child: const Text(
                    'Done',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
