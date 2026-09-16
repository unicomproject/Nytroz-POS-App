import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/hardware/receipt_printer/platform/android_receipt_printer_platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('phase16/passive-observation-test');
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test(
      'Bluetooth snapshot preserves observation time and never opens or closes transport',
      () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final calls = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      expect(call.arguments, {'address': 'AA:BB:CC:DD:EE:FF'});
      return {'observedAt': 1700000000000};
    });
    final platform = MethodChannelAndroidReceiptPrinter(channel: channel);
    final first =
        await platform.bluetoothLastWriteObservation('AA:BB:CC:DD:EE:FF');
    final second =
        await platform.bluetoothLastWriteObservation('AA:BB:CC:DD:EE:FF');
    expect(
        first, DateTime.fromMillisecondsSinceEpoch(1700000000000, isUtc: true));
    expect(second, first);
    expect(calls, ['bluetoothObservation', 'bluetoothObservation']);
  });

  test('Bluetooth without a successful observation cannot claim freshness',
      () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async => {'observedAt': null});
    expect(
        await MethodChannelAndroidReceiptPrinter(channel: channel)
            .bluetoothLastWriteObservation('AA:BB:CC:DD:EE:FF'),
        isNull);
  });
}
