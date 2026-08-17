import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/hardware/receipt_printer/esc_pos/esc_pos_drawer_pulse_builder.dart';

void main() {
  const builder = EscPosDrawerPulseBuilder();

  test('pin 2 and pin 5 exact ESC p bytes', () {
    expect(
      builder.build(
        drawerPort: 'drawerPin2',
        pulseOnMilliseconds: 100,
        pulseOffMilliseconds: 200,
      ),
      [0x1B, 0x70, 0, 50, 100],
    );
    expect(
      builder.build(
        drawerPort: 'drawerPin5',
        pulseOnMilliseconds: 100,
        pulseOffMilliseconds: 200,
      ),
      [0x1B, 0x70, 1, 50, 100],
    );
  });

  test('timing conversion matches LocalPrintAgent (ms+1)/2 clamped', () {
    expect(EscPosDrawerPulseBuilder.toEscPosUnit(2), 1);
    expect(EscPosDrawerPulseBuilder.toEscPosUnit(3), 2);
    expect(EscPosDrawerPulseBuilder.toEscPosUnit(510), 255);
  });

  test('rejects invalid pin and out-of-range timing', () {
    expect(
      () => builder.build(
        drawerPort: 'drawerPin9',
        pulseOnMilliseconds: 100,
        pulseOffMilliseconds: 100,
      ),
      throwsArgumentError,
    );
    expect(
      () => builder.build(
        drawerPort: 'drawerPin2',
        pulseOnMilliseconds: 1,
        pulseOffMilliseconds: 100,
      ),
      throwsArgumentError,
    );
    expect(
      () => builder.build(
        drawerPort: 'drawerPin2',
        pulseOnMilliseconds: 100,
        pulseOffMilliseconds: 511,
      ),
      throwsArgumentError,
    );
  });
}
