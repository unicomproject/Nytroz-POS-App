/// Shared ESC/POS cash-drawer pulse builder.
///
/// Canonical command: `ESC p m t1 t2` (`0x1B 0x70 m t1 t2`).
/// Timing uses ESC/POS 2 ms units. Valid input range: 2–510 ms.
class EscPosDrawerPulseBuilder {
  const EscPosDrawerPulseBuilder();

  static const minPulseMs = 2;
  static const maxPulseMs = 510;
  static const portPin2 = 'drawerPin2';
  static const portPin5 = 'drawerPin5';

  /// Builds exact pulse bytes for the configured port and timings.
  List<int> build({
    required String drawerPort,
    required int pulseOnMilliseconds,
    required int pulseOffMilliseconds,
  }) {
    final pin = switch (drawerPort.trim()) {
      portPin2 => 0,
      portPin5 => 1,
      _ => throw ArgumentError.value(
          drawerPort,
          'drawerPort',
          'Supported ports are drawerPin2 and drawerPin5.',
        ),
    };
    _validateTiming(pulseOnMilliseconds, 'pulseOnMilliseconds');
    _validateTiming(pulseOffMilliseconds, 'pulseOffMilliseconds');
    return [
      0x1B,
      0x70,
      pin,
      toEscPosUnit(pulseOnMilliseconds),
      toEscPosUnit(pulseOffMilliseconds),
    ];
  }

  /// Matches LocalPrintAgent `EscPosDrawerPulseBuilder.ToEscPosUnit`.
  static int toEscPosUnit(int milliseconds) {
    final unit = ((milliseconds + 1) / 2).floor().clamp(1, 255);
    return unit;
  }

  static void _validateTiming(int milliseconds, String name) {
    if (milliseconds < minPulseMs || milliseconds > maxPulseMs) {
      throw ArgumentError.value(
        milliseconds,
        name,
        'Pulse timing must be between $minPulseMs and $maxPulseMs ms.',
      );
    }
  }
}
