import 'package:flutter/material.dart';

import '../../domain/entities/outlet_create_options.dart';
import '../../domain/entities/outlet_details.dart';
import '../utils/outlet_api_errors.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_buttons.dart';
import '../../../presentation/widgets/tenant_admin_form_section.dart';
import 'business_hours_editor.dart';
import 'outlet_review_section.dart';
import 'outlet_wizard_stepper.dart';

class OutletForm extends StatefulWidget {
  const OutletForm({
    super.key,
    required this.onSubmit,
    this.initialValue,
    this.createOptions,
    this.backendErrors = const {},
    this.submitting = false,
  });

  final OutletFormData? initialValue;
  final OutletCreateOptions? createOptions;
  final Map<String, String> backendErrors;
  final bool submitting;
  final Future<void> Function(OutletFormData form) onSubmit;

  @override
  State<OutletForm> createState() => _OutletFormState();
}

class _OutletFormState extends State<OutletForm> {
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
          OutletWizardStepper(
            steps: _steps,
            currentStep: _step,
            onStepSelected: (step) => setState(() => _step = step),
          ),
          const SizedBox(height: TenantAdminSpacing.xl),
          _buildStep(),
          const SizedBox(height: TenantAdminSpacing.xl),
          _OutletWizardActions(
            step: _step,
            lastStep: _steps.length - 1,
            submitting: widget.submitting,
            onBack: _step == 0 ? null : () => setState(() => _step -= 1),
            onNext: _continue,
          ),
        ],
      ),
    );
  }

  Widget _buildStep() {
    return switch (_step) {
      0 => _OutletDetailsStep(
          outletName: _outletName,
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
      1 => _OutletLocationContactStep(
          addressLine1: _addressLine1,
          addressLine2: _addressLine2,
          city: _city,
          state: _state,
          postalCode: _postalCode,
          countryCode: _countryCode,
          mainPhone: _mainPhoneNumber,
          email: _emailAddress,
          contactName: _contactName,
          contactPhone: _contactPhone,
          countries: widget.createOptions?.countries ?? const [],
          errors: widget.backendErrors,
        ),
      2 => TenantAdminFormSection(
          title: 'Business Hours',
          subtitle:
              'Configure Monday through Sunday using the backend day mapping: Sunday is 0, Monday is 1.',
          children: [
            BusinessHoursEditor(
              hours: _openingHours,
              errors: _businessHourErrors,
              onChanged: () => setState(_businessHourErrors.clear),
              onApplyMondayToWeekdays: _applyMondayToWeekdays,
            ),
          ],
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
    return OutletFormData(
      outletName: _outletName.text.trim(),
      outletType: _outletType,
      status: _status,
      mainPhoneNumber: _mainPhoneNumber.text.trim(),
      emailAddress: _emailAddress.text.trim(),
      contactName: _nullable(_contactName.text),
      contactPhone: _nullable(_contactPhone.text),
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
    return TenantAdminFormSection(
      title: 'Outlet Details',
      subtitle:
          'Outlet code is generated by the backend after creation; the current create API does not accept a custom outlet code.',
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
          _outletTypeDropdown(),
        ),
        _twoColumnRow(_statusSelector(context), _timezoneField()),
        Material(
          color: Colors.transparent,
          child: SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Default Outlet'),
            subtitle: const Text(
              'Making this the default outlet may replace the existing default outlet.',
            ),
            value: isDefaultOutlet,
            onChanged: onDefaultChanged,
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

    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: 'Outlet Type',
        prefixIcon: const Icon(Icons.sell_outlined, size: 18),
        errorText: errors['outletType'],
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
    );
  }

  Widget _timezoneField() {
    if (timezones.isNotEmpty) {
      final value = _matchingOptionValue(timezone.text, timezones);
      return DropdownButtonFormField<String>(
        initialValue: value,
        decoration: InputDecoration(
          labelText: 'Timezone',
          prefixIcon: const Icon(Icons.schedule_outlined, size: 18),
          errorText: errors['timezone'],
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
      );
    }

    return TextFormField(
      controller: timezone,
      decoration: InputDecoration(
        labelText: 'Timezone',
        prefixIcon: const Icon(Icons.schedule_outlined, size: 18),
        errorText: errors['timezone'],
        helperText: 'Use an IANA timezone code, for example UTC.',
      ),
      validator: (value) {
        final trimmed = value?.trim() ?? '';
        if (trimmed.isEmpty) {
          return 'Timezone is required.';
        }
        if (trimmed.length > 80) {
          return 'Timezone must be 80 characters or less.';
        }
        return null;
      },
    );
  }

  Widget _statusSelector(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Status',
          style: TenantAdminTextStyles.muted(context).copyWith(
            color: TenantAdminColors.bodyText,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: TenantAdminSpacing.sm),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(
              value: 'ACTIVE',
              label: Text('Active'),
              icon: Icon(Icons.check_circle_outline),
            ),
            ButtonSegment(
              value: 'INACTIVE',
              label: Text('Inactive'),
              icon: Icon(Icons.pause_circle_outline),
            ),
          ],
          selected: {status},
          onSelectionChanged: (value) => onStatusChanged(value.first),
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
}

class _OutletLocationContactStep extends StatelessWidget {
  const _OutletLocationContactStep({
    required this.addressLine1,
    required this.addressLine2,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.countryCode,
    required this.mainPhone,
    required this.email,
    required this.contactName,
    required this.contactPhone,
    required this.countries,
    required this.errors,
  });

  final TextEditingController addressLine1;
  final TextEditingController addressLine2;
  final TextEditingController city;
  final TextEditingController state;
  final TextEditingController postalCode;
  final TextEditingController countryCode;
  final TextEditingController mainPhone;
  final TextEditingController email;
  final TextEditingController contactName;
  final TextEditingController contactPhone;
  final List<OutletCountryOption> countries;
  final Map<String, String> errors;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TenantAdminFormSection(
          title: 'Outlet Address',
          subtitle:
              'Country uses the backend country-code contract. No country reference API exists yet.',
          children: [
            _twoColumnRow(
              _field(
                'addressLine1',
                'Address Line 1',
                addressLine1,
                errors: errors,
                isRequired: true,
                maxLength: 255,
                icon: Icons.location_city_outlined,
              ),
              _field(
                'addressLine2',
                'Address Line 2',
                addressLine2,
                errors: errors,
                maxLength: 255,
                icon: Icons.apartment_outlined,
              ),
            ),
            _twoColumnRow(
              _field(
                'city',
                'City',
                city,
                errors: errors,
                isRequired: true,
                maxLength: 120,
                icon: Icons.place_outlined,
              ),
              _field(
                'state',
                'State / Province',
                state,
                errors: errors,
                maxLength: 120,
                icon: Icons.map_outlined,
              ),
            ),
            _twoColumnRow(
              _field(
                'postalCode',
                'Postal Code',
                postalCode,
                errors: errors,
                maxLength: 30,
                icon: Icons.local_post_office_outlined,
              ),
              _countryCodeInput(),
            ),
          ],
        ),
        const SizedBox(height: TenantAdminSpacing.xl),
        TenantAdminFormSection(
          title: 'Contact Details',
          subtitle:
              'Optional contact fields are omitted from the request when blank.',
          children: [
            _twoColumnRow(
              _field(
                'mainPhoneNumber',
                'Outlet Phone',
                mainPhone,
                errors: errors,
                maxLength: 40,
                keyboardType: TextInputType.phone,
                icon: Icons.phone_outlined,
                validator: _phoneValidator,
              ),
              _field(
                'emailAddress',
                'Outlet Email',
                email,
                errors: errors,
                maxLength: 255,
                keyboardType: TextInputType.emailAddress,
                icon: Icons.mail_outline,
                validator: _emailValidator,
              ),
            ),
            _twoColumnRow(
              _field(
                'contactName',
                'Contact Person',
                contactName,
                errors: errors,
                maxLength: 150,
                icon: Icons.person_outline,
              ),
              _field(
                'contactPhone',
                'Contact Phone',
                contactPhone,
                errors: errors,
                maxLength: 40,
                keyboardType: TextInputType.phone,
                icon: Icons.contact_phone_outlined,
                validator: _phoneValidator,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _countryCodeInput() {
    if (countries.isEmpty) {
      return _field(
        'country',
        'Country Code',
        countryCode,
        errors: errors,
        isRequired: true,
        maxLength: 2,
        icon: Icons.flag_outlined,
        validator: (value) => _countryCodeValidator(value, const []),
      );
    }

    final current = countryCode.text.trim().toUpperCase();
    final countryCodes = countries.map((country) => country.code).toList();
    final value = countryCodes.contains(current) ? current : null;

    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: 'Country Code',
        prefixIcon: const Icon(Icons.flag_outlined, size: 18),
        errorText: errors['country'],
      ),
      items: [
        for (final country in countries)
          DropdownMenuItem(
            value: country.code,
            child: Text(country.label),
          ),
      ],
      validator: (value) => value == null || value.trim().isEmpty
          ? 'Country Code is required.'
          : _countryCodeValidator(value, countryCodes),
      onChanged: (value) {
        countryCode.text = value ?? '';
      },
    );
  }
}

class _OutletReviewStep extends StatelessWidget {
  const _OutletReviewStep({
    required this.form,
    required this.onEdit,
  });

  final OutletFormData form;
  final ValueChanged<int> onEdit;

  @override
  Widget build(BuildContext context) {
    return TenantAdminFormSection(
      title: 'Review & Create',
      subtitle: 'Review the supported fields that will be sent to the backend.',
      children: [
        OutletReviewSection(
          title: 'Outlet Details',
          icon: Icons.storefront_outlined,
          onEdit: () => onEdit(0),
          items: [
            OutletReviewItem('Outlet Name', form.outletName),
            const OutletReviewItem('Outlet Code', 'Generated by backend'),
            OutletReviewItem(
                'Outlet Type', _displayOutletType(form.outletType)),
            OutletReviewItem('Timezone', form.timezone),
            OutletReviewItem(
                'Default Outlet', form.isDefaultOutlet ? 'Yes' : 'No'),
            OutletReviewItem('Status', _displayStatus(form.status)),
          ],
        ),
        OutletReviewSection(
          title: 'Location',
          icon: Icons.location_on_outlined,
          onEdit: () => onEdit(1),
          items: [
            OutletReviewItem('Address Line 1', form.addressLine1),
            OutletReviewItem('Address Line 2', form.addressLine2 ?? ''),
            OutletReviewItem('City', form.city),
            OutletReviewItem('State / Province', form.state ?? ''),
            OutletReviewItem('Postal Code', form.postalCode),
            OutletReviewItem('Country Code', form.country),
          ],
        ),
        OutletReviewSection(
          title: 'Contact',
          icon: Icons.contact_phone_outlined,
          onEdit: () => onEdit(1),
          items: [
            OutletReviewItem('Outlet Phone', form.mainPhoneNumber),
            OutletReviewItem('Outlet Email', form.emailAddress),
            OutletReviewItem('Contact Person', form.contactName ?? ''),
            OutletReviewItem('Contact Phone', form.contactPhone ?? ''),
          ],
        ),
        OutletReviewSection(
          title: 'Business Hours',
          icon: Icons.schedule_outlined,
          onEdit: () => onEdit(2),
          items: [
            for (final hour in form.openingHours)
              OutletReviewItem(
                hour.day,
                hour.closed ? 'Closed' : '${hour.openTime} - ${hour.closeTime}',
              ),
          ],
        ),
      ],
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
  });

  final int step;
  final int lastStep;
  final bool submitting;
  final VoidCallback? onBack;
  final VoidCallback onNext;

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
  return TextFormField(
    controller: controller,
    keyboardType: keyboardType,
    maxLength: maxLength,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: icon == null ? null : Icon(icon, size: 18),
      errorText: errors[key],
      counterText: '',
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
