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
    if (!_isDirty) {
      setState(() {
        _isDirty = true;
      });
    }
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
        if (deviceId != null) {
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

      final formData = AddTillFormData(
        name: _nameController.text.trim(),
        code: _codeController.text.trim(),
        outletId: _selectedOutletId!,
        status: _selectedStatus!,
        defaultCashierTenantUserId: _selectedCashierId!,
        defaultOpeningFloatAmount: _floatController.text.trim(),
        posDeviceId: _selectedPosDeviceId,
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
                _backendErrors = {'tillCode': 'This till code is already in use.'};
              } else if (code.contains('subscription_limit')) {
                _backendErrors = {'general': 'Subscription limit reached: $message'};
              } else {
                _backendErrors = {'general': message.isNotEmpty ? message : 'Failed to create till.'};
              }
            }
          }

          if (_backendErrors.isEmpty) {
            final errorMsg = e.toString().toLowerCase();
            if (errorMsg.contains('till.duplicate_code') || 
                errorMsg.contains('already in use')) {
              _backendErrors = {'tillCode': 'This till code is already in use.'};
            } else {
              _backendErrors = {'general': 'An error occurred while creating till.'};
            }
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_backendErrors['general'] ?? 'Failed to create till'),
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
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: TenantAdminColors.border.withValues(alpha: 0.5)),
          ),
          padding: const EdgeInsets.all(TenantAdminSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add Till',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Create a till and connect its hardware.',
                style: TextStyle(
                  color: TenantAdminColors.mutedText,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: TenantAdminSpacing.xl),
            LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth > 900;

                final scopedOptionsState = ref.watch(tillCreateOptionsProvider(_selectedOutletId));
                final scopedOptions = scopedOptionsState.valueOrNull;

                final effectiveOptions = TillCreateOptions(
                  outlets: widget.options.outlets,
                  statuses: widget.options.statuses,
                  currencyCode: widget.options.currencyCode,
                  cashiers: scopedOptions?.cashiers ?? [],
                  posDevices: scopedOptions?.posDevices ?? [],
                  hardwareDevices: scopedOptions?.hardwareDevices ?? [],
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
                        onPosDeviceChanged: widget.canManageHardware && !scopedOptionsState.isLoading
                            ? (value) => setState(() {
                                  _selectedPosDeviceId = value;
                                  _markDirty();
                                })
                            : (value) {},
                        onScannerChanged: widget.canManageHardware && !scopedOptionsState.isLoading
                            ? (value) => setState(() {
                                  _selectedScannerId = value;
                                  _markDirty();
                                })
                            : (value) {},
                        onPrinterChanged: widget.canManageHardware && !scopedOptionsState.isLoading
                            ? (value) => setState(() {
                                  _selectedPrinterId = value;
                                  _markDirty();
                                })
                            : (value) {},
                        onCashDrawerChanged: widget.canManageHardware && !scopedOptionsState.isLoading
                            ? (value) => setState(() {
                                  _selectedCashDrawerId = value;
                                  _markDirty();
                                })
                            : (value) {},
                        onCardReaderChanged: widget.canManageHardware && !scopedOptionsState.isLoading
                            ? (value) => setState(() {
                                  _selectedCardReaderId = value;
                                  _markDirty();
                                })
                            : (value) {},
                        quickPairPanel: const AddTillQuickPairPanel(),
                        hardwareStatusCards: _buildHardwareStatusCards(effectiveOptions),
                      )
                    : const SizedBox.shrink();

                if (isDesktop) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: detailsSection,
                      ),
                      if (widget.canViewHardware) ...[
                        const SizedBox(width: TenantAdminSpacing.xl),
                        Expanded(
                          child: hardwareSection,
                        ),
                      ],
                    ],
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    detailsSection,
                    if (widget.canViewHardware) ...[
                      const SizedBox(height: TenantAdminSpacing.xl),
                      hardwareSection,
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: TenantAdminSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSubmitting ? null : () => context.pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black87,
                      side: BorderSide(color: TenantAdminColors.border.withValues(alpha: 0.5)),
                      padding: const EdgeInsets.symmetric(
                        vertical: TenantAdminSpacing.md,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
                      ),
                    ),
                    child: const Text('Cancel',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                const SizedBox(width: TenantAdminSpacing.lg),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6A00),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFFFF6A00).withValues(alpha: 0.45),
                      padding: const EdgeInsets.symmetric(
                        vertical: TenantAdminSpacing.md,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('Create Till',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildHardwareStatusCards(TillCreateOptions effectiveOptions) {
    final cards = <Widget>[];

    void addCard(String? id, IconData icon, String actionLabel) {
      if (id == null) return;
      final hw = effectiveOptions.hardwareDevices.where((d) => d.id == id).firstOrNull;
      if (hw != null) {
        cards.add(AddTillHardwareStatusCard.fromOption(
          hw,
          icon,
          actionLabel,
          null,
        ));
      }
    }

    addCard(_selectedScannerId, Icons.qr_code_scanner, 'Test Scan');
    addCard(_selectedPrinterId, Icons.print, 'Print Test');
    addCard(_selectedCashDrawerId, Icons.point_of_sale, 'Open Drawer');
    addCard(_selectedCardReaderId, Icons.credit_card, 'Card Test');

    if (cards.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: TenantAdminSpacing.lg),
        child: Text(
          'Select hardware devices to view setup status.',
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
            Text(
              'You can test hardware after saving.',
              style:
                  TextStyle(fontSize: 12, color: TenantAdminColors.mutedText),
            ),
          ],
        ),
      ],
    );
  }

  void _showSuccessDialog() {
    showAppDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Till created successfully'),
        content: const Text(
            'The Till and selected device assignments have been saved.'),
        actions: [
          TenantAdminSecondaryButton(
            onPressed: () {
              context.pop();
              context.pop(); // Back to list
            },
            label: 'Close',
          ),
        ],
      ),
    );
  }
}
