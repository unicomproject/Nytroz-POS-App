import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../presentation/theme/tenant_admin_theme.dart';
import '../../../../presentation/widgets/tenant_admin_buttons.dart';
import '../../domain/tax_aggregate.dart';
import '../../domain/tax_treatment.dart';
import '../utils/tax_formatters.dart';

Future<TaxRateScheduleInput?> showScheduleRateSheet({
  required BuildContext context,
  required TaxTreatment treatment,
  required double? currentRate,
  DateTime? currentRateEffectiveFrom,
  TaxRateHistoryItem? editing,
}) {
  final screenWidth = MediaQuery.sizeOf(context).width;
  final isMobile = screenWidth < TenantAdminBreakpoints.smallTablet;
  final drawerWidth = screenWidth < 480 ? screenWidth : 460.0;

  if (isMobile) {
    return showModalBottomSheet<TaxRateScheduleInput>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: TenantAdminColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.94,
        child: ScheduleRateSheet(
          treatment: treatment,
          currentRate: currentRate,
          currentRateEffectiveFrom: currentRateEffectiveFrom,
          editing: editing,
        ),
      ),
    );
  }

  return showGeneralDialog<TaxRateScheduleInput>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close schedule rate change',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      return Align(
        alignment: Alignment.centerRight,
        child: Material(
          color: TenantAdminColors.surface,
          elevation: 12,
          child: SizedBox(
            width: drawerWidth,
            height: double.infinity,
            child: ScheduleRateSheet(
              treatment: treatment,
              currentRate: currentRate,
              currentRateEffectiveFrom: currentRateEffectiveFrom,
              editing: editing,
            ),
          ),
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final slide = Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        ),
      );
      return SlideTransition(position: slide, child: child);
    },
  );
}

class ScheduleRateSheet extends StatefulWidget {
  const ScheduleRateSheet({
    super.key,
    required this.treatment,
    required this.currentRate,
    this.currentRateEffectiveFrom,
    this.editing,
  });

  final TaxTreatment treatment;
  final double? currentRate;
  final DateTime? currentRateEffectiveFrom;
  final TaxRateHistoryItem? editing;

  @override
  State<ScheduleRateSheet> createState() => _ScheduleRateSheetState();
}

