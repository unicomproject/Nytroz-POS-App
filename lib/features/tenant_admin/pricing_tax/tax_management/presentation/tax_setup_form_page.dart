import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/services/tenant_admin_access_checker.dart';
import '../../../presentation/providers/tenant_admin_access_provider.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_buttons.dart';
import '../../../presentation/widgets/tenant_admin_form_section.dart';
import '../../../presentation/widgets/tenant_admin_page_scaffold.dart';
import '../../../presentation/widgets/tenant_admin_row_action.dart';
import '../../../presentation/widgets/tenant_admin_states.dart';
import '../../../presentation/widgets/tenant_admin_status_badge.dart';
import '../application/tax_management_controller.dart';
import '../domain/tax_aggregate.dart';
import '../domain/tax_status.dart';
import '../domain/tax_treatment.dart';
import 'utils/tax_formatters.dart';
import 'widgets/schedule_rate_sheet.dart';

class TaxSetupFormPage extends ConsumerStatefulWidget {
  const TaxSetupFormPage({
    super.key,
    this.taxId,
  });

  final String? taxId;

  bool get isEdit => taxId != null && taxId!.isNotEmpty;

  @override
  ConsumerState<TaxSetupFormPage> createState() => _TaxSetupFormPageState();
}

class _TaxSetupFormPageState extends ConsumerState<TaxSetupFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _rateController = TextEditingController();

  TaxTreatment _treatment = TaxTreatment.taxable;
  DateTime _effectiveFrom = DateTime.now();
  bool _populated = false;
  String? _formError;

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _descriptionController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  void _populateFromDetail(TaxSetup tax) {
    if (_populated) return;
    _nameController.text = tax.name;
    _codeController.text = tax.code;
    _descriptionController.text = tax.description ?? '';
    _treatment = tax.taxTreatment;
    if (tax.taxTreatment == TaxTreatment.zeroRated) {
      _rateController.text = '0';
    } else if (tax.currentRate != null) {
      final rate = tax.currentRate!;
      _rateController.text = rate.truncateToDouble() == rate
          ? rate.toStringAsFixed(0)
          : rate.toString();
    }
    _populated = true;
  }

  Future<void> _pickEffectiveFrom() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _effectiveFrom,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) {
      setState(() => _effectiveFrom = picked);
    }
  }

  Future<void> _submitCreate() async {
    setState(() => _formError = null);
    if (!_formKey.currentState!.validate()) return;

    final mutation = ref.read(taxMutationControllerProvider);
    if (mutation.isSubmitting) return;

    final treatment = _treatment;
    final initialRate = switch (treatment) {
      TaxTreatment.taxable => double.tryParse(_rateController.text.trim()),
      TaxTreatment.zeroRated => 0.0,
      TaxTreatment.exempt => null,
    };

    try {
      await ref.read(taxMutationControllerProvider.notifier).create(
            TaxSetupCreateInput(
              name: _nameController.text.trim(),
              code: _codeController.text.trim().toUpperCase(),
              description: _descriptionController.text.trim().isEmpty
                  ? null
                  : _descriptionController.text.trim(),
              taxTreatment: treatment,
              initialRate: initialRate,
              effectiveFrom: _effectiveFrom,
            ),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tax setup created successfully.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _formError = taxApiErrorMessage(error));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(taxApiErrorMessage(error)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _submitUpdate(TaxSetup existing) async {
    setState(() => _formError = null);
    if (!_formKey.currentState!.validate()) return;

    final mutation = ref.read(taxMutationControllerProvider);
    if (mutation.isSubmitting) return;

    try {
      await ref.read(taxMutationControllerProvider.notifier).update(
            existing.id,
            TaxSetupUpdateInput(
              name: _nameController.text.trim(),
              code: _codeController.text.trim().isEmpty
                  ? null
                  : _codeController.text.trim().toUpperCase(),
              description: _descriptionController.text.trim().isEmpty
                  ? null
                  : _descriptionController.text.trim(),
              taxTreatment: _treatment,
            ),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tax setup updated successfully.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _formError = taxApiErrorMessage(error));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(taxApiErrorMessage(error)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final accessAsync = ref.watch(tenantAdminAccessCheckerProvider);
    final mutation = ref.watch(taxMutationControllerProvider);

    if (!widget.isEdit) {
      return accessAsync.when(
        loading: () => const TenantAdminPageScaffold(
          title: 'Add Tax Setup',
          child: TenantAdminLoadingSkeleton(rowCount: 4),
        ),
        error: (_, __) => TenantAdminPageScaffold(
          title: 'Add Tax Setup',
          child: TenantAdminErrorState(
            title: 'Unable to load access rules',
            message: 'Please try again.',
            onRetry: () => ref.invalidate(tenantAdminAccessCheckerProvider),
          ),
        ),
        data: (access) {
          final visibility = TaxSetupListVisibility.resolve(access: access);
          if (!visibility.showCreate) {
            return const TenantAdminPageScaffold(
              title: 'Add Tax Setup',
              child: TenantAdminEmptyState(
                title: 'No access',
                message: 'You do not have permission to create tax setups.',
                icon: Icons.lock_outline,
              ),
            );
          }
          return _buildCreateScaffold(mutation);
        },
      );
    }

    final detailAsync = ref.watch(taxDetailProvider(widget.taxId!));
    return accessAsync.when(
      loading: () => const TenantAdminPageScaffold(
        title: 'Edit Tax Setup',
        child: TenantAdminLoadingSkeleton(rowCount: 5),
      ),
      error: (_, __) => TenantAdminPageScaffold(
        title: 'Edit Tax Setup',
        child: TenantAdminErrorState(
          title: 'Unable to load access rules',
          message: 'Please try again.',
          onRetry: () => ref.invalidate(tenantAdminAccessCheckerProvider),
        ),
      ),
      data: (access) {
        final visibility = TaxSetupListVisibility.resolve(access: access);
        return detailAsync.when(
          loading: () => const TenantAdminPageScaffold(
            title: 'Edit Tax Setup',
            child: TenantAdminLoadingSkeleton(rowCount: 5),
          ),
          error: (error, _) => TenantAdminPageScaffold(
            title: 'Edit Tax Setup',
            child: TenantAdminErrorState(
              title: 'Unable to load tax setup',
              message: taxApiErrorMessage(error),
              onRetry: () =>
                  ref.invalidate(taxDetailProvider(widget.taxId!)),
            ),
          ),
          data: (tax) {
            _populateFromDetail(tax);
            return _buildEditScaffold(
              tax: tax,
              visibility: visibility,
              mutation: mutation,
            );
          },
        );
      },
    );
  }

  Widget _buildCreateScaffold(TaxMutationState mutation) {
    return TenantAdminPageScaffold(
      title: 'Add Tax Setup',
      subtitle: 'Create a tax rate configuration for your products.',
      showBackButton: true,
      onBackButtonPressed: mutation.isSubmitting
          ? null
          : () => Navigator.of(context).pop(),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 880),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_formError != null) ...[
                  Text(
                    _formError!,
                    style: const TextStyle(color: TenantAdminColors.danger),
                  ),
                  const SizedBox(height: TenantAdminSpacing.md),
                ],
                _BasicDetailsSection(
                  nameController: _nameController,
                  codeController: _codeController,
                  descriptionController: _descriptionController,
                  codeEnabled: true,
                  enabled: !mutation.isSubmitting,
                ),
                const SizedBox(height: TenantAdminSpacing.md),
                _TreatmentSection(
                  value: _treatment,
                  enabled: !mutation.isSubmitting,
                  onChanged: (value) {
                    setState(() {
                      _treatment = value;
                      if (value == TaxTreatment.zeroRated) {
                        _rateController.text = '0';
                      }
                    });
                  },
                ),
                const SizedBox(height: TenantAdminSpacing.md),
                _InitialRateSection(
                  treatment: _treatment,
                  rateController: _rateController,
                  effectiveFrom: _effectiveFrom,
                  enabled: !mutation.isSubmitting,
                  onPickDate: _pickEffectiveFrom,
                ),
                const SizedBox(height: TenantAdminSpacing.lg),
                _TaxFormBottomActions(
                  cancelLabel: 'Cancel',
                  primaryLabel: 'Create Tax Setup',
                  loading: mutation.isSubmitting,
                  onCancel: mutation.isSubmitting
                      ? null
                      : () => Navigator.of(context).pop(),
                  onPrimary: mutation.isSubmitting ? null : _submitCreate,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditScaffold({
    required TaxSetup tax,
    required TaxSetupListVisibility visibility,
    required TaxMutationState mutation,
  }) {
    return TenantAdminPageScaffold(
      title: 'Edit Tax Setup',
      subtitle: 'Update details and manage the rate schedule.',
      showBackButton: true,
      onBackButtonPressed: mutation.isSubmitting
          ? null
          : () => Navigator.of(context).pop(),
      actions: [
        if (visibility.showStatusManage)
          TenantAdminOverflowMenu(
            actions: [
              if (tax.status.isActive)
                TenantAdminOverflowAction(
                  id: 'deactivate',
                  icon: Icons.pause_circle_outline,
                  label: 'Deactivate',
                  onSelected: () => _confirmDeactivate(tax),
                )
              else
                TenantAdminOverflowAction(
                  id: 'activate',
                  icon: Icons.play_circle_outline,
                  label: 'Activate',
                  onSelected: () => _activate(tax),
                ),
            ],
          ),
      ],
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _EditSummaryCard(tax: tax),
            const SizedBox(height: TenantAdminSpacing.lg),
            if (_formError != null) ...[
              Text(
                _formError!,
                style: const TextStyle(color: TenantAdminColors.danger),
              ),
              const SizedBox(height: TenantAdminSpacing.lg),
            ],
            _BasicDetailsSection(
              nameController: _nameController,
              codeController: _codeController,
              descriptionController: _descriptionController,
              codeEnabled: visibility.showEdit,
              enabled: visibility.showEdit && !mutation.isSubmitting,
            ),
            const SizedBox(height: TenantAdminSpacing.lg),
            _TreatmentSection(
              value: _treatment,
              enabled: visibility.showEdit && !mutation.isSubmitting,
              onChanged: (value) => setState(() => _treatment = value),
            ),
            const SizedBox(height: TenantAdminSpacing.lg),
            _RateSummarySection(tax: tax),
            const SizedBox(height: TenantAdminSpacing.lg),
            _RateHistorySection(
              tax: tax,
              canSchedule: visibility.showScheduleManage,
              onSchedule: () => _scheduleRate(tax),
              onEditScheduled: (item) => _scheduleRate(tax, editing: item),
              onDeleteScheduled: (item) => _deleteScheduled(tax, item),
            ),
            if (visibility.showEdit) ...[
              const SizedBox(height: TenantAdminSpacing.xl),
              _TaxFormBottomActions(
                cancelLabel: 'Cancel',
                primaryLabel: 'Save Changes',
                loading: mutation.isSubmitting,
                onCancel: mutation.isSubmitting
                    ? null
                    : () => Navigator.of(context).pop(),
                onPrimary:
                    mutation.isSubmitting ? null : () => _submitUpdate(tax),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _activate(TaxSetup tax) async {
    try {
      await ref.read(taxMutationControllerProvider.notifier).activate(tax.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tax setup activated.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(taxApiErrorMessage(error)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _confirmDeactivate(TaxSetup tax) async {
    final action = await showDialog<_DeactivateAction>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deactivate tax setup?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This tax setup is currently used by ${tax.productCount} products.',
            ),
            const SizedBox(height: 12),
            const Text(
              'Existing products will retain this tax assignment, but the tax will no longer be available for new assignments.',
            ),
            const SizedBox(height: 12),
            const Text('Historical transactions remain unchanged.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context, _DeactivateAction.keepActive),
            child: const Text('Keep Active'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: TenantAdminColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () =>
                Navigator.pop(context, _DeactivateAction.deactivate),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );

    if (!mounted || action == null || action == _DeactivateAction.keepActive) {
      return;
    }

    try {
      await ref
          .read(taxMutationControllerProvider.notifier)
          .deactivate(tax.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tax setup deactivated.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(taxApiErrorMessage(error)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _scheduleRate(
    TaxSetup tax, {
    TaxRateHistoryItem? editing,
  }) async {
    final input = await showScheduleRateSheet(
      context: context,
      treatment: tax.taxTreatment,
      currentRate: tax.currentRate,
      currentRateEffectiveFrom: tax.currentRateEffectiveFrom,
      editing: editing,
    );
    if (input == null || !mounted) return;

    try {
      final controller = ref.read(taxMutationControllerProvider.notifier);
      if (editing == null) {
        await controller.scheduleRate(tax.id, input);
      } else {
        await controller.updateScheduledRate(tax.id, editing.id, input);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            editing == null
                ? 'Rate change scheduled.'
                : 'Scheduled rate updated.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(taxApiErrorMessage(error)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _deleteScheduled(
    TaxSetup tax,
    TaxRateHistoryItem item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete scheduled rate?'),
        content: Text(
          'Remove the scheduled ${formatTaxRatePercent(item.rate)} change for ${formatTaxDate(item.effectiveFrom)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: TenantAdminColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await ref
          .read(taxMutationControllerProvider.notifier)
          .deleteScheduledRate(tax.id, item.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Scheduled rate deleted.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(taxApiErrorMessage(error)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

enum _DeactivateAction { keepActive, deactivate }

class _TaxFormBottomActions extends StatelessWidget {
  const _TaxFormBottomActions({
    required this.cancelLabel,
    required this.primaryLabel,
    required this.loading,
    required this.onCancel,
    required this.onPrimary,
  });

  final String cancelLabel;
  final String primaryLabel;
  final bool loading;
  final VoidCallback? onCancel;
  final VoidCallback? onPrimary;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: 1),
        const SizedBox(height: TenantAdminSpacing.md),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onCancel,
                child: Text(cancelLabel),
              ),
            ),
            const SizedBox(width: TenantAdminSpacing.md),
            Expanded(
              child: TenantAdminPrimaryButton(
                label: primaryLabel,
                loading: loading,
                backgroundColor: TenantAdminColors.posHomeAccentOrange,
                onPressed: onPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

InputDecoration _taxFormFieldDecoration({
  String? hint,
  Widget? suffixIcon,
  bool filled = true,
  Color? fillColor,
}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(
      color: TenantAdminColors.mutedText,
      fontSize: 14,
      fontWeight: FontWeight.w500,
    ),
    filled: filled,
    fillColor: fillColor ?? Colors.white,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: TenantAdminColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: TenantAdminColors.border),
    ),
    disabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: TenantAdminColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(
        color: TenantAdminColors.posHomeAccentOrange,
        width: 1.4,
      ),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: TenantAdminColors.danger),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: TenantAdminColors.danger, width: 1.4),
    ),
    suffixIcon: suffixIcon,
  );
}

class _TaxFormFieldLabel extends StatelessWidget {
  const _TaxFormFieldLabel(this.text, {this.required = false});

  final String text;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text.rich(
        TextSpan(
          text: text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF374151),
          ),
          children: required
              ? const [
                  TextSpan(
                    text: ' *',
                    style: TextStyle(
                      color: TenantAdminColors.danger,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ]
              : null,
        ),
      ),
    );
  }
}

class _BasicDetailsSection extends StatelessWidget {
  const _BasicDetailsSection({
    required this.nameController,
    required this.codeController,
    required this.descriptionController,
    required this.codeEnabled,
    required this.enabled,
  });

  final TextEditingController nameController;
  final TextEditingController codeController;
  final TextEditingController descriptionController;
  final bool codeEnabled;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final codeFieldEnabled = enabled && codeEnabled;

    final nameField = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _TaxFormFieldLabel('Tax Name', required: true),
        TextFormField(
          controller: nameController,
          enabled: enabled,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111827),
          ),
          decoration: _taxFormFieldDecoration(
            hint: 'e.g. Standard VAT',
            fillColor: enabled ? Colors.white : const Color(0xFFF3F4F6),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Tax name is required';
            }
            if (value.trim().length > 150) {
              return 'Tax name must be 150 characters or less';
            }
            return null;
          },
        ),
      ],
    );

    final codeField = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _TaxFormFieldLabel('Tax Code', required: true),
        TextFormField(
          controller: codeController,
          enabled: codeFieldEnabled,
          textCapitalization: TextCapitalization.characters,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111827),
          ),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9_\-]')),
          ],
          decoration: _taxFormFieldDecoration(
            hint: 'e.g. VAT_21',
            fillColor:
                codeFieldEnabled ? Colors.white : const Color(0xFFF3F4F6),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Tax code is required';
            }
            return null;
          },
        ),
      ],
    );

    return TenantAdminFormSection(
      title: 'Basic Details',
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final sideBySide = constraints.maxWidth >= 560;
            if (sideBySide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: nameField),
                  const SizedBox(width: TenantAdminSpacing.md),
                  Expanded(child: codeField),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                nameField,
                const SizedBox(height: TenantAdminSpacing.md),
                codeField,
              ],
            );
          },
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _TaxFormFieldLabel('Description'),
            TextFormField(
              controller: descriptionController,
              enabled: enabled,
              maxLines: 3,
              minLines: 3,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF111827),
                height: 1.4,
              ),
              decoration: _taxFormFieldDecoration(
                hint: 'Optional note about this tax setup',
                fillColor: enabled ? Colors.white : const Color(0xFFF3F4F6),
              ).copyWith(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TreatmentSection extends StatelessWidget {
  const _TreatmentSection({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final TaxTreatment value;
  final bool enabled;
  final ValueChanged<TaxTreatment> onChanged;

  @override
  Widget build(BuildContext context) {
    return TenantAdminFormSection(
      title: 'Tax Treatment',
      subtitle: 'Choose how this tax setup applies to products.',
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 720;
            final cards = TaxTreatment.values
                .map(
                  (treatment) => _TreatmentCard(
                    treatment: treatment,
                    selected: value == treatment,
                    enabled: enabled,
                    onTap: () => onChanged(treatment),
                  ),
                )
                .toList();

            if (wide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < cards.length; i++) ...[
                    if (i > 0) const SizedBox(width: 12),
                    Expanded(child: cards[i]),
                  ],
                ],
              );
            }

            return Column(
              children: [
                for (var i = 0; i < cards.length; i++) ...[
                  if (i > 0) const SizedBox(height: 10),
                  cards[i],
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _TreatmentCard extends StatelessWidget {
  const _TreatmentCard({
    required this.treatment,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final TaxTreatment treatment;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? TenantAdminColors.posHomeAccentOrange.withValues(alpha: 0.08)
          : Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? TenantAdminColors.posHomeAccentOrange
                  : TenantAdminColors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                treatment.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: selected
                      ? TenantAdminColors.posHomeAccentOrange
                      : const Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                treatment.description,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                  color: TenantAdminColors.mutedText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InitialRateSection extends StatelessWidget {
  const _InitialRateSection({
    required this.treatment,
    required this.rateController,
    required this.effectiveFrom,
    required this.enabled,
    required this.onPickDate,
  });

  final TaxTreatment treatment;
  final TextEditingController rateController;
  final DateTime effectiveFrom;
  final bool enabled;
  final VoidCallback onPickDate;

  @override
  Widget build(BuildContext context) {
    final showRate = treatment != TaxTreatment.exempt;
    final rateLocked = treatment == TaxTreatment.zeroRated;

    final rateField = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _TaxFormFieldLabel('Rate (%)', required: true),
        TextFormField(
          controller: rateController,
          enabled: enabled && !rateLocked,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111827),
          ),
          decoration: _taxFormFieldDecoration(
            hint: 'e.g. 21',
            fillColor: (enabled && !rateLocked)
                ? Colors.white
                : const Color(0xFFF3F4F6),
          ).copyWith(
            helperText: rateLocked ? 'Zero rated setups always use 0%.' : null,
            helperStyle: const TextStyle(
              fontSize: 12,
              color: TenantAdminColors.mutedText,
            ),
          ),
          validator: (value) {
            if (!showRate || rateLocked) return null;
            final parsed = double.tryParse(value?.trim() ?? '');
            if (parsed == null) return 'Enter a valid rate';
            if (parsed < 0 || parsed > 100) {
              return 'Rate must be between 0 and 100';
            }
            return null;
          },
        ),
      ],
    );

    final dateField = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _TaxFormFieldLabel('Effective From', required: true),
        InkWell(
          onTap: enabled ? onPickDate : null,
          borderRadius: BorderRadius.circular(10),
          child: InputDecorator(
            decoration: _taxFormFieldDecoration(
              hint: 'DD/MM/YYYY',
              fillColor: enabled ? Colors.white : const Color(0xFFF3F4F6),
              suffixIcon: const Icon(
                Icons.calendar_today_outlined,
                size: 18,
                color: Color(0xFF6B7280),
              ),
            ),
            child: Text(
              formatTaxDate(effectiveFrom),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
            ),
          ),
        ),
      ],
    );

    return TenantAdminFormSection(
      title: 'Initial Rate',
      children: [
        if (!showRate)
          const Text(
            'Exempt setups do not use a percentage rate.',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: TenantAdminColors.mutedText,
            ),
          ),
        LayoutBuilder(
          builder: (context, constraints) {
            final sideBySide = showRate && constraints.maxWidth >= 560;
            if (sideBySide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: rateField),
                  const SizedBox(width: TenantAdminSpacing.md),
                  Expanded(child: dateField),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (showRate) ...[
                  rateField,
                  const SizedBox(height: TenantAdminSpacing.md),
                ],
                dateField,
              ],
            );
          },
        ),
      ],
    );
  }
}

class _EditSummaryCard extends StatelessWidget {
  const _EditSummaryCard({required this.tax});

  final TaxSetup tax;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(TenantAdminSpacing.xl),
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
        border: Border.all(color: TenantAdminColors.border),
      ),
      child: Wrap(
        spacing: 24,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _SummaryItem(label: 'Name', value: tax.name),
          _SummaryItem(label: 'Code', value: tax.code),
          _SummaryItem(label: 'Treatment', value: tax.taxTreatment.label),
          _SummaryItem(label: 'Products', value: '${tax.productCount}'),
          TenantAdminStatusBadge(
            label: tax.status.label,
            status: tax.status.isActive
                ? TenantAdminStatusType.active
                : TenantAdminStatusType.inactive,
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: TenantAdminColors.mutedText,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: TenantAdminColors.bodyText,
          ),
        ),
      ],
    );
  }
}

