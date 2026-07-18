import '../../domain/entities/outlet_create_options.dart';

class OutletCreateOptionsDto {
  const OutletCreateOptionsDto({
    required this.outletTypes,
    required this.countries,
    required this.timezones,
    required this.defaults,
  });

  factory OutletCreateOptionsDto.fromJson(Map<String, dynamic> json) {
    return OutletCreateOptionsDto(
      outletTypes: _selectOptionList(
        json['outletTypes'],
        normalizeValue: (value) => value.trim().toUpperCase(),
      ),
      countries: _countryList(json['countries']),
      timezones: _selectOptionList(json['timezones']),
      defaults: OutletCreateDefaultsDto.fromJson(
        json['defaults'] is Map
            ? Map<String, dynamic>.from(json['defaults'] as Map)
            : const {},
      ),
    );
  }

  final List<OutletSelectOptionDto> outletTypes;
  final List<OutletCountryOptionDto> countries;
  final List<OutletSelectOptionDto> timezones;
  final OutletCreateDefaultsDto defaults;

  OutletCreateOptions toEntity() {
    return OutletCreateOptions(
      outletTypes: outletTypes.map((option) => option.toEntity()).toList(),
      countries: countries.map((country) => country.toEntity()).toList(),
      timezones: timezones.map((option) => option.toEntity()).toList(),
      defaults: defaults.toEntity(),
    );
  }
}

class OutletSelectOptionDto {
  const OutletSelectOptionDto({
    required this.value,
    required this.label,
  });

  factory OutletSelectOptionDto.fromJson(
    Map<String, dynamic> json, {
    String Function(String value)? normalizeValue,
  }) {
    final rawValue = json['value']?.toString().trim() ??
        json['code']?.toString().trim() ??
        '';
    final value = normalizeValue?.call(rawValue) ?? rawValue;
    final label = json['label']?.toString().trim() ??
        json['name']?.toString().trim() ??
        value;

    return OutletSelectOptionDto(value: value, label: label);
  }

  final String value;
  final String label;

  OutletSelectOption toEntity() {
    return OutletSelectOption(
      value: value,
      label: label,
    );
  }
}

class OutletCountryOptionDto {
  const OutletCountryOptionDto({
    required this.code,
    required this.name,
  });

  factory OutletCountryOptionDto.fromJson(Map<String, dynamic> json) {
    final code = json['code']?.toString().trim().toUpperCase() ?? '';
    return OutletCountryOptionDto(
      code: code,
      name: json['name']?.toString().trim() ?? code,
    );
  }

  final String code;
  final String name;

  OutletCountryOption toEntity() {
    return OutletCountryOption(
      code: code,
      name: name,
    );
  }
}

class OutletCreateDefaultsDto {
  const OutletCreateDefaultsDto({
    required this.countryCode,
    required this.timezone,
    required this.status,
  });

  factory OutletCreateDefaultsDto.fromJson(Map<String, dynamic> json) {
    return OutletCreateDefaultsDto(
      countryCode: _optionValue(json['countryCode']).toUpperCase(),
      timezone: _optionValue(json['timezone']),
      status: _optionValue(json['status']).toUpperCase(),
    );
  }

  final String countryCode;
  final String timezone;
  final String status;

  OutletCreateDefaults toEntity() {
    return OutletCreateDefaults(
      countryCode: countryCode,
      timezone: timezone,
      status: status,
    );
  }
}

List<OutletSelectOptionDto> _selectOptionList(
  Object? value, {
  String Function(String value)? normalizeValue,
}) {
  if (value is! List) {
    return const [];
  }

  return value
      .map((item) => _selectOption(item, normalizeValue: normalizeValue))
      .where((option) => option.value.isNotEmpty)
      .toList(growable: false);
}

String _optionValue(Object? value) {
  if (value is Map) {
    return (value['value'] ?? value['code'] ?? '').toString().trim();
  }

  return value?.toString().trim() ?? '';
}

OutletSelectOptionDto _selectOption(
  Object? value, {
  String Function(String value)? normalizeValue,
}) {
  if (value is Map) {
    return OutletSelectOptionDto.fromJson(
      Map<String, dynamic>.from(value),
      normalizeValue: normalizeValue,
    );
  }

  final rawValue = value?.toString().trim() ?? '';
  final optionValue = normalizeValue?.call(rawValue) ?? rawValue;
  return OutletSelectOptionDto(value: optionValue, label: optionValue);
}

List<OutletCountryOptionDto> _countryList(Object? value) {
  if (value is! List) {
    return const [];
  }

  return value
      .map(_countryOption)
      .where((country) => country.code.isNotEmpty)
      .toList(growable: false);
}

OutletCountryOptionDto _countryOption(Object? value) {
  if (value is Map) {
    return OutletCountryOptionDto.fromJson(Map<String, dynamic>.from(value));
  }

  final code = value?.toString().trim().toUpperCase() ?? '';
  return OutletCountryOptionDto(code: code, name: code);
}
