import 'package:flutter/material.dart';

import '../../domain/entities/outlet.dart';
import '../../domain/entities/outlet_details.dart';
import '../config/outlet_timezone_options.dart';
import '../utils/outlet_api_errors.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_buttons.dart';
import '../../../presentation/widgets/tenant_admin_form_section.dart';
import '../../../presentation/widgets/tenant_admin_stepper_header.dart';

class OutletForm extends StatefulWidget {
  const OutletForm({
    super.key,
    required this.managers,
    required this.onSubmit,
    this.initialValue,
    this.backendErrors = const {},
    this.submitting = false,
  });

  final List<OutletManagerOption> managers;
  final OutletFormData? initialValue;
  final Map<String, String> backendErrors;
  final bool submitting;
  final Future<void> Function(OutletFormData form) onSubmit;

  @override
  State<OutletForm> createState() => _OutletFormState();
}

class _OutletFormState extends State<OutletForm> {
  final _formKey = GlobalKey<FormState>();
  var _step = 0;

  late final TextEditingController _outletName;
  late final TextEditingController _outletCode;
  late final TextEditingController _outletType;
  var _status = 'Active';
  late final TextEditingController _mainPhoneNumber;
  late final TextEditingController _emailAddress;
  late final TextEditingController _addressLine1;
  late final TextEditingController _addressLine2;
  late final TextEditingController _city;
  late final TextEditingController _state;
  late final TextEditingController _country;
  late final TextEditingController _postalCode;
  late List<_OpeningHourDraft> _openingHours;
  String? _managerId;
  late String _timezone;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialValue;
    _outletName = TextEditingController(text: initial?.outletName ?? '');
    _outletCode = TextEditingController(text: initial?.outletCode ?? '');
    _outletType = TextEditingController(text: initial?.outletType ?? 'Retail');
    _status = initial?.status ?? 'Active';
    _mainPhoneNumber =
        TextEditingController(text: initial?.mainPhoneNumber ?? '');
    _emailAddress = TextEditingController(text: initial?.emailAddress ?? '');
    _addressLine1 = TextEditingController(text: initial?.addressLine1 ?? '');
    _addressLine2 = TextEditingController(text: initial?.addressLine2 ?? '');
    _city = TextEditingController(text: initial?.city ?? '');
    _state = TextEditingController(text: initial?.state ?? '');
    _country = TextEditingController(text: initial?.country ?? 'LK');
    _postalCode = TextEditingController(text: initial?.postalCode ?? '');
    _managerId = initial?.managerId;
    _timezone = _resolveTimezone(initial?.timezone);
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
    _outletCode.dispose();
    _outletType.dispose();
    _mainPhoneNumber.dispose();
    _emailAddress.dispose();
    _addressLine1.dispose();
    _addressLine2.dispose();
    _city.dispose();
    _state.dispose();
    _country.dispose();
    _postalCode.dispose();
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TenantAdminStepperHeader(
            steps: const [
              'Outlet Details',
              'Location & Contact',
              'Review & Create',
            ],
            currentStep: _step,
          ),
          const SizedBox(height: TenantAdminSpacing.xl),
          _buildStep(),
          const SizedBox(height: TenantAdminSpacing.xl),
          Row(
            children: [
              if (_step > 0)
                TenantAdminSecondaryButton(
                  label: 'Back',
                  icon: Icons.arrow_back,
                  onPressed: widget.submitting
                      ? null
                      : () => setState(() => _step -= 1),
                ),
              const Spacer(),
              TenantAdminSecondaryButton(
                label: 'Save draft',
                icon: Icons.save,
                onPressed: widget.submitting ? null : () {},
              ),
              const SizedBox(width: TenantAdminSpacing.md),
              TenantAdminPrimaryButton(
                label: _step == 2 ? 'Create Outlet' : 'Next',
                icon: _step == 2 ? Icons.check : Icons.arrow_forward,
                loading: widget.submitting,
                onPressed: widget.submitting ? null : _continue,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return TenantAdminFormSection(
          title: 'Outlet Details',
          subtitle: 'Provide basic information about the outlet.',
          children: [
            _twoColumnRow(
              _field('outletName', 'Outlet Name', _outletName,
                  isRequired: true, icon: Icons.storefront_outlined),
              _field('outletCode', 'Outlet Code', _outletCode,
                  hintText: 'Optional — backend auto-generates OUT-001',
                  icon: Icons.tag),
            ),
            _twoColumnRow(_outletTypeDropdown(), _statusSelector()),
            DropdownButtonFormField<String>(
              initialValue:
                  widget.managers.any((manager) => manager.id == _managerId)
                      ? _managerId
                      : null,
              decoration: InputDecoration(
                labelText: 'Manager',
                errorText: widget.backendErrors['managerId'],
              ),
              items: [
                for (final manager in widget.managers)
                  DropdownMenuItem<String>(
                    value: manager.id,
                    child: Text(manager.displayName),
                  ),
              ],
              onChanged: widget.managers.isEmpty
                  ? null
                  : (value) => setState(() => _managerId = value),
              hint: Text(
                widget.managers.isEmpty
                    ? 'No managers available'
                    : 'Select manager',
              ),
            ),
          ],
        );
      case 1:
        return TenantAdminFormSection(
          title: 'Location & Contact',
          subtitle:
              'Provide the location and contact information for the outlet.',
          children: [
            _twoColumnRow(
              _field('addressLine1', 'Address Line 1', _addressLine1,
                  isRequired: true, icon: Icons.location_city_outlined),
              _field('addressLine2', 'Address Line 2 (optional)', _addressLine2,
                  icon: Icons.apartment_outlined),
            ),
            _twoColumnRow(
              _field('city', 'City', _city,
                  isRequired: true, icon: Icons.place_outlined),
              _field('state', 'District / Province', _state,
                  icon: Icons.map_outlined),
            ),
            _twoColumnRow(
              _field('postalCode', 'Postal Code', _postalCode,
                  isRequired: true, icon: Icons.local_post_office_outlined),
              _field('mainPhoneNumber', 'Phone Number', _mainPhoneNumber,
                  isRequired: true,
                  keyboardType: TextInputType.phone,
                  icon: Icons.phone_outlined),
            ),
            _field(
              'emailAddress',
              'Email Address',
              _emailAddress,
              isRequired: true,
              keyboardType: TextInputType.emailAddress,
              validator: _emailValidator,
              icon: Icons.mail_outline,
            ),
            _timezoneDropdown(),
          ],
        );
      default:
        return TenantAdminFormSection(
          title: 'Review & Confirm',
          subtitle:
              'Please review the details below before creating the outlet.',
          children: [
            _reviewGroup(
              title: 'Outlet Details',
              icon: Icons.storefront_outlined,
              children: [
                _reviewLine('Outlet Name', _outletName.text),
                _reviewLine('Outlet Code', _outletCode.text),
                _reviewLine('Outlet Type', _outletType.text),
                _reviewLine('Status', _status),
              ],
            ),
            _reviewGroup(
              title: 'Location & Contact',
              icon: Icons.location_on_outlined,
              children: [
                _reviewLine('Address', _addressLine1.text),
                _reviewLine('City', _city.text),
                _reviewLine('District / Province', _state.text),
                _reviewLine('Postal Code', _postalCode.text),
                _reviewLine('Timezone', _timezone),
                _reviewLine('Phone', _mainPhoneNumber.text),
                _reviewLine('Email', _emailAddress.text),
              ],
            ),
          ],
        );
    }
  }

  Widget _field(
    String key,
    String label,
    TextEditingController controller, {
    bool isRequired = false,
    TextInputType? keyboardType,
    String? Function(String? value)? validator,
    IconData? icon,
    String? hintText,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: icon == null ? null : Icon(icon, size: 18),
        errorText: widget.backendErrors[key],
      ),
      validator: (value) {
        if (isRequired && (value == null || value.trim().isEmpty)) {
          return '$label is required';
        }

        return validator?.call(value);
      },
    );
  }

