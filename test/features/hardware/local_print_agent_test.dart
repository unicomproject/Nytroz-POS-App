import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/hardware/receipt_printer/clients/local_print_agent_client.dart';
import 'package:nytroz_pos/features/hardware/receipt_printer/config/local_print_agent_config.dart';
import 'package:nytroz_pos/features/hardware/receipt_printer/models/local_print_agent_models.dart';
import 'package:nytroz_pos/features/hardware/receipt_printer/models/pos_device_printer_config.dart';
import 'package:nytroz_pos/features/hardware/receipt_printer/presentation/providers/local_print_agent_controller.dart';
import 'package:nytroz_pos/features/hardware/receipt_printer/presentation/screens/pos_hardware_testing_screen.dart';
import 'package:nytroz_pos/features/hardware/receipt_printer/testing/local_print_agent_test_receipt.dart';

void main() {
  group('Local Print Agent configuration', () {
    test('normalizes trailing slashes and masks API key', () {
      expect(
        normalizeLocalPrintAgentUrl(' http://192.168.1.8:9101/// '),
        'http://192.168.1.8:9101',
      );
      expect(
        maskLocalPrintAgentApiKey('1234567890abcdefghijklmn'),
        '••••••••••••••••••••klmn',
      );
    });

    test('validates URL, key, endpoint, and timeout', () {
      final errors = validateLocalPrintAgentConfig(
        _config(
          url: 'ftp://localhost/api/print/receipt',
          apiKey: 'short',
          timeoutMs: 999,
        ),
      );
      expect(errors, contains('Agent URL must be a valid http or https URL.'));
      expect(errors, contains('API key must contain at least 24 characters.'));
      expect(errors, contains('Timeout must be between 1 and 30 seconds.'));

      expect(
        validateLocalPrintAgentConfig(
          _config(url: 'http://laptop:9101/api/print/receipt'),
        ),
        contains('Enter the agent base URL, not the receipt endpoint.'),
      );
    });

    test('classifies private LAN hosts', () {
      expect(isPrivateLanOrLoopbackHost('192.168.1.8'), isTrue);
      expect(isPrivateLanOrLoopbackHost('10.0.0.5'), isTrue);
      expect(isPrivateLanOrLoopbackHost('172.16.0.1'), isTrue);
      expect(isPrivateLanOrLoopbackHost('8.8.8.8'), isFalse);
      expect(isLoopbackAgentUrl('http://127.0.0.1:9101'), isTrue);
    });

    test('round-trips Local Print Agent device configuration', () {
      final restored = PosDevicePrinterConfig.fromJson(_config().toJson());
      expect(restored.connectionType, PrinterConnectionType.localPrintAgent);
      expect(restored.agentBaseUrl, 'http://192.168.1.8:9101');
      expect(restored.localApiKey, '1234567890abcdefghijklmn');
      expect(restored.agentPrinterName, 'POSPrinter POS80');
      expect(restored.connectionTimeoutMs, 5000);
    });

    test('blank key and printer update preserve saved secure values', () {
      final merged = mergeLocalPrintAgentConfig(
        deviceId: 'device-1',
        agentBaseUrl: 'http://192.168.1.8:9101',
        apiKey: '',
        timeoutMs: 5000,
        printerName: '',
        existing: _config(),
      );

      expect(merged.localApiKey, '1234567890abcdefghijklmn');
      expect(merged.agentPrinterName, 'POSPrinter POS80');
      expect(merged.connectionType, PrinterConnectionType.localPrintAgent);
    });
  });

  group('Local Print Agent contract', () {
    test('health response is parsed', () async {
      final adapter = _AgentHttpAdapter(
        statusCode: 200,
        response: {
          'agentStatus': 'running',
          'printerName': 'POSPrinter POS80',
          'printerExists': true,
          'ready': true,
          'agentVersion': '1.0.0',
          'apiVersion': '1',
          'receiptContractVersion': '3',
        },
      );
      final health = await _client(adapter).health(_config());
      expect(health.agentStatus, 'running');
      expect(health.printerName, 'POSPrinter POS80');
      expect(health.printerExists, isTrue);
      expect(health.ready, isTrue);
      expect(health.agentVersion, '1.0.0');
      expect(
        adapter.lastHeaders['X-Local-Print-Key'],
        '1234567890abcdefghijklmn',
      );
    });

    test('Chunk 6 printerReady health response is parsed', () async {
      final health = await _client(
        _AgentHttpAdapter(
          statusCode: 200,
          response: const {
            'agentStatus': 'running',
            'printerName': 'POSPrinter POS80',
            'printerExists': true,
            'printerReady': true,
            'detail': 'Windows spooler reports no blocking status.',
            'agentVersion': '1.0.0.0',
            'apiVersion': '1',
            'receiptContractVersion': '3',
          },
        ),
      ).health(_config());

      expect(health.printerName, 'POSPrinter POS80');
      expect(health.printerExists, isTrue);
      expect(health.printerReady, isTrue);
      expect(health.agentVersion, '1.0.0.0');
    });

    test('printer exists but offline remains distinct from not found', () {
      final health = LocalPrintAgentHealth.fromJson(const {
        'agentStatus': 'running',
        'configuredPrinterName': 'POSPrinter POS80',
        'printerExists': true,
        'printerReady': false,
      });

      expect(health.printerExists, isTrue);
      expect(health.printerReady, isFalse);
      expect(health.printerName, 'POSPrinter POS80');
    });

    test('missing printer fields produce an invalid response', () async {
      await expectLater(
        _client(
          _AgentHttpAdapter(
            statusCode: 200,
            response: const {
              'agentStatus': 'running',
              'agentVersion': '1.0.0.0',
            },
          ),
        ).health(_config()),
        throwsA(
          isA<LocalPrintAgentException>().having(
            (error) => error.type,
            'type',
            LocalPrintAgentFailureType.invalidResponse,
          ),
        ),
      );
    });

    test('print serializes request and includes API key header', () async {
      final adapter = _AgentHttpAdapter(
        statusCode: 200,
        response: {
          'success': true,
          'code': 'printed',
          'message': 'Printed.',
          'requestId': '11111111-1111-4111-8111-111111111111',
          'duplicate': false,
          'printerName': 'POSPrinter POS80',
          'bytesWritten': 100,
        },
      );
      final request = _request();
      final result = await _client(adapter).printReceipt(_config(), request);
      expect(result.success, isTrue);
      expect(
        adapter.lastHeaders['X-Local-Print-Key'],
        '1234567890abcdefghijklmn',
      );
      expect(adapter.lastBody['requestId'], request.requestId);
      expect(adapter.lastBody['items'], isA<List<dynamic>>());
      expect(adapter.lastBody['total'], 0);
      expect(adapter.lastBody['apiVersion'], '1');
      expect(adapter.lastBody['receiptContractVersion'], '3');
    });

    test('serializes authoritative v2 tender discount tax and copy fields', () {
      final json = _request(
        tenders: const [
          LocalPrintAgentTenderLine(
            methodCode: 'CARD',
            methodName: 'Card',
            methodType: 'CARD',
            amount: 0,
            currency: 'LKR',
            status: 'PAID',
            cardBrand: 'VISA',
            maskedCardLast4: '4242',
          ),
        ],
        discounts: const [
          LocalPrintAgentDiscountLine(
            scope: 'TRANSACTION',
            name: 'Offer',
            amount: 0,
          ),
        ],
        taxes: const [
          LocalPrintAgentTaxLine(
            taxCode: 'VAT',
            taxName: 'VAT',
            taxableAmount: 0,
            taxAmount: 0,
          ),
        ],
      ).toJson();

      expect((json['tenders'] as List).single['maskedCardLast4'], '4242');
      expect((json['discountLines'] as List).single['name'], 'Offer');
      expect((json['taxLines'] as List).single['taxCode'], 'VAT');
      expect(json['copyType'], 'CUSTOMER');
      expect(json['copyIndex'], 1);
    });

    test('accepts installed agent receipt contracts v1/v2/v3', () async {
      for (final version in const ['1', '2', '3']) {
        final adapter = _AgentHttpAdapter(
          statusCode: 200,
          response: {
            'agentStatus': 'running',
            'printerName': 'POSPrinter POS80',
            'printerExists': true,
            'ready': true,
            'apiVersion': '1',
            'receiptContractVersion': version,
          },
        );
        final health = await _client(adapter).health(_config());
        expect(health.receiptContractVersion, version);
      }
    });

    test('rejects explicitly unsupported agent contract version', () async {
      final adapter = _AgentHttpAdapter(
        statusCode: 200,
        response: {
          'agentStatus': 'running',
          'printerName': 'POSPrinter POS80',
          'printerExists': true,
          'ready': true,
          'apiVersion': '1',
          'receiptContractVersion': '99',
        },
      );

      await expectLater(
        _client(adapter).health(_config()),
        throwsA(
          isA<LocalPrintAgentException>().having(
            (error) => error.type,
            'type',
            LocalPrintAgentFailureType.updateRequired,
          ),
        ),
      );
    });

    test('maps authentication, duplicate, and printer failures', () async {
      Future<LocalPrintAgentException> failure(
        int status,
        Map<String, Object?> body,
      ) async {
        try {
          await _client(
            _AgentHttpAdapter(statusCode: status, response: body),
          ).printReceipt(_config(), _request());
          fail('Expected LocalPrintAgentException');
        } on LocalPrintAgentException catch (error) {
          return error;
        }
      }

      expect(
        (await failure(401, const {
          'success': false,
          'code': 'unauthorized',
          'message': 'No',
        }))
            .type,
        LocalPrintAgentFailureType.authentication,
      );
      expect(
        (await failure(409, const {
          'success': false,
          'code': 'duplicate_request',
          'message': 'Already accepted',
          'requestId': '11111111-1111-4111-8111-111111111111',
          'duplicate': true,
          'printerName': 'POSPrinter POS80',
        }))
            .type,
        LocalPrintAgentFailureType.duplicate,
      );
      expect(
        (await failure(503, const {
          'success': false,
          'code': 'printer_not_ready',
          'message': 'Printer offline',
          'requestId': '11111111-1111-4111-8111-111111111111',
          'duplicate': false,
          'printerName': 'POSPrinter POS80',
        }))
            .type,
        LocalPrintAgentFailureType.printerUnavailable,
      );
    });

    test('maps transport timeout without exposing API key', () async {
      final adapter = _AgentHttpAdapter(
        statusCode: 200,
        response: const {},
        failureType: DioExceptionType.connectionTimeout,
      );
      expect(
        () => _client(adapter).health(_config()),
        throwsA(
          isA<LocalPrintAgentException>()
              .having(
                (error) => error.type,
                'type',
                LocalPrintAgentFailureType.timeout,
              )
              .having(
                (error) => error.message,
                'safe message',
                isNot(contains('1234567890abcdefghijklmn')),
              ),
        ),
      );
    });

    test('manual test fixture is explicitly non-transactional', () {
      final request = const LocalPrintAgentTestReceiptBuilder().build(
        merchantName: 'OneVerz POS',
        now: DateTime.utc(2026, 7, 28),
      );
      expect(request.items.single.name, 'PRINTER TEST - NOT A SALE');
      expect(request.total, 0);
      expect(request.paymentMethod, 'TEST ONLY');
      expect(request.requestId, matches(RegExp(r'^[0-9a-f-]{36}$')));
    });
  });

  group('Local Print Agent controller states', () {
    test('maps typed failures to visible controller states', () {
      expect(
        localPrintAgentStatusForFailure(
          LocalPrintAgentFailureType.authentication,
        ),
        LocalPrintAgentUiStatus.authenticationFailed,
      );
      expect(
        localPrintAgentStatusForFailure(LocalPrintAgentFailureType.timeout),
        LocalPrintAgentUiStatus.unreachable,
      );
      expect(
        localPrintAgentStatusForFailure(
          LocalPrintAgentFailureType.printerUnavailable,
        ),
        LocalPrintAgentUiStatus.printerOffline,
      );
      expect(
        localPrintAgentStatusForFailure(
          LocalPrintAgentFailureType.invalidResponse,
        ),
        LocalPrintAgentUiStatus.invalidResponse,
      );
    });

    test('state transitions preserve config and update operation feedback', () {
      final configured = LocalPrintAgentState(
        config: _config(),
        status: LocalPrintAgentUiStatus.idle,
        message: 'Saved',
      );
      final checking = configured.copyWith(
        status: LocalPrintAgentUiStatus.checking,
        message: 'Checking',
      );
      final ready = checking.copyWith(
        status: LocalPrintAgentUiStatus.printerReady,
        message: 'Ready',
        health: const LocalPrintAgentHealth(
          agentStatus: 'running',
          printerName: 'POSPrinter POS80',
          printerExists: true,
          ready: true,
        ),
        healthSet: true,
      );
      expect(checking.isBusy, isTrue);
      expect(ready.isBusy, isFalse);
      expect(ready.config, same(configured.config));
      expect(ready.health?.ready, isTrue);
    });

    test('health maps ready, offline, and not-found states distinctly', () {
      LocalPrintAgentHealth health({
        required bool exists,
        required bool ready,
      }) =>
          LocalPrintAgentHealth(
            agentStatus: 'running',
            printerName: 'POSPrinter POS80',
            printerExists: exists,
            ready: ready,
          );

      expect(
        localPrintAgentStatusForHealth(health(exists: true, ready: true)),
        LocalPrintAgentUiStatus.printerReady,
      );
      expect(
        localPrintAgentStatusForHealth(health(exists: true, ready: false)),
        LocalPrintAgentUiStatus.printerOffline,
      );
      expect(
        localPrintAgentStatusForHealth(health(exists: false, ready: false)),
        LocalPrintAgentUiStatus.reachable,
      );
    });

    testWidgets('ready status displays the mapped POS80 printer name',
        (tester) async {
      final state = LocalPrintAgentState(
        config: _config(),
        status: LocalPrintAgentUiStatus.printerReady,
        message: 'Agent reachable. Printer is ready.',
        health: const LocalPrintAgentHealth(
          agentStatus: 'running',
          printerName: 'POSPrinter POS80',
          printerExists: true,
          ready: true,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocalPrintAgentStatusCard(state: state),
          ),
        ),
      );

      expect(find.text('Printer ready'), findsOneWidget);
      expect(find.text('Printer: POSPrinter POS80'), findsOneWidget);
    });

    test('drawer request uses dedicated endpoint and typed contract', () async {
      final adapter = _AgentHttpAdapter(
        statusCode: 200,
        response: {
          'success': true,
          'code': 'printed',
          'message': 'Accepted; verify physically.',
          'requestId': '11111111-1111-4111-8111-111111111111',
          'drawerOperationId': '22222222-2222-4222-8222-222222222222',
          'duplicate': false,
          'printerName': 'POSPrinter POS80',
          'bytesWritten': 5,
          'physicalOpenConfirmed': false,
        },
      );

      final result = await _client(adapter).openDrawer(
        _config(),
        const LocalPrintAgentDrawerOpenRequest(
          requestId: '11111111-1111-4111-8111-111111111111',
          drawerOperationId: '22222222-2222-4222-8222-222222222222',
          purpose: LocalPrintAgentDrawerPurpose.hardwareTest,
          printerName: 'POSPrinter POS80',
          drawerPort: 'drawerPin2',
          pulseOnMilliseconds: 100,
          pulseOffMilliseconds: 200,
        ),
      );

      expect(result.success, isTrue);
      expect(result.physicalOpenConfirmed, isFalse);
      expect(adapter.lastBody['drawerPurpose'], 'hardwareTest');
      expect(adapter.lastBody['pulseOnTime'], 100);
      expect(adapter.lastHeaders['X-Local-Print-Key'], isNotEmpty);
    });

    test('drawer timeout is unknown and never reported as opened', () async {
      final adapter = _AgentHttpAdapter(
        statusCode: 200,
        response: const {},
        failureType: DioExceptionType.connectionTimeout,
      );

      await expectLater(
        _client(adapter).openDrawer(
          _config(),
          const LocalPrintAgentDrawerOpenRequest(
            requestId: '11111111-1111-4111-8111-111111111111',
            drawerOperationId: '22222222-2222-4222-8222-222222222222',
            purpose: LocalPrintAgentDrawerPurpose.cashSale,
            printerName: 'POSPrinter POS80',
            drawerPort: 'drawerPin2',
            pulseOnMilliseconds: 100,
            pulseOffMilliseconds: 200,
          ),
        ),
        throwsA(
          isA<LocalPrintAgentException>().having(
            (error) => error.type,
            'type',
            LocalPrintAgentFailureType.unknown,
          ),
        ),
      );
    });
  });
}

