import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/core/theme/pos_theme_config.dart';

void main() {
  test('parses canonical backend POS colours', () {
    expect(parsePosThemeColor('#FF6A00'), const Color(0xFFFF6A00));
    expect(parsePosThemeColor('#000000'), const Color(0xFF000000));
  });

  test('maps valid theme DTO as backend authoritative', () {
    final theme = PosThemeConfig.fromDto(
      const PosThemeDto(
        primaryColor: '#FF6A00',
        secondaryColor: '#000000',
      ),
    );
    expect(theme.primary, const Color(0xFFFF6A00));
    expect(theme.secondary, const Color(0xFF000000));
    expect(theme.fromBackend, isTrue);
  });

  test('uses safe fallback for malformed theme values', () {
    final theme = PosThemeConfig.fromDto(
      const PosThemeDto(primaryColor: 'orange', secondaryColor: ''),
    );
    expect(theme.primary, PosThemeConfig.fallbackPrimary);
    expect(theme.secondary, PosThemeConfig.fallbackSecondary);
    expect(theme.fromBackend, isFalse);
  });
}