class _ScheduleRateSheetState extends State<ScheduleRateSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _rateController;
  late final TextEditingController _notesController;
  late DateTime _effectiveFrom;
  bool _submitting = false;

  static const _notesMax = 200;

  bool get _isEdit => widget.editing != null;
  bool get _rateLocked => widget.treatment == TaxTreatment.zeroRated;
  bool get _isExempt => widget.treatment == TaxTreatment.exempt;

  @override
  void initState() {
    super.initState();
    final initialRate = widget.editing?.rate ??
        (widget.treatment == TaxTreatment.zeroRated ? 0 : null);
    _rateController = TextEditingController(
      text: initialRate == null
          ? ''
          : (initialRate.truncateToDouble() == initialRate
              ? initialRate.toStringAsFixed(0)
              : initialRate.toString()),
    );
    _notesController = TextEditingController(text: widget.editing?.notes ?? '');
    _effectiveFrom = widget.editing?.effectiveFrom ??
        DateTime.now().add(const Duration(days: 1));
  }

  @override
  void dispose() {
    _rateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _formatInputDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _effectiveFrom,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) {
      setState(() => _effectiveFrom = picked);
    }
  }

  void _submit() {
    if (_submitting) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    final rate = _isExempt
        ? 0.0
        : (_rateLocked
            ? 0.0
            : (double.tryParse(_rateController.text.trim()) ?? 0));

    Navigator.of(context).pop(
      TaxRateScheduleInput(
        newRate: rate,
        effectiveFrom: _effectiveFrom,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      ),
    );
  }

  InputDecoration _fieldDecoration({
    required String hint,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: TenantAdminColors.mutedText,
        fontSize: 14,
      ),
      filled: true,
      fillColor: TenantAdminColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: TenantAdminColors.border),
      ),
      enabledBorder: OutlineInputBorder(
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
      suffixIcon: suffixIcon,
    );
  }

  @override
  Widget build(BuildContext context) {
    final previewCurrent = formatCurrentRateDisplay(
      treatment: widget.treatment,
      currentRate: widget.currentRate,
    );
    final parsedNew =
        _rateLocked ? 0.0 : double.tryParse(_rateController.text.trim());
    final previewNew =
        _isExempt ? 'Exempt' : formatTaxRatePercent(parsedNew);

    return Material(
      color: Colors.white,
      child: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 8, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isEdit
                                ? 'Edit Scheduled Rate'
                                : 'Schedule Rate Change',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF111827),
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Add a future rate and effective date. The new rate will apply automatically from the effective date.',
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.4,
                              color: Color(0xFF6B7280),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: _submitting
                          ? null
                          : () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Divider(height: 1, color: TenantAdminColors.border),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!_isExempt) ...[
                        const _FieldLabel('New Rate (%)'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _rateController,
                          enabled: !_rateLocked && !_submitting,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9.]'),
                            ),
                          ],
                          decoration: _fieldDecoration(
                            hint: 'e.g. 21',
                          ).copyWith(
                            filled: true,
                            fillColor: _rateLocked
                                ? const Color(0xFFF3F4F6)
                                : Colors.white,
                          ),
                          onChanged: (_) => setState(() {}),
                          validator: (value) {
                            if (_rateLocked || _isExempt) return null;
                            final parsed =
                                double.tryParse(value?.trim() ?? '');
                            if (parsed == null) {
                              return 'Enter a valid rate';
                            }
                            if (parsed < 0 || parsed > 100) {
                              return 'Rate must be between 0 and 100';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                      const _FieldLabel('Effective From'),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _submitting ? null : _pickDate,
                        borderRadius: BorderRadius.circular(10),
                        child: InputDecorator(
                          decoration: _fieldDecoration(
                            hint: 'DD/MM/YYYY',
                            suffixIcon: const Icon(
                              Icons.calendar_today_outlined,
                              size: 20,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          child: Text(
                            _formatInputDate(_effectiveFrom),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF111827),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const _FieldLabel('Notes (optional)'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _notesController,
                        enabled: !_submitting,
                        maxLines: 4,
                        maxLength: _notesMax,
                        onChanged: (_) => setState(() {}),
                        decoration: _fieldDecoration(
                          hint: 'Add a note for this scheduled change...',
                        ).copyWith(
                          counterText: '',
                          alignLabelWithHint: true,
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '${_notesController.text.length} / $_notesMax',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF9CA3AF),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const _InfoBanner(
                        icon: Icons.info_outline,
                        background: Color(0xFFEFF6FF),
                        border: Color(0xFFBFDBFE),
                        iconColor: Color(0xFF2563EB),
                        textColor: Color(0xFF1E3A8A),
                        message:
                            'Transactions on or after the effective date will use the new rate.',
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Preview',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF374151),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _PreviewCard(
                              label: 'Current Rate',
                              value: previewCurrent,
                              subtitle: widget.currentRateEffectiveFrom == null
                                  ? 'Current effective rate'
                                  : 'Effective since ${formatTaxDate(widget.currentRateEffectiveFrom)}',
                              background: const Color(0xFFECFDF5),
                              border: const Color(0xFFA7F3D0),
                              labelColor: const Color(0xFF047857),
                              valueColor: const Color(0xFF065F46),
                              subtitleColor: const Color(0xFF059669),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Icon(
                              Icons.arrow_forward,
                              size: 20,
                              color: Color(0xFF9CA3AF),
                            ),
                          ),
                          Expanded(
                            child: _PreviewCard(
                              label: 'New Rate',
                              value: previewNew == '—' ? '—' : previewNew,
                              subtitle:
                                  'From ${formatTaxDate(_effectiveFrom)}',
                              background: const Color(0xFFFFF1EE),
                              border: const Color(0xFFFFD0C2),
                              labelColor: const Color(0xFFC2410C),
                              valueColor:
                                  TenantAdminColors.posHomeAccentOrange,
                              subtitleColor: const Color(0xFFEA580C),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const _InfoBanner(
                        icon: Icons.lightbulb_outline,
                        background: Color(0xFFFFFBEB),
                        border: Color(0xFFFDE68A),
                        iconColor: Color(0xFFD97706),
                        textColor: Color(0xFF92400E),
                        message:
                            'You can add more future rates later. Overlapping schedules are not allowed.',
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1, color: TenantAdminColors.border),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TenantAdminSecondaryButton(
                        label: 'Cancel',
                        onPressed: _submitting
                            ? null
                            : () => Navigator.of(context).pop(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: TenantAdminPrimaryButton(
                        label:
                            _isEdit ? 'Save Schedule' : 'Schedule Change',
                        loading: _submitting,
                        backgroundColor:
                            TenantAdminColors.posHomeAccentOrange,
                        onPressed: _submit,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Color(0xFF374151),
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({
    required this.icon,
    required this.background,
    required this.border,
    required this.iconColor,
    required this.textColor,
    required this.message,
  });

  final IconData icon;
  final Color background;
  final Color border;
  final Color iconColor;
  final Color textColor;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.35,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.background,
    required this.border,
    required this.labelColor,
    required this.valueColor,
    required this.subtitleColor,
  });

  final String label;
  final String value;
  final String subtitle;
  final Color background;
  final Color border;
  final Color labelColor;
  final Color valueColor;
  final Color subtitleColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: labelColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1.1,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: subtitleColor,
            ),
          ),
        ],
      ),
    );
  }
}
