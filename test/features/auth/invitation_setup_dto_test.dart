import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/auth/data/models/setup_token_validation_dto.dart';
import 'package:nytroz_pos/features/auth/data/models/set_password_request_dto.dart';

void main() {
  group('Phase 5 invitation DTOs', () {
    test('SetupTokenValidationDto parses flat backend payload', () {
      final dto = SetupTokenValidationDto.fromJson({
        'setupToken': 'tok',
        'valid': true,
        'expired': false,
        'email': 'admin@example.test',
        'message': null,
      });

      expect(dto.setupToken, 'tok');
      expect(dto.valid, isTrue);
      expect(dto.expired, isFalse);
      expect(dto.email, 'admin@example.test');
    });

    test('SetPasswordRequestDto serializes camelCase fields', () {
      const dto = SetPasswordRequestDto(
        setupToken: 'tok',
        password: 'Password1',
        confirmPassword: 'Password1',
      );

      expect(dto.toJson(), {
        'setupToken': 'tok',
        'password': 'Password1',
        'confirmPassword': 'Password1',
      });
    });
  });
}
