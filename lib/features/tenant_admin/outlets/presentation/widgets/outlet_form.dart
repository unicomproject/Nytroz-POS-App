import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/outlet_create_options.dart';
import '../../domain/entities/outlet_details.dart';
import '../utils/outlet_api_errors.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_buttons.dart';
import '../../../presentation/widgets/tenant_admin_responsive_form_grid.dart';
import 'business_hours_editor.dart';
import 'outlet_image_upload_card.dart';
import '../providers/outlet_image_upload_provider.dart';

class OutletForm extends ConsumerStatefulWidget {
  const OutletForm({
    super.key,
    required this.onSubmit,
    this.initialValue,
    this.createOptions,
    this.backendErrors = const {},
    this.submitting = false,
    this.onDiscard,
  });

  final OutletFormData? initialValue;
  final OutletCreateOptions? createOptions;
  final Map<String, String> backendErrors;
  final bool submitting;
  final Future<void> Function(OutletFormData form) onSubmit;
  final Future<void> Function(String? mediaAssetId)? onDiscard;

  @override
  ConsumerState<OutletForm> createState() => _OutletFormState();
}

class _OutletFormState extends ConsumerState<OutletForm> {
  static const _steps = [
    'Outlet Details',
    'Location & Contact',
    'Business Hours',
    'Review & Create',
  ];

  final _formKey = GlobalKey<FormState>();
  var _step = 0;
  var _submitted = false;

  late final TextEditingController _outletName;
  late final TextEditingController _mainPhoneNumber;
  late final TextEditingController _emailAddress;
  late final TextEditingController _contactName;
  late final TextEditingController _contactPhone;
  late final TextEditingController _contactEmail;
  late final TextEditingController _addressLine1;
  late final TextEditingController _addressLine2;
  late final TextEditingController _city;
  late final TextEditingController _state;
  late final TextEditingController _countryCode;
  late final TextEditingController _postalCode;
  late final TextEditingController _timezone;
  late List<BusinessHoursDraft> _openingHours;
  final _businessHourErrors = <String, String>{};

  String _outletType = 'STORE';
  String _status = 'ACTIVE';
  bool _isDefaultOutlet = false;
  late String _initialSignature;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialValue;
    final defaults = widget.createOptions?.defaults;
    _outletName = TextEditingController(text: initial?.outletName ?? '');
    _outletType = _resolveOptionValue(
      initial?.outletType ??
          _firstOptionValue(widget.createOptions?.outletTypes),
      widget.createOptions?.outletTypes,
      normalize: _normalizeCanonicalOutletType,
    );
    _status = _normalizeStatus(initial?.status ?? defaults?.status ?? 'ACTIVE');
    _mainPhoneNumber =
        TextEditingController(text: initial?.mainPhoneNumber ?? '');
    _emailAddress = TextEditingController(text: initial?.emailAddress ?? '');
    _contactName = TextEditingController(text: initial?.contactName ?? '');
    _contactPhone = TextEditingController(text: initial?.contactPhone ?? '');
    _contactEmail = TextEditingController(text: initial?.contactEmail ?? '');
    _addressLine1 = TextEditingController(text: initial?.addressLine1 ?? '');
    _addressLine2 = TextEditingController(text: initial?.addressLine2 ?? '');
    _city = TextEditingController(text: initial?.city ?? '');
    _state = TextEditingController(text: initial?.state ?? '');
    _countryCode = TextEditingController(
        text: initial?.country ?? defaults?.countryCode ?? '');
    _postalCode = TextEditingController(text: initial?.postalCode ?? '');
    _timezone = TextEditingController(
      text: _resolveOptionValue(
        initial?.timezone ?? defaults?.timezone,
        widget.createOptions?.timezones,
      ),
    );
    _isDefaultOutlet = initial?.isDefaultOutlet ?? false;
    _openingHours = _initialOpeningHours(initial?.openingHours);
    