  Widget _outletTypeDropdown() {
    final currentValue =
        const ['Retail', 'Warehouse'].contains(_outletType.text)
            ? _outletType.text
            : 'Retail';

    return DropdownButtonFormField<String>(
      initialValue: currentValue,
      decoration: InputDecoration(
        labelText: 'Outlet Type',
        prefixIcon: const Icon(Icons.sell_outlined, size: 18),
        errorText: widget.backendErrors['outletType'],
      ),
      items: const [
        DropdownMenuItem(value: 'Retail', child: Text('Retail')),
        DropdownMenuItem(value: 'Warehouse', child: Text('Warehouse')),
      ],
      onChanged: (value) {
        if (value == null) {
          return;
        }
        setState(() => _outletType.text = value);
      },
    );
  }

  Widget _timezoneDropdown() {
    final currentValue = outletTimezoneOptions.contains(_timezone)
        ? _timezone
        : defaultOutletTimezone;

    return DropdownButtonFormField<String>(
      initialValue: currentValue,
      decoration: InputDecoration(
        labelText: 'Timezone',
        prefixIcon: const Icon(Icons.schedule_outlined, size: 18),
        errorText: widget.backendErrors['timezone'],
      ),
      items: [
        for (final option in outletTimezoneOptions)
          DropdownMenuItem<String>(
            value: option,
            child: Text(option),
          ),
      ],
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Timezone is required';
        }

        return null;
      },
      onChanged: (value) {
        if (value == null) {
          return;
        }

        setState(() => _timezone = value);
      },
    );
  }

  Widget _statusSelector() {
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
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: TenantAdminColors.border),
            borderRadius: BorderRadius.circular(TenantAdminRadius.md),
          ),
          child: Row(
            children: [
              Expanded(child: _statusOption('Active')),
              Expanded(child: _statusOption('Inactive')),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statusOption(String value) {
    final selected = _status == value;
    return InkWell(
      onTap: () => setState(() => _status = value),
      borderRadius: BorderRadius.circular(TenantAdminRadius.md),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: TenantAdminSpacing.md),
        decoration: BoxDecoration(
          color: selected
              ? TenantAdminColors.success.withValues(alpha: 0.10)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.circle,
              size: 8,
              color: selected
                  ? TenantAdminColors.success
                  : TenantAdminColors.mutedText,
            ),
            const SizedBox(width: TenantAdminSpacing.sm),
            Text(
              value,
              style: TextStyle(
                color: selected
                    ? TenantAdminColors.success
                    : TenantAdminColors.mutedText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _emailValidator(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return null;
    }

    final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailPattern.hasMatch(email)) {
      return 'Enter a valid email address';
    }

    return null;
  }

  Widget _reviewLine(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 160,
          child:
              Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
        Expanded(child: Text(value.isEmpty ? '-' : value)),
      ],
    );
  }

  Widget _reviewGroup({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(TenantAdminSpacing.lg),
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        border: Border.all(color: TenantAdminColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: TenantAdminColors.primary),
              const SizedBox(width: TenantAdminSpacing.sm),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: TenantAdminSpacing.md),
          ...children,
        ],
      ),
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

  Future<void> _continue() async {
    if (_step < 2) {
      if (!_formKey.currentState!.validate()) {
        return;
      }

      setState(() => _step += 1);
      return;
    }

    final validationError = _submitValidationError();
    if (validationError != null) {
      final fieldKey = validationError.$1;
      final message = validationError.$2;
      final errorStep = outletErrorStep({fieldKey: message});
      if (errorStep != null) {
        setState(() => _step = errorStep);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _formKey.currentState?.validate();
        });
      }
      return;
    }

    await widget.onSubmit(_formData());
  }

  (String, String)? _submitValidationError() {
    final checks = <(String, String, String? Function(String? value)?)>[
      ('outletName', 'Outlet name', _requiredValidator('Outlet name')),
      ('outletType', 'Outlet type', _requiredValidator('Outlet type')),
      (
        'mainPhoneNumber',
        'Main phone number',
        _requiredValidator('Main phone number')
      ),
      ('emailAddress', 'Email address', _emailValidator),
      ('addressLine1', 'Address line 1', _requiredValidator('Address line 1')),
      ('city', 'City', _requiredValidator('City')),
      ('postalCode', 'Postal code', _requiredValidator('Postal code')),
      ('timezone', 'Timezone', _requiredValidator('Timezone')),
    ];

    for (final check in checks) {
      final value = switch (check.$1) {
        'outletName' => _outletName.text,
        'outletCode' => _outletCode.text,
        'outletType' => _outletType.text,
        'mainPhoneNumber' => _mainPhoneNumber.text,
        'emailAddress' => _emailAddress.text,
        'addressLine1' => _addressLine1.text,
        'city' => _city.text,
        'postalCode' => _postalCode.text,
        'timezone' => _timezone,
        _ => '',
      };

      final message = check.$3?.call(value);
      if (message != null) {
        return (check.$1, message);
      }
    }

    return null;
  }

  String? Function(String? value) _requiredValidator(String label) {
    return (value) {
      if (value == null || value.trim().isEmpty) {
        return '$label is required';
      }

      return null;
    };
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

  OutletFormData _formData() {
    return OutletFormData(
      outletName: _outletName.text.trim(),
      outletCode: _outletCode.text.trim(),
      outletType: _outletType.text.trim(),
      status: _status,
      mainPhoneNumber: _mainPhoneNumber.text.trim(),
      emailAddress: _emailAddress.text.trim(),
      managerId: _managerId,
      addressLine1: _addressLine1.text.trim(),
      addressLine2: _addressLine2.text.trim(),
      city: _city.text.trim(),
      state: _state.text.trim(),
      country: _country.text.trim().isEmpty ? 'LK' : _country.text.trim(),
      postalCode: _postalCode.text.trim(),
      timezone: _timezone.trim().isEmpty ? defaultOutletTimezone : _timezone.trim(),
      openingHours: [
        for (final hour in _openingHours)
          OutletOpeningHour(
            day: hour.day,
            openTime: hour.openTime.text.trim(),
            closeTime: hour.closeTime.text.trim(),
            closed: hour.closed,
          ),
      ],
    );
  }
}

