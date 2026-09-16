import 'dart:async';

/// Runtime input observations contain no barcode, customer or payment content.
class HardwareInputObservation {
  HardwareInputObservation(this.mode) : observedAt = DateTime.now().toUtc();
  final String mode;
  final DateTime observedAt;
}

final _observations = StreamController<HardwareInputObservation>.broadcast();
Stream<HardwareInputObservation> get hardwareInputObservations =>
    _observations.stream;
void observeHardwareInput(String mode) =>
    _observations.add(HardwareInputObservation(mode));