    if (initial?.imageMediaAssetId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(outletImageUploadControllerProvider.notifier)
            .initializeExistingImage(
              mediaAssetId: initial!.imageMediaAssetId!,
              imageUrl: initial.imageUrl,
            );
        }
      });
    }

    _initialSignature = _signature();
  }

  @override
  void didUpdateWidget(covariant OutletForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.backendErrors.isEmpty ||
        _mapsEqual(widget.backendErrors, oldWidget.backendErrors)) {
      return;
    }

    final errorStep = outletErrorStep(widget.backendErrors);
    if (errorStep != null && errorStep != _step) {
      setState(() => _step = errorStep);
    }
  }

  @override
  void dispose() {
    _outletName.dispose();
    _mainPhoneNumber.dispose();
    _emailAddress.dispose();
    _contactName.dispose();
    _contactPhone.dispose();
    _contactEmail.dispose();
    _addressLine1.dispose();
    _addressLine2.dispose();
    _city.dispose();
    _state.dispose();
    _countryCode.dispose();
    _postalCode.dispose();
    _timezone.dispose();
    for (final hour in _openingHours) {
      hour.openTime.dispose();
      hour.closeTime.dispose();
    }
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
          _buildStep(),
          const SizedBox(height: TenantAdminSpacing.xl),
          _OutletWizardActions(
            step: _step,
            lastStep: _steps.length - 1,
            submitting: widget.submitting,
            onBack: _step == 0 ? null : () => setState(() => _step -= 1),
            onNext: _continue,
            onCancel: _confirmDiscard,
          ),
        ],
      ),
    );
  }

  Widget _buildStep() {
    return switch (_step) {
      0 => _OutletDetailsStep(
          outletName: _outletName,
          outletPhone: _mainPhoneNumber,
          outletEmail: _emailAddress,
          outletType: _outletType,
          status: _status,
          timezone: _timezone,
          outletTypes: widget.createOptions?.outletTypes ?? const [],
          timezones: widget.createOptions?.timezones ?? const [],
          isDefaultOutlet: _isDefaultOutlet,
          errors: widget.backendErrors,
          onOutletTypeChanged: (value) => setState(() => _outletType = value),
          onStatusChanged: (value) => setState(() => _status = value),
          onDefaultChanged: (value) => setState(() => _isDefaultOutlet = value),
        ),
      1 => Consumer(builder: (context, ref, _) {
          final imageState = ref.watch(outletImageUploadControllerProvider);
          final imageController =
              ref.read(outletImageUploadControllerProvider.notifier);
          return _OutletLocationContactStep(
            addressLine1: _addressLine1,
            addressLine2: _addressLine2,
            city: _city,
            state: _state,
            postalCode: _postalCode,
            countryCode: _countryCode,
            contactName: _contactName,
            contactPhone: _contactPhone,
            contactEmail: _contactEmail,
            countries: widget.createOptions?.countries ?? const [],
            errors: widget.backendErrors,
            imageState: imageState,
            onChooseImage: imageController.chooseImage,
            onReplaceImage: imageController.replaceImage,
            onRemoveImage: imageController.removeImage,
            onRetryImageUpload: imageController.retryUpload,
          );
        }),
      2 => BusinessHoursEditor(
          hours: _openingHours,
          errors: _businessHourErrors,
          onChanged: () => setState(_businessHourErrors.clear),
          onApplyMondayToWeekdays: _applyMondayToWeekdays,
        ),
      _ => _OutletReviewStep(
          form: _formData(),
          onEdit: (step) => setState(() => _step = step),
        ),
    };
  }

  Future<void> _continue() async {
    setState(() => _submitted = true);

    if (!_validateCurrentStep()) {
      return;
    }

    if (_step < _steps.length - 1) {
      setState(() => _step += 1);
      return;
    }

    await widget.onSubmit(_formData());
  }

  bool _validateCurrentStep() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return false;
    }

    if (_step == 2) {
      final errors = _validateBusinessHours();
      setState(() {
        _businessHourErrors
          ..clear()
          ..addAll(errors);
      });
      return errors.isEmpty;
    }

    return true;
  }

  Map<String, String> _validateBusinessHours() {
    final errors = <String, String>{};
    final seenDays = <int>{};

    for (final hour in _openingHours) {
      if (!seenDays.add(hour.dayOfWeek)) {
        errors['businessHours.${hour.dayOfWeek}'] =
            'Business hours can contain only one entry per day.';
        continue;
      }

      if (hour.closed) {
        continue;
      }

      final open = _minutes(hour.openTime.text);
      final close = _minutes(hour.closeTime.text);
      if (open == null || close == null) {
        errors['businessHours.${hour.dayOfWeek}'] =
            'Opening and closing times are required when the outlet is open.';
      } else if (open >= close) {
        errors['businessHours.${hour.dayOfWeek}'] =
            'Closing time must be later than opening time.';
      }
    }

    return errors;
  }

  void _applyMondayToWeekdays() {
    final monday = _openingHours.firstWhere((hour) => hour.dayOfWeek == 1);
    setState(() {
      for (final hour in _openingHours
          .where((hour) => hour.dayOfWeek >= 1 && hour.dayOfWeek <= 5)) {
        hour.closed = monday.closed;
        hour.openTime.text = monday.openTime.text;
        hour.closeTime.text = monday.closeTime.text;
      }
      _businessHourErrors.clear();
    });
  }

  OutletFormData _formData() {
    final imageState = ref.read(outletImageUploadControllerProvider);
    final currentImageId = imageState.mediaAssetId;

    OutletImageOperation imageOperation = OutletImageOperation.keep;
    final initialImageId = widget.initialValue?.imageMediaAssetId;
    if (currentImageId != initialImageId) {
      if (currentImageId == null) {
        imageOperation = OutletImageOperation.remove;
      } else {
        imageOperation = OutletImageOperation.replace;
      }
    }

    return OutletFormData(
      outletName: _outletName.text.trim(),
      outletType: _outletType,
      status: _status,
      mainPhoneNumber: _mainPhoneNumber.text.trim(),
      emailAddress: _emailAddress.text.trim(),
      contactName: _nullable(_contactName.text),
      contactPhone: _nullable(_contactPhone.text),
      contactEmail: _nullable(_contactEmail.text),
      imageMediaAssetId: currentImageId,
      imageOperation: imageOperation,
      isDefaultOutlet: _isDefaultOutlet,
      addressLine1: _addressLine1.text.trim(),
      addressLine2: _nullable(_addressLine2.text),
      city: _city.text.trim(),
      state: _nullable(_state.text),
      country: _countryCode.text.trim().toUpperCase(),
      postalCode: _postalCode.text.trim(),
      timezone: _timezone.text.trim(),
      openingHours: [
        for (final hour in _openingHours)
          OutletOpeningHour(
            day: hour.dayLabel,
            openTime: hour.openTime.text.trim(),
            closeTime: hour.closeTime.text.trim(),
            closed: hour.closed,
          ),
      ],
    );
  }

  Future<void> _confirmDiscard() async {
    final currentImageId = ref.read(outletImageUploadControllerProvider).mediaAssetId;
    if (_signature() == _initialSignature) {
      await widget.onDiscard?.call(currentImageId);
      return;
    }
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Discard outlet setup?'),
        content: const Text('Your entered information will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Continue editing'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Discard and return to Outlets'),
          ),
        ],
      ),
    );
    if (discard == true && mounted) {
      await widget.onDiscard?.call(currentImageId);
    }
  }

  String _signature() => [
        _outletName.text,
        _outletType,
        _status,
        _mainPhoneNumber.text,
        _emailAddress.text,
        _contactName.text,
        _contactPhone.text,
        _contactEmail.text,
        _addressLine1.text,
        _addressLine2.text,
        _city.text,
        _state.text,
        _countryCode.text,
        _postalCode.text,
        _timezone.text,
        _isDefaultOutlet.toString(),
        ref.read(outletImageUploadControllerProvider).mediaAssetId ?? '',
        for (final hour in _openingHours)
          '${hour.dayOfWeek}|${hour.openTime.text}|${hour.closeTime.text}|${hour.closed}',
      ].join('\u001f');

  bool _mapsEqual(Map<String, String> a, Map<String, String> b) {
    if (a.length != b.length) {
      return false;
    }
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) {
        return false;
      }
    }
    return true;
  }
}

