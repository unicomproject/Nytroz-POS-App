class OutletCreateOptions {
  const OutletCreateOptions({
    required this.outletTypes,
    required this.countries,
    required this.timezones,
    required this.defaults,
  });

  final List<OutletSelectOption> outletTypes;
  final List<OutletCountryOption> countries;
  final List<OutletSelectOption> timezones;
  final OutletCreateDefaults defaults;
}

class OutletSelectOption {
  const OutletSelectOption({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;
}

class OutletCountryOption {
  const OutletCountryOption({
    required this.code,
    required this.name,
  });

  final String code;
  final String name;

  String get label {
    if (name.trim().isEmpty) {
      return code;
    }

    return '$name ($code)';
  }
}

class OutletCreateDefaults {
  const OutletCreateDefaults({
    required this.countryCode,
    required this.timezone,
    required this.status,
  });

  final String countryCode;
  final String timezone;
  final String status;
}