class _RateSummarySection extends StatelessWidget {
  const _RateSummarySection({required this.tax});

  final TaxSetup tax;

  @override
  Widget build(BuildContext context) {
    return TenantAdminFormSection(
      title: 'Rates',
      children: [
        Row(
          children: [
            Expanded(
              child: _RateInfoCard(
                title: 'Current Rate',
                value: formatCurrentRateDisplay(
                  treatment: tax.taxTreatment,
                  currentRate: tax.currentRate,
                ),
                subtitle: tax.currentRateEffectiveFrom == null
                    ? null
                    : 'Since ${formatTaxDate(tax.currentRateEffectiveFrom)}',
              ),
            ),
            const SizedBox(width: TenantAdminSpacing.md),
            Expanded(
              child: _RateInfoCard(
                title: 'Next Scheduled',
                value: formatNextChange(
                  nextRate: tax.nextRate,
                  nextRateEffectiveFrom: tax.nextRateEffectiveFrom,
                ),
                subtitle: tax.nextRate == null ? 'No upcoming changes' : null,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RateInfoCard extends StatelessWidget {
  const _RateInfoCard({
    required this.title,
    required this.value,
    this.subtitle,
  });

  final String title;
  final String value;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(TenantAdminSpacing.lg),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        border: Border.all(color: TenantAdminColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: TenantAdminColors.mutedText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: TenantAdminColors.bodyText,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: const TextStyle(
                fontSize: 12,
                color: TenantAdminColors.mutedText,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RateHistorySection extends StatelessWidget {
  const _RateHistorySection({
    required this.tax,
    required this.canSchedule,
    required this.onSchedule,
    required this.onEditScheduled,
    required this.onDeleteScheduled,
  });

  final TaxSetup tax;
  final bool canSchedule;
  final VoidCallback onSchedule;
  final ValueChanged<TaxRateHistoryItem> onEditScheduled;
  final ValueChanged<TaxRateHistoryItem> onDeleteScheduled;

  @override
  Widget build(BuildContext context) {
    final history = tax.rateHistory ?? const <TaxRateHistoryItem>[];

    return TenantAdminFormSection(
      title: 'Rate History',
      trailing: canSchedule
          ? TenantAdminPrimaryButton(
              label: 'Schedule Rate Change',
              icon: Icons.schedule,
              backgroundColor: TenantAdminColors.posHomeAccentOrange,
              onPressed: onSchedule,
            )
          : null,
      children: [
        if (history.isEmpty)
          const Text(
            'No rate history available yet.',
            style: TextStyle(color: TenantAdminColors.mutedText),
          )
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Rate')),
                DataColumn(label: Text('Effective From')),
                DataColumn(label: Text('Effective To')),
                DataColumn(label: Text('State')),
                DataColumn(label: Text('Notes')),
                DataColumn(label: Text('Actions')),
              ],
              rows: [
                for (final item in history)
                  DataRow(
                    cells: [
                      DataCell(
                        Text(
                          tax.taxTreatment == TaxTreatment.exempt
                              ? 'Exempt'
                              : formatTaxRatePercent(item.rate),
                        ),
                      ),
                      DataCell(Text(formatTaxDate(item.effectiveFrom))),
                      DataCell(Text(formatTaxDate(item.effectiveTo))),
                      DataCell(Text(item.state.label)),
                      DataCell(Text(item.notes?.trim().isNotEmpty == true
                          ? item.notes!
                          : '—')),
                      DataCell(
                        item.state == TaxRateHistoryState.scheduled && canSchedule
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: 'Edit',
                                    onPressed: () => onEditScheduled(item),
                                    icon: const Icon(Icons.edit_outlined),
                                  ),
                                  IconButton(
                                    tooltip: 'Delete',
                                    onPressed: () => onDeleteScheduled(item),
                                    icon: const Icon(Icons.delete_outline),
                                  ),
                                ],
                              )
                            : const Text('—'),
                      ),
                    ],
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