class _OutletDetailsStep extends StatelessWidget {
  const _OutletDetailsStep({
    required this.outletName,
    required this.outletPhone,
    required this.outletEmail,
    required this.outletType,
    required this.status,
    required this.timezone,
    required this.outletTypes,
    required this.timezones,
    required this.isDefaultOutlet,
    required this.errors,
    required this.onOutletTypeChanged,
    required this.onStatusChanged,
    required this.onDefaultChanged,
  });

  final TextEditingController outletName;
  final TextEditingController outletPhone;
  final TextEditingController outletEmail;
  final String outletType;
  final String status;
  final TextEditingController timezone;
  final List<OutletSelectOption> outletTypes;
  final List<OutletSelectOption> timezones;
  final bool isDefaultOutlet;
  final Map<String, String> errors;
  final ValueChanged<String> onOutletTypeChanged;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<bool> onDefaultChanged;

  @override
  Widget build(BuildContext context) {
    final form = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _twoColumnRow(
          _field(
            'outletName',
            'Outlet Name',
            outletName,
            errors: errors,
            isRequired: true,
            maxLength: 200,
            icon: Icons.storefront_outlined,
          ),
          _buildOutletCode(context),
        ),
        const SizedBox(height: TenantAdminSpacing.lg),
        _twoColumnRow(
          _outletTypeDropdown(),
          _statusSelector(context),
        ),
        const SizedBox(height: TenantAdminSpacing.lg),
        _twoColumnRow(
          _buildManagerField(context),
          _field(
            'contactPhone',
            'Outlet Phone (optional)',
            outletPhone,
            errors: errors,
            icon: Icons.phone_outlined,
          ),
        ),
        const SizedBox(height: TenantAdminSpacing.lg),
        _twoColumnRow(
          _field(
            'contactEmail',
            'Outlet Email (optional)',
            outletEmail,
            errors: errors,
            icon: Icons.mail_outline,
          ),
          _timezoneField(),
        ),
        const SizedBox(height: TenantAdminSpacing.lg),
        _twoColumnRow(
          _buildSwitchOption(
            title: 'Main / Central Outlet',
            subtitle:
                'Designate this outlet as the main or central outlet. Only one central outlet is allowed per tenant.',
            value: false,
            onChanged: (v) {},
          ),
          _buildSwitchOption(
            title: 'Default for New Tills',
            subtitle:
                'Newly created tills will be assigned to this outlet by default.',
            value: isDefaultOutlet,
            onChanged: onDefaultChanged,
          ),
        ),
      ],
    );

    return form;
  }

  Widget _buildSwitchOption({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(TenantAdminSpacing.lg),
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        border: Border.all(
          color: value ? TenantAdminColors.posHomeOrangeEnd.withValues(alpha: 0.3) : TenantAdminColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: TenantAdminColors.bodyText,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              Switch.adaptive(
                value: value,
                onChanged: onChanged,
                activeColor: Colors.white,
                activeTrackColor: TenantAdminColors.posHomeOrangeEnd,
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: const Color(0xFFE2E8F0),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              color: TenantAdminColors.mutedText,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManagerField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Text(
              'Outlet Manager ',
              style: TextStyle(
                color: TenantAdminColors.bodyText,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            Text('*', style: TextStyle(color: TenantAdminColors.danger)),
          ],
        ),
        const SizedBox(height: TenantAdminSpacing.sm),
        TextFormField(
          enabled: false,
          decoration: InputDecoration(
            hintText: 'Search and select a user',
            hintStyle: const TextStyle(
                color: TenantAdminColors.mutedText,
                fontWeight: FontWeight.normal),
            prefixIcon:
                const Icon(Icons.search, color: TenantAdminColors.mutedText),
            filled: true,
            fillColor: TenantAdminColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TenantAdminRadius.md),
              borderSide: const BorderSide(color: TenantAdminColors.border),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TenantAdminRadius.md),
              borderSide: const BorderSide(color: TenantAdminColors.border),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: TenantAdminSpacing.lg,
              vertical: TenantAdminSpacing.md,
            ),
          ),
        ),
        const SizedBox(height: TenantAdminSpacing.xs),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFE0F2FE),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.info_outline, size: 12, color: Color(0xFF0284C7)),
              SizedBox(width: 4),
              Text(
                'Eligible tenant users only',
                style: TextStyle(
                  color: Color(0xFF0284C7),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOutletCode(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Text(
              'Outlet Code ',
              style: TextStyle(
                color: TenantAdminColors.bodyText,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            Text('*', style: TextStyle(color: TenantAdminColors.danger)),
          ],
        ),
        const SizedBox(height: TenantAdminSpacing.sm),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: TenantAdminSpacing.lg,
            vertical: TenantAdminSpacing.md,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9), // subtle slate
            borderRadius: BorderRadius.circular(TenantAdminRadius.md),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              const Icon(Icons.lock_outline, size: 18, color: TenantAdminColors.mutedText),
              const SizedBox(width: TenantAdminSpacing.sm),
              const Expanded(
                child: Text(
                  'OUT-2025-0005',
                  style: TextStyle(
                    color: Color(0xFF475569),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Auto-Generated',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'This unique code cannot be changed.',
          style: TextStyle(
            color: TenantAdminColors.mutedText,
            fontSize: 11,
          ),
        ),
      ],
    );
  }



  Widget _outletTypeDropdown() {
    final options = outletTypes.isEmpty && outletType.trim().isNotEmpty
        ? [
            OutletSelectOption(
              value: _normalizeCanonicalOutletType(outletType),
              label: _displayOutletType(outletType),
            ),
          ]
        : outletTypes;
    final value = _matchingOptionValue(outletType, options);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Text(
              'Outlet Type ',
              style: TextStyle(
                color: TenantAdminColors.bodyText,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            Text('*', style: TextStyle(color: TenantAdminColors.danger)),
          ],
        ),
        const SizedBox(height: TenantAdminSpacing.sm),
        DropdownButtonFormField<String>(
          isExpanded: true,
          initialValue: value,
          icon: const Icon(Icons.keyboard_arrow_down,
              color: TenantAdminColors.mutedText),
          decoration: InputDecoration(
            errorText: errors['outletType'],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TenantAdminRadius.md),
              borderSide: const BorderSide(color: TenantAdminColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TenantAdminRadius.md),
              borderSide: const BorderSide(color: TenantAdminColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TenantAdminRadius.md),
              borderSide: const BorderSide(color: TenantAdminColors.primary),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: TenantAdminSpacing.lg,
              vertical: TenantAdminSpacing.md,
            ),
          ),
          items: [
            for (final option in options)
              DropdownMenuItem(
                value: option.value,
                child: Text(option.label),
              ),
          ],
          validator: (value) => _outletTypeValidator(value, options),
          onChanged: (value) {
            if (value != null) {
              onOutletTypeChanged(_normalizeCanonicalOutletType(value));
            }
          },
        ),
      ],
    );
  }

  Widget _timezoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Text(
              'Timezone ',
              style: TextStyle(
                color: TenantAdminColors.bodyText,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            Text('*', style: TextStyle(color: TenantAdminColors.danger)),
          ],
        ),
        const SizedBox(height: TenantAdminSpacing.sm),
        if (timezones.isNotEmpty)
          DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: _matchingOptionValue(timezone.text, timezones),
            icon: const Icon(Icons.keyboard_arrow_down,
                color: TenantAdminColors.mutedText),
            decoration: InputDecoration(
              errorText: errors['timezone'],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(TenantAdminRadius.md),
                borderSide: const BorderSide(color: TenantAdminColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(TenantAdminRadius.md),
                borderSide: const BorderSide(color: TenantAdminColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(TenantAdminRadius.md),
                borderSide: const BorderSide(color: TenantAdminColors.primary),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: TenantAdminSpacing.lg,
                vertical: TenantAdminSpacing.md,
              ),
            ),
            items: [
              for (final option in timezones)
                DropdownMenuItem(
                  value: option.value,
                  child: Text(option.label),
                ),
            ],
            validator: (value) => _timezoneValidator(value, timezones),
            onChanged: (value) {
              timezone.text = value ?? '';
            },
          )
        else
          TextFormField(
            controller: timezone,
            decoration: InputDecoration(
              hintText: 'Enter timezone (e.g., UTC)',
              hintStyle: const TextStyle(
                  color: TenantAdminColors.mutedText,
                  fontWeight: FontWeight.normal),
              errorText: errors['timezone'],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(TenantAdminRadius.md),
                borderSide: const BorderSide(color: TenantAdminColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(TenantAdminRadius.md),
                borderSide: const BorderSide(color: TenantAdminColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(TenantAdminRadius.md),
                borderSide: const BorderSide(color: TenantAdminColors.primary),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: TenantAdminSpacing.lg,
                vertical: TenantAdminSpacing.md,
              ),
            ),
            validator: (value) {
              final trimmed = value?.trim() ?? '';
              if (trimmed.isEmpty) return 'Timezone is required.';
              if (trimmed.length > 80) {
                return 'Timezone must be 80 characters or less.';
              }
              return null;
            },
          ),
      ],
    );
  }

  Widget _statusSelector(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Text(
              'Status ',
              style: TextStyle(
                color: TenantAdminColors.bodyText,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            Text('*', style: TextStyle(color: TenantAdminColors.danger)),
          ],
        ),
        const SizedBox(height: TenantAdminSpacing.sm),
        Container(
          height: 48,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(TenantAdminRadius.md),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildStatusOption(
                  label: 'Active',
                  value: 'ACTIVE',
                  icon: Icons.check_circle_outline,
                  isSelected: status == 'ACTIVE',
                  onTap: () => onStatusChanged('ACTIVE'),
                ),
              ),
              Expanded(
                child: _buildStatusOption(
                  label: 'Inactive',
                  value: 'INACTIVE',
                  icon: Icons.highlight_off,
                  isSelected: status == 'INACTIVE',
                  onTap: () => onStatusChanged('INACTIVE'),
                ),
              ),
            ],
          ),
        ),
        if (errors['status'] != null) ...[
          const SizedBox(height: TenantAdminSpacing.xs),
          Text(
            errors['status']!,
            style: const TextStyle(color: TenantAdminColors.danger),
          ),
        ],
      ],
    );
  }

  Widget _buildStatusOption({
    required String label,
    required String value,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? (value == 'ACTIVE' ? Colors.green[600] : Colors.grey[700])
                  : TenantAdminColors.mutedText,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? TenantAdminColors.bodyText : TenantAdminColors.mutedText,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OutletLocationContactStep extends StatelessWidget {
  const _OutletLocationContactStep({
    required this.addressLine1,
    required this.addressLine2,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.countryCode,
    required this.contactName,
    required this.contactPhone,
    required this.contactEmail,
    required this.countries,
    required this.errors,
    required this.imageState,
    required this.onChooseImage,
    required this.onReplaceImage,
    required this.onRemoveImage,
    required this.onRetryImageUpload,
  });

  final TextEditingController addressLine1;
  final TextEditingController addressLine2;
  final TextEditingController city;
  final TextEditingController state;
  final TextEditingController postalCode;
  final TextEditingController countryCode;
  final TextEditingController contactName;
  final TextEditingController contactPhone;
  final TextEditingController contactEmail;
  final List<OutletCountryOption> countries;
  final Map<String, String> errors;
  final OutletImageUploadState imageState;
  final VoidCallback onChooseImage;
  final VoidCallback onReplaceImage;
  final VoidCallback onRemoveImage;
  final VoidCallback onRetryImageUpload;

  @override
  Widget build(BuildContext context) {
    final form = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _twoColumnRow(
          _field('addressLine1', 'Address Line 1', addressLine1,
              errors: errors,
              isRequired: true,
              maxLength: 250,
              icon: Icons.location_on_outlined),
          _field('addressLine2', 'Address Line 2 (optional)', addressLine2,
              errors: errors, maxLength: 250, icon: Icons.apartment_outlined),
        ),
        const SizedBox(height: TenantAdminSpacing.lg),
        _twoColumnRow(
          _field('city', 'City', city,
              errors: errors,
              isRequired: true,
              maxLength: 120,
              icon: Icons.location_city_outlined),
          _field('state', 'Province / State (optional)', state,
              errors: errors, maxLength: 120, icon: Icons.map_outlined),
        ),
        const SizedBox(height: TenantAdminSpacing.lg),
        _twoColumnRow(
          _field('postalCode', 'Postal Code (optional)', postalCode,
              errors: errors,
              maxLength: 30,
              icon: Icons.local_post_office_outlined),
          _countryCodeInput(),
        ),
        const SizedBox(height: TenantAdminSpacing.lg),
        _twoColumnRow(
          _field('contactName', 'Contact Person (optional)', contactName,
              errors: errors, maxLength: 150, icon: Icons.person_outline),
          _field('contactPhone', 'Phone Number (optional)', contactPhone,
              errors: errors,
              maxLength: 40,
              keyboardType: TextInputType.phone,
              icon: Icons.phone_outlined,
              validator: _phoneValidator),
        ),
        const SizedBox(height: TenantAdminSpacing.lg),
        _twoColumnRow(
          _field('contactEmail', 'Email Address (optional)', contactEmail,
              errors: errors,
              maxLength: 255,
              keyboardType: TextInputType.emailAddress,
              icon: Icons.mail_outline,
              validator: _emailValidator),
          const SizedBox.shrink(),
        ),
      ],
    );

    final image = OutletImageUploadCard(
      state: imageState,
      onChoose: onChooseImage,
      onReplace: onReplaceImage,
      onRemove: onRemoveImage,
      onRetry: onRetryImageUpload,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        image,
        const SizedBox(height: TenantAdminSpacing.xl),
        form,
      ],
    );
  }

  Widget _countryCodeInput() {
    if (countries.isEmpty) {
      return _field(
        'country',
        'Country or Region',
        countryCode,
        errors: errors,
        isRequired: true,
        maxLength: 2,
        icon: Icons.public_outlined,
        validator: (value) => _countryCodeValidator(value, const []),
      );
    }

    final current = countryCode.text.trim().toUpperCase();
    final countryCodes = countries.map((country) => country.code).toList();
    final value = countryCodes.contains(current) ? current : null;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Row(
        children: [
          Text(
            'Country or Region ',
            style: TextStyle(
              color: TenantAdminColors.bodyText,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          Text('*', style: TextStyle(color: TenantAdminColors.danger)),
        ],
      ),
      const SizedBox(height: TenantAdminSpacing.sm),
      DropdownButtonFormField<String>(
        isExpanded: true,
        initialValue: value,
        icon: const Icon(Icons.keyboard_arrow_down,
            color: TenantAdminColors.mutedText),
        decoration: InputDecoration(
          hintText: 'Select country or region',
          hintStyle: const TextStyle(
              color: TenantAdminColors.mutedText,
              fontWeight: FontWeight.normal),
          errorText: errors['country'],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(TenantAdminRadius.md),
            borderSide: const BorderSide(color: TenantAdminColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(TenantAdminRadius.md),
            borderSide: const BorderSide(color: TenantAdminColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(TenantAdminRadius.md),
            borderSide: const BorderSide(color: TenantAdminColors.primary),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: TenantAdminSpacing.lg,
            vertical: TenantAdminSpacing.md,
          ),
        ),
        items: [
          for (final country in countries)
            DropdownMenuItem(
              value: country.code,
              child: Text(country.label),
            ),
        ],
        validator: (value) => value == null || value.trim().isEmpty
            ? 'Select a country or region.'
            : _countryCodeValidator(value, countryCodes),
        onChanged: (value) {
          countryCode.text = value ?? '';
        },
      )
    ]);
  }
}

