import 'dart:io';

void main() {
  final file = File(
      r'c:\Users\User\Desktop\pos final wep\Tenantadmin\Nytroz-POS-App\lib\features\tenant_admin\outlets\presentation\widgets\outlet_form.dart');
  final content = file.readAsStringSync();

  const startText =
      'class _OutletLocationContactStep extends StatelessWidget {';
  const endText = 'class _OutletReviewStep extends StatelessWidget {';

  final startIndex = content.indexOf(startText);
  final endIndex = content.indexOf(endText);

  if (startIndex == -1 || endIndex == -1) {
    // ignore: avoid_print
    print('Could not find start or end index');
    return;
  }

  const newClass = '''class _OutletLocationContactStep extends StatelessWidget {
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
          _field('addressLine1', 'Address Line 1 *', addressLine1, errors: errors, isRequired: true, maxLength: 250, icon: Icons.location_on_outlined),
          _field('addressLine2', 'Address Line 2 (optional)', addressLine2, errors: errors, maxLength: 250, icon: Icons.apartment_outlined),
        ),
        const SizedBox(height: TenantAdminSpacing.lg),
        _twoColumnRow(
          _field('city', 'City *', city, errors: errors, isRequired: true, maxLength: 120, icon: Icons.location_city_outlined),
          _field('state', 'Province / State (optional)', state, errors: errors, maxLength: 120, icon: Icons.map_outlined),
        ),
        const SizedBox(height: TenantAdminSpacing.lg),
        _twoColumnRow(
          _field('postalCode', 'Postal Code (optional)', postalCode, errors: errors, maxLength: 30, icon: Icons.local_post_office_outlined),
          _countryCodeInput(),
        ),
        const SizedBox(height: TenantAdminSpacing.lg),
        _twoColumnRow(
          _field('contactName', 'Contact Person (optional)', contactName, errors: errors, maxLength: 150, icon: Icons.person_outline),
          _field('contactPhone', 'Phone Number (optional)', contactPhone, errors: errors, maxLength: 40, keyboardType: TextInputType.phone, icon: Icons.phone_outlined, validator: _phoneValidator),
        ),
        const SizedBox(height: TenantAdminSpacing.lg),
        _twoColumnRow(
          _field('contactEmail', 'Email Address (optional)', contactEmail, errors: errors, maxLength: 255, keyboardType: TextInputType.emailAddress, icon: Icons.mail_outline, validator: _emailValidator),
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

    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth >= 1250) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 5, child: form),
            const SizedBox(width: TenantAdminSpacing.xl),
            Expanded(flex: 3, child: image),
            const SizedBox(width: TenantAdminSpacing.xl),
            const Expanded(flex: 3, child: OutletLocationGuidancePanel()),
          ],
        );
      }
      if (constraints.maxWidth >= 900) {
        return Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: form),
                const SizedBox(width: TenantAdminSpacing.xl),
                Expanded(flex: 2, child: image),
              ],
            ),
            const SizedBox(height: TenantAdminSpacing.xl),
            const OutletLocationGuidancePanel(),
          ],
        );
      }
      return Column(
        children: [
          form,
          const SizedBox(height: TenantAdminSpacing.xl),
          image,
          const SizedBox(height: TenantAdminSpacing.xl),
          const OutletLocationGuidancePanel(),
        ],
      );
    });
  }

  Widget _countryCodeInput() {
    if (countries.isEmpty) {
      return _field(
        'country',
        'Country or Region *',
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
          initialValue: value,
          icon: const Icon(Icons.keyboard_arrow_down, color: TenantAdminColors.mutedText),
          decoration: InputDecoration(
            hintText: 'Select country or region',
            hintStyle: const TextStyle(color: TenantAdminColors.mutedText, fontWeight: FontWeight.normal),
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
      ]
    );
  }
}
''';

  final newContent = content.replaceRange(startIndex, endIndex, newClass);
  file.writeAsStringSync(newContent);
  // ignore: avoid_print
  print('Successfully replaced _OutletLocationContactStep');
}