String _resolveTimezone(String? timezone) {
  final value = timezone?.trim() ?? '';
  if (value.isEmpty) {
    return defaultOutletTimezone;
  }

  return outletTimezoneOptions.contains(value) ? value : defaultOutletTimezone;
}

List<_OpeningHourDraft> _initialOpeningHours(List<OutletOpeningHour>? values) {
  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  return [
    for (final day in days)
      _OpeningHourDraft(
        day: day,
        openTime: TextEditingController(
          text: values
                  ?.firstWhere(
                    (value) => value.day == day,
                    orElse: () => const OutletOpeningHour(
                      day: '',
                      openTime: '08:00',
                      closeTime: '20:00',
                      closed: false,
                    ),
                  )
                  .openTime ??
              '08:00',
        ),
        closeTime: TextEditingController(
          text: values
                  ?.firstWhere(
                    (value) => value.day == day,
                    orElse: () => const OutletOpeningHour(
                      day: '',
                      openTime: '08:00',
                      closeTime: '20:00',
                      closed: false,
                    ),
                  )
                  .closeTime ??
              '20:00',
        ),
        closed: values
                ?.firstWhere(
                  (value) => value.day == day,
                  orElse: () => const OutletOpeningHour(
                    day: '',
                    openTime: '08:00',
                    closeTime: '20:00',
                    closed: false,
                  ),
                )
                .closed ??
            false,
      ),
  ];
}

class _OpeningHourDraft {
  _OpeningHourDraft({
    required this.day,
    required this.openTime,
    required this.closeTime,
    required this.closed,
  });

  final String day;
  final TextEditingController openTime;
  final TextEditingController closeTime;
  bool closed;
}