class _OutletReviewStep extends ConsumerWidget {
  const _OutletReviewStep({
    required this.form,
    required this.onEdit,
  });

  final OutletFormData form;
  final ValueChanged<int> onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {


    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(builder: (context, gridConstraints) {
          final isGridWide = gridConstraints.maxWidth >= 700;
          return Wrap(
            spacing: TenantAdminSpacing.lg,
            runSpacing: TenantAdminSpacing.lg,
            children: [
              SizedBox(
                width: isGridWide
                    ? (gridConstraints.maxWidth - TenantAdminSpacing.lg) / 2
                    : gridConstraints.maxWidth,
                child: _buildDetailsCard(),
              ),
              SizedBox(
                width: isGridWide
                    ? (gridConstraints.maxWidth - TenantAdminSpacing.lg) / 2
                    : gridConstraints.maxWidth,
                child: _buildLocationContactCard(),
              ),
              SizedBox(
                width: isGridWide
                    ? (gridConstraints.maxWidth - TenantAdminSpacing.lg) / 2
                    : gridConstraints.maxWidth,
                child: _buildBusinessHoursCard(),
              ),

            ],
          );
        }),
      ],
    );
  }

  Widget _buildCard(
      {required String title, required int step, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: const Color(0xFFE2E8F0).withValues(alpha: 0.5),
            blurRadius: 2,
            offset: const Offset(0, 0),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: Color(0xFF0F172A),
                  ),
                ),
                InkWell(
                  onTap: () => onEdit(step),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: TenantAdminColors.posHomeOrangeEnd.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        const Icon(
                          Icons.edit_outlined,
                          size: 14,
                          color: TenantAdminColors.posHomeOrangeEnd,
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Edit',
                          style: TextStyle(
                            color: TenantAdminColors.posHomeOrangeEnd,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
          Padding(
            padding: const EdgeInsets.all(20),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard() {
    Widget row(String label, String value,
        {bool isBadge = false, bool badgeSuccess = true}) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label.toUpperCase(),
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF94A3B8),
                    letterSpacing: 0.8)),
            const SizedBox(height: 8),
            isBadge
                ? Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                        color: badgeSuccess
                            ? const Color(0xFFF0FDF4)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: badgeSuccess
                                ? const Color(0xFFBBF7D0)
                                : const Color(0xFFE2E8F0))),
                    child: Text(value,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: badgeSuccess
                                ? const Color(0xFF16A34A)
                                : const Color(0xFF64748B))),
                  )
                : Text(value,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B))),
          ],
        ),
      );
    }

    return _buildCard(
      title: 'Outlet Details',
      step: 0,
      child: Wrap(
        spacing: 24,
        runSpacing: 4,
        children: [
          SizedBox(
              width: 160,
              child: row('Outlet Name',
                  form.outletName.isNotEmpty ? form.outletName : '-')),
          SizedBox(
              width: 160, child: row('Outlet Code', 'Generated automatically')),
          SizedBox(
              width: 160,
              child: row('Outlet Type', _displayOutletType(form.outletType))),
          SizedBox(
              width: 160,
              child: row('Status', _displayStatus(form.status),
                  isBadge: true, badgeSuccess: form.status == 'ACTIVE')),
          SizedBox(
              width: 160, child: row('Manager', form.contactName ?? '-')),
          SizedBox(
              width: 160,
              child: row('Phone',
                  form.mainPhoneNumber.isNotEmpty ? form.mainPhoneNumber : '-')),
          SizedBox(
              width: 160,
              child: row('Email',
                  form.emailAddress.isNotEmpty ? form.emailAddress : '-')),
          SizedBox(
              width: 160,
              child: row('Timezone',
                  form.timezone.isNotEmpty ? form.timezone : '-')),
          SizedBox(
              width: 160,
              child: row('Main Outlet', 'No',
                  isBadge: true, badgeSuccess: false)),
          SizedBox(
              width: 160,
              child: row('Default for Tills',
                  form.isDefaultOutlet ? 'Yes' : 'No',
                  isBadge: true, badgeSuccess: form.isDefaultOutlet)),
        ],
      ),
    );
  }

  Widget _buildLocationContactCard() {
    final address = [
      if (form.addressLine1.isNotEmpty) form.addressLine1,
      if (form.addressLine2 != null && form.addressLine2!.isNotEmpty)
        form.addressLine2,
      [
        if (form.city.isNotEmpty) form.city,
        if (form.state != null && form.state!.isNotEmpty) form.state,
        if (form.postalCode.isNotEmpty) form.postalCode
      ].where((e) => e != null && e.isNotEmpty).join(', '),
      if (form.country.isNotEmpty) form.country,
    ];

    Widget section(String label, String value) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label.toUpperCase(),
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF94A3B8),
                    letterSpacing: 0.8)),
            const SizedBox(height: 8),
            Text(value,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                    color: Color(0xFF1E293B))),
          ],
        ),
      );
    }

    return _buildCard(
      title: 'Location & Contact',
      step: 1,
      child: Wrap(
        spacing: 24,
        runSpacing: 4,
        children: [
          SizedBox(
              width: 160,
              child: section('Address',
                  address.isEmpty ? '-' : address.join('\n'))),
          SizedBox(
              width: 160,
              child: section('Contact Person',
                  form.contactName?.isNotEmpty == true ? form.contactName! : '-')),
          SizedBox(
              width: 160,
              child: section('Phone Number',
                  form.contactPhone?.isNotEmpty == true ? form.contactPhone! : '-')),
          SizedBox(
              width: 160,
              child: section('Email Address',
                  form.contactEmail?.isNotEmpty == true ? form.contactEmail! : '-')),
        ],
      ),
    );
  }

  Widget _buildBusinessHoursCard() {
    Widget hourRow(OutletOpeningHour hour) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(hour.day.toUpperCase(),
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF94A3B8),
                    letterSpacing: 0.8)),
            const SizedBox(height: 8),
            Text(
              hour.closed ? 'Closed' : '${hour.openTime} - ${hour.closeTime}',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: hour.closed ? const Color(0xFFEF4444) : const Color(0xFF1E293B)),
            ),
          ],
        ),
      );
    }

    Widget specialDayRow(String day, String hours) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(day.toUpperCase(),
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF94A3B8),
                    letterSpacing: 0.8)),
            const SizedBox(height: 8),
            Text(hours,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B))),
          ],
        ),
      );
    }

    return _buildCard(
      title: 'Business Hours',
      step: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC), // Slate 50
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.language, size: 16, color: Color(0xFF64748B)),
                const SizedBox(width: 8),
                Text(
                  'Timezone: ${form.timezone.isNotEmpty ? form.timezone : '-'}',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF475569)), // Slate 600
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('Regular Hours',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B))),
          const SizedBox(height: 16),
          Wrap(
            spacing: 24,
            runSpacing: 4,
            children: form.openingHours.map((hour) => SizedBox(width: 140, child: hourRow(hour))).toList(),
          ),
          const SizedBox(height: 24),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 24),
          const Text('Special Days / Holiday Hours',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B))),
          const SizedBox(height: 16),
          Wrap(
            spacing: 24,
            runSpacing: 4,
            children: [
              SizedBox(
                  width: 180,
                  child: specialDayRow('Christmas Day (Dec 25)', '09:00 AM - 06:00 PM')),
              SizedBox(
                  width: 180,
                  child: specialDayRow("New Year's Day (Jan 01)", '10:00 AM - 08:00 PM')),
            ],
          ),
        ],
      ),
    );
  }


}

