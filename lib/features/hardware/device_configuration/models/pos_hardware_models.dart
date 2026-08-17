enum PosHardwareOperationStatus {
  notConfigured,
  loading,
  ready,
  saving,
  saved,
  checking,
  executingTest,
  awaitingPhysicalConfirmation,
  passed,
  failed,
  unknown,
  blocked,
  permissionDenied,
  versionConflict,
}

class PosHardwareConfiguration {
  const PosHardwareConfiguration({
    required this.configurationId,
    required this.posDeviceId,
    required this.outletId,
    required this.tillId,
    required this.hardwareType,
    required this.transportType,
    required this.displayName,
    required this.enabled,
    required this.configurationVersion,
    required this.activeShift,
    required this.tillSessionId,
    required this.settings,
  });

  final String configurationId;
  final String posDeviceId;
  final String outletId;
  final String? tillId;
  final String hardwareType;
  final String transportType;
  final String displayName;
  final bool enabled;
  final int configurationVersion;
  final bool activeShift;
  final String? tillSessionId;
  final Map<String, dynamic> settings;

  factory PosHardwareConfiguration.fromJson(Map<String, dynamic> json) =>
      PosHardwareConfiguration(
        configurationId: json['configurationId']?.toString() ?? '',
        posDeviceId: json['posDeviceId']?.toString() ?? '',
        outletId: json['outletId']?.toString() ?? '',
        tillId: _optional(json['tillId']),
        hardwareType: json['hardwareType']?.toString() ?? '',
        transportType: json['transportType']?.toString() ?? '',
        displayName: json['displayName']?.toString() ?? '',
        enabled: json['enabled'] == true,
        configurationVersion: _int(json['configurationVersion']),
        activeShift: json['activeShift'] == true,
        tillSessionId: _optional(json['tillSessionId']),
        settings: json['settings'] is Map
            ? Map<String, dynamic>.from(json['settings'] as Map)
            : const {},
      );
}

class HardwareTestOperation {
  const HardwareTestOperation({
    required this.testId,
    required this.requestId,
    required this.hardwareType,
    required this.testType,
    required this.configurationVersion,
    required this.status,
    required this.resultCategory,
    required this.safeMessage,
    required this.physicalConfirmation,
    required this.initiatedAt,
    required this.completedAt,
    this.detectedAt,
    this.automaticResult,
    this.scannerEvidence,
  });

  final String testId;
  final String requestId;
  final String hardwareType;
  final String testType;
  final int configurationVersion;
  final String status;
  final String? resultCategory;
  final String? safeMessage;
  final bool? physicalConfirmation;
  final DateTime? initiatedAt;
  final DateTime? completedAt;
  final DateTime? detectedAt;
  final String? automaticResult;
  final ScannerTestEvidence? scannerEvidence;

  bool get isBlocked => status.toLowerCase() == 'blocked';

  factory HardwareTestOperation.fromJson(Map<String, dynamic> json) =>
      HardwareTestOperation(
        testId: json['testId']?.toString() ?? '',
        requestId: json['requestId']?.toString() ?? '',
        hardwareType: json['hardwareType']?.toString() ?? '',
        testType: json['testType']?.toString() ?? '',
        configurationVersion: _int(json['configurationVersion']),
        status: json['status']?.toString() ?? 'Unknown',
        resultCategory: _optional(json['resultCategory']),
        safeMessage: _optional(json['safeMessage']),
        physicalConfirmation: json['physicalConfirmation'] as bool?,
        initiatedAt: DateTime.tryParse(json['initiatedAt']?.toString() ?? ''),
        completedAt: DateTime.tryParse(json['completedAt']?.toString() ?? ''),
        detectedAt: DateTime.tryParse(json['detectedAt']?.toString() ?? ''),
        automaticResult: _optional(json['automaticResult']),
        scannerEvidence: json['scannerEvidence'] is Map
            ? ScannerTestEvidence.fromJson(
                Map<String, dynamic>.from(json['scannerEvidence'] as Map),
              )
            : null,
      );
}

class PosBarcodeScannerConfiguration {
  const PosBarcodeScannerConfiguration({
    this.enabled = true,
    this.mode = 'usbHid',
    this.inputSuffix = 'enter',
    this.scanTimeout = 120,
    this.minimumBarcodeLength = 4,
    this.maximumBarcodeLength = 128,
    this.allowRapidScan = true,
    this.cameraEnabled = true,
    this.enabledFormats = const ['ean13', 'ean8', 'upcA', 'code128', 'code39'],
  });

  final bool enabled;
  final String mode;
  final String inputSuffix;
  final int scanTimeout;
  final int minimumBarcodeLength;
  final int maximumBarcodeLength;
  final bool allowRapidScan;
  final bool cameraEnabled;
  final List<String> enabledFormats;

