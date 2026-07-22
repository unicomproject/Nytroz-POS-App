import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/sale/presentation/widgets/new_sale/pos_camera_barcode_scanner.dart';

void main() {
  test('first valid camera frame is accepted once and preserves leading zero',
      () {
    final gate = PosCameraDetectionGate();

    expect(gate.accept([null, ' ', '0012345678905']), '0012345678905');
    expect(gate.accept(['0012345678905']), isNull);
    expect(gate.accept(['2000000000114']), isNull);
    expect(gate.isLocked, isTrue);
  });

  test('empty frames do not lock detection', () {
    final gate = PosCameraDetectionGate();

    expect(gate.accept([null, '', '   ']), isNull);
    expect(gate.isLocked, isFalse);
    expect(gate.accept(['2000000000114']), '2000000000114');
  });
}