PosDevicePrinterConfig _config({
  String url = 'http://192.168.1.8:9101',
  String apiKey = '1234567890abcdefghijklmn',
  int timeoutMs = 5000,
}) {
  return PosDevicePrinterConfig(
    deviceId: 'device-1',
    enabled: true,
    connectionType: PrinterConnectionType.localPrintAgent,
    displayName: 'Windows Local Print Agent',
    paperWidth: PrinterPaperWidth.mm80,
    agentBaseUrl: url,
    localApiKey: apiKey,
    agentPrinterName: 'POSPrinter POS80',
    connectionTimeoutMs: timeoutMs,
  );
}

LocalPrintAgentReceiptRequest _request({
  List<LocalPrintAgentTenderLine> tenders = const [],
  List<LocalPrintAgentDiscountLine> discounts = const [],
  List<LocalPrintAgentTaxLine> taxes = const [],
}) {
  return LocalPrintAgentReceiptRequest(
    requestId: '11111111-1111-4111-8111-111111111111',
    receiptNumber: 'PRINTER-TEST',
    printedAt: DateTime.utc(2026, 7, 28),
    merchantName: 'OneVerz POS',
    currency: 'LKR',
    items: const [
      LocalPrintAgentReceiptLine(
        name: 'PRINTER TEST - NOT A SALE',
        quantity: 1,
        unitPrice: 0,
        lineTotal: 0,
      ),
    ],
    subtotal: 0,
    discountTotal: 0,
    taxTotal: 0,
    total: 0,
    paymentMethod: 'TEST ONLY',
    tenders: tenders,
    discountLines: discounts,
    taxLines: taxes,
  );
}

LocalPrintAgentClient _client(_AgentHttpAdapter adapter) {
  final dio = Dio()..httpClientAdapter = adapter;
  return LocalPrintAgentClient(dio: dio);
}

class _AgentHttpAdapter implements HttpClientAdapter {
  _AgentHttpAdapter({
    required this.statusCode,
    required this.response,
    this.failureType,
  });

  final int statusCode;
  final Map<String, Object?> response;
  final DioExceptionType? failureType;
  Map<String, dynamic> lastHeaders = {};
  Map<String, dynamic> lastBody = {};

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastHeaders = Map<String, dynamic>.from(options.headers);
    if (options.data is Map) {
      lastBody = Map<String, dynamic>.from(options.data as Map);
    }
    if (failureType case final type?) {
      throw DioException(requestOptions: options, type: type);
    }
    return ResponseBody.fromString(
      jsonEncode(response),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}