  factory PosBarcodeScannerConfiguration.fromHardware(
    PosHardwareConfiguration configuration,
  ) {
    final settings = configuration.settings;
    final formats = settings['enabledFormats'];
    return PosBarcodeScannerConfiguration(
      enabled: configuration.enabled,
      mode: settings['mode']?.toString() == 'hid'
          ? 'usbHid'
          : settings['mode']?.toString() ?? 'usbHid',
      inputSuffix: settings['inputSuffix']?.toString() ?? 'enter',
      scanTimeout: _int(settings['scanTimeout']) == 0
          ? 120
          : _int(settings['scanTimeout']),
      minimumBarcodeLength: _int(settings['minimumBarcodeLength']) == 0
          ? 4
          : _int(settings['minimumBarcodeLength']),
      maximumBarcodeLength: _int(settings['maximumBarcodeLength']) == 0
          ? 128
          : _int(settings['maximumBarcodeLength']),
      allowRapidScan: settings['allowRapidScan'] != false,
      cameraEnabled: settings['cameraEnabled'] != false,
      enabledFormats: formats is List
          ? formats.map((item) => item.toString()).toList(growable: false)
          : const ['ean13', 'ean8', 'upcA', 'code128', 'code39'],
    );
  }
}

class ScannerTestEvidence {
  const ScannerTestEvidence({
    required this.scannerMode,
    required this.barcodeLength,
    required this.barcodeHash,
    required this.eventCount,
    required this.expectedEventCount,
    required this.droppedScans,
    required this.duplicateScans,
    required this.averageLatencyMs,
    required this.maximumLatencyMs,
  });

  final String scannerMode;
  final int barcodeLength;
  final String? barcodeHash;
  final int eventCount;
  final int? expectedEventCount;
  final int droppedScans;
  final int duplicateScans;
  final double? averageLatencyMs;
  final double? maximumLatencyMs;

  factory ScannerTestEvidence.fromJson(Map<String, dynamic> json) =>
      ScannerTestEvidence(
        scannerMode: json['scannerMode']?.toString() ?? '',
        barcodeLength: _int(json['barcodeLength']),
        barcodeHash: _optional(json['barcodeHash']),
        eventCount: _int(json['eventCount']),
        expectedEventCount: json['expectedEventCount'] == null
            ? null
            : _int(json['expectedEventCount']),
        droppedScans: _int(json['droppedScans']),
        duplicateScans: _int(json['duplicateScans']),
        averageLatencyMs: _double(json['averageLatencyMs']),
        maximumLatencyMs: _double(json['maximumLatencyMs']),
      );
}

class PosHardwareApiException implements Exception {
  const PosHardwareApiException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => message;
}

String? _optional(Object? value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

int _int(Object? value) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? 0;

double? _double(Object? value) =>
    value is num ? value.toDouble() : double.tryParse('$value');

class PosCashDrawerConfiguration {
  const PosCashDrawerConfiguration({
    required this.enabled,
    required this.linkedReceiptPrinterId,
    required this.drawerPort,
    required this.pulseOnMilliseconds,
    required this.pulseOffMilliseconds,
    required this.policy,
    required this.openOnCashSale,
    required this.openOnCashRefund,
    required this.openOnCashSplit,
    required this.manualOpenEnabled,
  });

  final bool enabled;
  final String? linkedReceiptPrinterId;
  final String drawerPort;
  final int pulseOnMilliseconds;
  final int pulseOffMilliseconds;
  final String policy;
  final bool openOnCashSale;
  final bool openOnCashRefund;
  final bool openOnCashSplit;
  final bool manualOpenEnabled;

  factory PosCashDrawerConfiguration.fromHardware(
      PosHardwareConfiguration config) {
    final s = config.settings;
    return PosCashDrawerConfiguration(
      enabled: config.enabled,
      linkedReceiptPrinterId: s['linkedReceiptPrinterId']?.toString(),
      drawerPort: s['drawerPort']?.toString() ?? 'drawerPin2',
      pulseOnMilliseconds: s['pulseOnMilliseconds'] is num
          ? (s['pulseOnMilliseconds'] as num).toInt()
          : 100,
      pulseOffMilliseconds: s['pulseOffMilliseconds'] is num
          ? (s['pulseOffMilliseconds'] as num).toInt()
          : 200,
      policy: s['policy']?.toString() ?? 'never',
      openOnCashSale: s['openOnCashSale'] != false,
      openOnCashRefund: s['openOnCashRefund'] != false,
      openOnCashSplit: s['openOnCashSplit'] != false,
      manualOpenEnabled: s['manualOpenEnabled'] == true,
    );
  }
}
