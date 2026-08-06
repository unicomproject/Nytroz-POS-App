import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
            isPrimary:
                true, // Assuming primary for now based on wizard behavior
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
          // In a real scenario, map validation errors to _backendErrors
          _backendErrors = {'general': e.toString()};
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
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
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth > 900;

                final detailsSection = AddTillDetailsSection(
                  nameController: _nameController,
                  codeController: _codeController,
                  floatController: _floatController,
                  selectedOutletId: _selectedOutletId,
                  selectedStatus: _selectedStatus,
                  selectedCashierId: _selectedCashierId,
                  options: widget.options,
                  onOutletChanged: (value) {
                    setState(() {
                      _selectedOutletId = value;
                      _selectedCashierId = null;
                      _selectedPosDeviceId = null;
                      _selectedScannerId = null;
                      _selectedPrinterId = null;
                      _selectedCashDrawerId = null;
                      _selectedCardReaderId = null;
                      _markDirty();
                    });
                  },
                  onStatusChanged: (value) {
                    setState(() {
                      _selectedStatus = value;
                      _markDirty();
                    });
                  },
                  onCashierChanged: (value) {
                    setState(() {
                      _selectedCashierId = value;
                      _markDirty();
                    });
                  },
                  backendErrors: _backendErrors,
                );

                final hardwareSection = widget.canViewHardware
                    ? AddTillHardwareSection(
                        options: widget.options,
                        selectedOutletId: _selectedOutletId,
                        selectedPosDeviceId: _selectedPosDeviceId,
                        selectedScannerId: _selectedScannerId,
                        selectedPrinterId: _selectedPrinterId,
                        selectedCashDrawerId: _selectedCashDrawerId,
                        selectedCardReaderId: _selectedCardReaderId,
                        onPosDeviceChanged: widget.canManageHardware
                            ? (value) => setState(() {
                                  _selectedPosDeviceId = value;
                                  _markDirty();
                                })
                            : (value) {},
                        onScannerChanged: widget.canManageHardware
                            ? (value) => setState(() {
                                  _selectedScannerId = value;
                                  _markDirty();
                                })
                            : (value) {},
                        onPrinterChanged: widget.canManageHardware
                            ? (value) => setState(() {
                                  _selectedPrinterId = value;
                                  _markDirty();
                                })
                            : (value) {},
                        onCashDrawerChanged: widget.canManageHardware
                            ? (value) => setState(() {
                                  _selectedCashDrawerId = value;
                                  _markDirty();
                                })
                            : (value) {},
                        onCardReaderChanged: widget.canManageHardware
                            ? (value) => setState(() {
                                  _selectedCardReaderId = value;
                                  _markDirty();
                                })
                            : (value) {},
                        quickPairPanel: const AddTillQuickPairPanel(),
                        hardwareStatusCards: _buildHardwareStatusCards(),
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
            Container(
              padding: const EdgeInsets.only(top: TenantAdminSpacing.lg),
              decoration: const BoxDecoration(
                border:
                    Border(top: BorderSide(color: TenantAdminColors.border)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                    width: 120,
                    child: TenantAdminSecondaryButton(
                      onPressed: _isSubmitting ? null : () => context.pop(),
                      label: 'Cancel',
                    ),
                  ),
                  const SizedBox(width: TenantAdminSpacing.md),
                  SizedBox(
                    width: 160,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6A00),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            const Color(0xFFFF6A00).withValues(alpha: 0.45),
                        padding: const EdgeInsets.symmetric(
                          horizontal: TenantAdminSpacing.lg,
                          vertical: TenantAdminSpacing.md,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(TenantAdminRadius.md),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Text('Create Till',
                              style: TextStyle(fontWeight: FontWeight.w600)),
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

  Widget _buildHardwareStatusCards() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AddTillHardwareStatusCard(
          deviceName: 'Scanner',
          deviceCode: 'Select scanner (optional)',
          type: 'Scanner',
          status: 'Pending',
          icon: Icons.qr_code_scanner,
          actionLabel: 'Test Scan',
          onAction: null,
        ),
        SizedBox(height: TenantAdminSpacing.md),
        AddTillHardwareStatusCard(
          deviceName: 'Printer',
          deviceCode: 'Select printer (optional)',
          type: 'Receipt Printer',
          status: 'Pending',
          icon: Icons.print,
          actionLabel: 'Print Test',
          onAction: null,
        ),
        SizedBox(height: TenantAdminSpacing.md),
        AddTillHardwareStatusCard(
          deviceName: 'Cash Drawer',
          deviceCode: 'Select cash drawer (optional)',
          type: 'Cash Drawer',
          status: 'Pending',
          icon: Icons.point_of_sale,
          actionLabel: 'Open Drawer',
          onAction: null,
        ),
        SizedBox(height: TenantAdminSpacing.sm),
        Row(
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
