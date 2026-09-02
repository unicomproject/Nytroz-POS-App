import 'package:flutter/material.dart';

class PosThemeDto {
  const PosThemeDto({
    required this.primaryColor,
    required this.secondaryColor,
  });

  final String primaryColor;
  final String secondaryColor;

  factory PosThemeDto.fromJson(Map<String, dynamic> json) => PosThemeDto(
        primaryColor: json['primaryColor']?.toString() ?? '',
        secondaryColor: json['secondaryColor']?.toString() ?? '',
      );
}

class PosThemeConfig {
  const PosThemeConfig({
    required this.primary,
    required this.secondary,
    required this.fromBackend,
  });

  static const fallbackPrimary = Color(0xFFFF6A00);
  static const fallbackSecondary = Color(0xFF000000);
  static const fallback = PosThemeConfig(
    primary: fallbackPrimary,
    secondary: fallbackSecondary,
    fromBackend: false,
  );

  final Color primary;
  final Color secondary;
  final bool fromBackend;

  factory PosThemeConfig.fromDto(PosThemeDto dto) => PosThemeConfig(
        primary: parsePosThemeColor(dto.primaryColor) ?? fallbackPrimary,
        secondary: parsePosThemeColor(dto.secondaryColor) ?? fallbackSecondary,
        fromBackend: parsePosThemeColor(dto.primaryColor) != null &&
            parsePosThemeColor(dto.secondaryColor) != null,
      );
}

Color? parsePosThemeColor(String value) {
  final normalized = value.trim();
  if (!RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(normalized)) return null;
  return Color(0xFF000000 | int.parse(normalized.substring(1), radix: 16));
}