class _OutletWizardActions extends StatelessWidget {
  const _OutletWizardActions({
    required this.step,
    required this.lastStep,
    required this.submitting,
    required this.onBack,
    required this.onNext,
    required this.onCancel,
  });

  final int step;
  final int lastStep;
  final bool submitting;
  final VoidCallback? onBack;
  final VoidCallback onNext;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < TenantAdminBreakpoints.mobile;
        final back = onBack == null
            ? const SizedBox.shrink()
            : TenantAdminSecondaryButton(
                label: 'Back',
                icon: Icons.arrow_back,
                onPressed: submitting ? null : onBack,
              );
        final next = TenantAdminPrimaryButton(
          label: step == lastStep ? 'Create Outlet' : 'Next',
          icon: step == lastStep ? Icons.check : Icons.arrow_forward,
          loading: submitting,
          onPressed: submitting ? null : onNext,
        );
        if (narrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              next,
              const SizedBox(height: TenantAdminSpacing.sm),
              TenantAdminSecondaryButton(
                  label: 'Cancel',
                  icon: Icons.close,
                  onPressed: submitting ? null : onCancel),
              if (onBack != null) ...[
                const SizedBox(height: TenantAdminSpacing.sm),
                back,
              ],
            ],
          );
        }

        return Row(
          children: [
            if (onBack != null) back,
            const SizedBox(width: TenantAdminSpacing.sm),
            TenantAdminSecondaryButton(
                label: 'Cancel',
                icon: Icons.close,
                onPressed: submitting ? null : onCancel),
            const Spacer(),
            next,
          ],
        );
      },
    );
  }
}

