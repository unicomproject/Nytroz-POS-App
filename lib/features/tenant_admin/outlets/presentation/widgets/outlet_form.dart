import 'package:flutter/material.dart';

import '../../domain/entities/outlet.dart';
import '../../domain/entities/outlet_details.dart';
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
  late final TextEditingController _mainPhoneNumber;
  late final TextEditingController _emailAddress;
  late final TextEditingController _addressLine1;
  late final TextEditingController _addressLine2;
  late final TextEditingController _city;
  late final TextEditingController _country;
  late final TextEditingController _postalCode;
  late List<_OpeningHourDraft> _openingHours;
  String? _managerId;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialValue;
    _outletName = TextEditingController(text: initial?.outletName ?? '');
    _outletCode = TextEditingController(text: initial?.outletCode ?? '');
    _outletType = TextEditingController(text: initial?.outletType ?? '');
    _mainPhoneNumber =
        TextEditingController(text: initial?.mainPhoneNumber ?? '');
    _emailAddress = TextEditingController(text: initial?.emailAddress ?? '');
    _addressLine1 = TextEditingController(text: initial?.addressLine1 ?? '');
    _addressLine2 = TextEditingController(text: initial?.addressLine2 ?? '');
    _city = TextEditingController(text: initial?.city ?? '');
    _country = TextEditingController(text: initial?.country ?? '');
    _postalCode = TextEditingController(text: initial?.postalCode ?? '');
    _managerId = initial?.managerId;
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
              'Basic details',
              'Address & contact',
              'Opening hours',
              'Review',
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
                label: _step == 3 ? 'Submit' : 'Continue',
                icon: _step == 3 ? Icons.check : Icons.arrow_forward,
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
          title: 'Outlet information',
          children: [
            _field('outletName', 'Outlet name', _outletName, isRequired: true),
            _field('outletCode', 'Outlet code', _outletCode, isRequired: true),
            _field('outletType', 'Outlet type', _outletType, isRequired: true),
            _field(
              'mainPhoneNumber',
              'Main phone number',
              _mainPhoneNumber,
              isRequired: true,
            ),
            _field(
              'emailAddress',
              'Email address',
              _emailAddress,
              isRequired: true,
              keyboardType: TextInputType.emailAddress,
              validator: _emailValidator,
            ),
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
          title: 'Address & contact',
          children: [
            _field('addressLine1', 'Address line 1', _addressLine1,
                isRequired: true),
            _field('addressLine2', 'Address line 2', _addressLine2),
            _field('city', 'City', _city, isRequired: true),
            _field('country', 'Country', _country, isRequired: true),
            _field('postalCode', 'Postal code', _postalCode, isRequired: true),
          ],
        );
      case 2:
        return TenantAdminFormSection(
          title: 'Opening hours',
          children: [
            for (final hour in _openingHours) _openingHourRow(hour),
          ],
        );
      default:
        return TenantAdminFormSection(
          title: 'Review',
          children: [
            _reviewLine('Outlet name', _outletName.text),
            _reviewLine('Outlet code', _outletCode.text),
            _reviewLine('Outlet type', _outletType.text),
            _reviewLine('Phone', _mainPhoneNumber.text),
            _reviewLine('Email', _emailAddress.text),
            _reviewLine('Address', '${_addressLine1.text}, ${_city.text}'),
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
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
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

  Widget _openingHourRow(_OpeningHourDraft hour) {
    return Row(
      children: [
        SizedBox(width: 90, child: Text(hour.day)),
        Expanded(
          child: TextFormField(
            controller: hour.openTime,
            decoration: const InputDecoration(labelText: 'Open time'),
            enabled: !hour.closed,
          ),
        ),
        const SizedBox(width: TenantAdminSpacing.md),
        Expanded(
          child: TextFormField(
            controller: hour.closeTime,
            decoration: const InputDecoration(labelText: 'Close time'),
            enabled: !hour.closed,
          ),
        ),
        const SizedBox(width: TenantAdminSpacing.md),
        Checkbox(
          value: hour.closed,
          onChanged: (value) {
            setState(() => hour.closed = value ?? false);
          },
        ),
        const Text('Closed'),
      ],
    );
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

  Future<void> _continue() async {
    if (_step < 3) {
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
      ('outletCode', 'Outlet code', _requiredValidator('Outlet code')),
      ('outletType', 'Outlet type', _requiredValidator('Outlet type')),
      (
        'mainPhoneNumber',
        'Main phone number',
        _requiredValidator('Main phone number')
      ),
      ('emailAddress', 'Email address', _emailValidator),
      ('addressLine1', 'Address line 1', _requiredValidator('Address line 1')),
      ('city', 'City', _requiredValidator('City')),
      ('country', 'Country', _requiredValidator('Country')),
      ('postalCode', 'Postal code', _requiredValidator('Postal code')),
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
        'country' => _country.text,
        'postalCode' => _postalCode.text,
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
      mainPhoneNumber: _mainPhoneNumber.text.trim(),
      emailAddress: _emailAddress.text.trim(),
      managerId: _managerId,
      addressLine1: _addressLine1.text.trim(),
      addressLine2: _addressLine2.text.trim(),
      city: _city.text.trim(),
      country: _country.text.trim(),
      postalCode: _postalCode.text.trim(),
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