Widget _field(
  String key,
  String label,
  TextEditingController controller, {
  required Map<String, String> errors,
  bool isRequired = false,
  int? maxLength,
  TextInputType? keyboardType,
  String? Function(String? value)? validator,
  IconData? icon,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
            child: Text.rich(
              TextSpan(
                text: label,
                style: const TextStyle(
                  color: TenantAdminColors.bodyText,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
                children: [
                  if (isRequired)
                    const TextSpan(
                      text: ' *',
                      style: TextStyle(color: TenantAdminColors.danger),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: TenantAdminSpacing.sm),
      Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.01),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLength: maxLength,
          style: const TextStyle(
            color: TenantAdminColors.bodyText,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: 'Enter ${label.toLowerCase().replaceAll(RegExp(r'\(optional\)'), '').trim()}',
            hintStyle: const TextStyle(
                color: TenantAdminColors.mutedText,
                fontWeight: FontWeight.normal),
            errorText: errors[key],
            counterText: '',
            filled: true,
            fillColor: Colors.white,
            prefixIcon: icon != null 
                ? Icon(icon, size: 20, color: const Color(0xFF94A3B8))
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TenantAdminRadius.md),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TenantAdminRadius.md),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TenantAdminRadius.md),
              borderSide: const BorderSide(color: TenantAdminColors.posHomeOrangeEnd, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TenantAdminRadius.md),
              borderSide: const BorderSide(color: TenantAdminColors.danger),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: TenantAdminSpacing.lg,
              vertical: TenantAdminSpacing.md,
            ),
          ),
          validator: (value) {
            final trimmed = value?.trim() ?? '';
            if (isRequired && trimmed.isEmpty) {
              return '$label is required.';
            }
            if (maxLength != null && trimmed.length > maxLength) {
              return '$label must be $maxLength characters or less.';
            }
            return validator?.call(value);
          },
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

List<BusinessHoursDraft> _initialOpeningHours(List<OutletOpeningHour>? values) {
  const days = [
    ('Sunday', 0),
    ('Monday', 1),
    ('Tuesday', 2),
    ('Wednesday', 3),
    ('Thursday', 4),
    ('Friday', 5),
    ('Saturday', 6),
  ];

  return [
    for (final day in days) _draftForDay(day.$1, day.$2, values),
  ];
}

BusinessHoursDraft _draftForDay(
  String label,
  int dayOfWeek,
  List<OutletOpeningHour>? values,
) {
  OutletOpeningHour? existing;
  for (final value in values ?? const <OutletOpeningHour>[]) {
    if (value.day == label) {
      existing = value;
      break;
    }
  }

  return BusinessHoursDraft(
    dayLabel: label,
    dayOfWeek: dayOfWeek,
    openTime: TextEditingController(text: existing?.openTime ?? '09:00'),
    closeTime: TextEditingController(text: existing?.closeTime ?? '17:00'),
    closed: existing?.closed ?? false,
  );
}

String _normalizeOutletType(String value) {
  return value.trim().toUpperCase();
}

String _normalizeCanonicalOutletType(String value) =>
    value.trim().toUpperCase();

String _normalizeStatus(String value) {
  final normalized = value.trim().toUpperCase();
  return normalized == 'INACTIVE' ? 'INACTIVE' : 'ACTIVE';
}

String _displayOutletType(String value) {
  final normalized = _normalizeOutletType(value);
  if (normalized == 'STORE') {
    return 'Store';
  }
  if (normalized == 'WAREHOUSE') {
    return 'Warehouse';
  }

  return value.trim();
}

String _displayStatus(String value) {
  return _normalizeStatus(value) == 'INACTIVE' ? 'Inactive' : 'Active';
}

String _resolveOptionValue(
  String? value,
  List<OutletSelectOption>? options, {
  String Function(String value)? normalize,
}) {
  final normalizedValue = normalize?.call(value ?? '') ?? (value ?? '').trim();
  if (normalizedValue.isEmpty) {
    return '';
  }

  for (final option in options ?? const <OutletSelectOption>[]) {
    final optionValue = normalize?.call(option.value) ?? option.value.trim();
    if (optionValue == normalizedValue) {
      return option.value;
    }
  }

  if (options != null && options.isNotEmpty) {
    return '';
  }

  return normalizedValue;
}

String? _firstOptionValue(List<OutletSelectOption>? options) {
  if (options == null || options.isEmpty) {
    return null;
  }

  return options.first.value;
}

String? _matchingOptionValue(
  String value,
  List<OutletSelectOption> options, {
  String Function(String value)? normalize,
}) {
  final normalizedValue = normalize?.call(value) ?? value.trim();
  for (final option in options) {
    final optionValue = normalize?.call(option.value) ?? option.value.trim();
    if (optionValue == normalizedValue) {
      return option.value;
    }
  }

  return null;
}

String? _outletTypeValidator(
  String? value,
  List<OutletSelectOption> options,
) {
  final normalized = _normalizeCanonicalOutletType(value ?? '');
  if (normalized.isEmpty) {
    return 'Outlet type is required.';
  }

  final supportedValues = options
      .map((option) => _normalizeCanonicalOutletType(option.value))
      .toSet();
  if (supportedValues.isNotEmpty && !supportedValues.contains(normalized)) {
    return 'Select a valid outlet type.';
  }

  return null;
}

String? _timezoneValidator(
  String? value,
  List<OutletSelectOption> options,
) {
  final normalized = value?.trim() ?? '';
  if (normalized.isEmpty) {
    return 'Timezone is required.';
  }

  final supportedValues = options.map((option) => option.value.trim()).toSet();
  if (supportedValues.isNotEmpty && !supportedValues.contains(normalized)) {
    return 'Select a valid timezone.';
  }

  return null;
}

String? _nullable(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

String? _emailValidator(String? value) {
  final email = value?.trim() ?? '';
  if (email.isEmpty) {
    return null;
  }
  final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  if (!emailPattern.hasMatch(email)) {
    return 'Enter a valid email address.';
  }
  return null;
}

String? _phoneValidator(String? value) {
  final phone = value?.trim() ?? '';
  if (phone.isEmpty) {
    return null;
  }
  final valid = RegExp(r'^[0-9+()\-\s]{6,40}$').hasMatch(phone);
  return valid ? null : 'Enter a valid phone number.';
}

String? _countryCodeValidator(String? value, List<String> supportedCountries) {
  final country = value?.trim() ?? '';
  if (country.isEmpty) {
    return 'Country code is required.';
  }
  if (!RegExp(r'^[A-Za-z]{2}$').hasMatch(country)) {
    return 'Country code must be 2 letters.';
  }
  if (supportedCountries.isNotEmpty &&
      !supportedCountries.contains(country.toUpperCase())) {
    return 'Country code must be one of ${supportedCountries.join(', ')}.';
  }
  return null;
}

int? _minutes(String value) {
  final parts = value.trim().split(':');
  if (parts.length < 2) {
    return null;
  }
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null ||
      minute == null ||
      hour < 0 ||
      hour > 23 ||
      minute < 0 ||
      minute > 59) {
    return null;
  }
  return hour * 60 + minute;
}
