class PosDeviceContext {
  const PosDeviceContext({
    required this.deviceId,
    required this.deviceCode,
    required this.deviceName,
    required this.deviceType,
    required this.platform,
    required this.deviceFingerprint,
    required this.isTrusted,
    required this.tenantId,
    required this.outletId,
    required this.outletName,
    required this.tillId,
    required this.tillCode,
    required this.tillName,
    required this.pairedAt,
    this.defaultOpeningFloatAmount = 0,
    this.currencyCode = 'LKR',
  });

  final String deviceId;
  final String deviceCode;
  final String deviceName;
  final String deviceType;
  final String platform;
  final String deviceFingerprint;
  final bool isTrusted;
  final String tenantId;
  final String outletId;
  final String outletName;
  final String tillId;
  final String tillCode;
  final String tillName;
  final DateTime pairedAt;
  final double defaultOpeningFloatAmount;
  final String currencyCode;

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'deviceCode': deviceCode,
      'deviceName': deviceName,
      'deviceType': deviceType,
      'platform': platform,
      'deviceFingerprint': deviceFingerprint,
      'isTrusted': isTrusted,
      'tenantId': tenantId,
      'outletId': outletId,
      'outletName': outletName,
      'tillId': tillId,
      'tillCode': tillCode,
      'tillName': tillName,
      'pairedAt': pairedAt.toIso8601String(),
      'defaultOpeningFloatAmount': defaultOpeningFloatAmount,
      'currencyCode': currencyCode,
    };
  }

  factory PosDeviceContext.fromJson(Map<String, dynamic> json) {
    return PosDeviceContext(
      deviceId: json['deviceId'] as String? ?? '',
      deviceCode: json['deviceCode'] as String? ?? '',
      deviceName: json['deviceName'] as String? ?? '',
      deviceType: json['deviceType'] as String? ?? '',
      platform: json['platform'] as String? ?? '',
      deviceFingerprint: json['deviceFingerprint'] as String? ?? '',
      isTrusted: json['isTrusted'] == true,
      tenantId: json['tenantId'] as String? ?? '',
      outletId: json['outletId'] as String? ?? '',
      outletName: json['outletName'] as String? ?? '',
      tillId: json['tillId'] as String? ?? '',
      tillCode: json['tillCode'] as String? ?? '',
      tillName: json['tillName'] as String? ?? '',
      pairedAt: DateTime.tryParse(json['pairedAt']?.toString() ?? '') ??
          DateTime.now(),
      defaultOpeningFloatAmount: _double(json['defaultOpeningFloatAmount']),
      currencyCode: json['currencyCode'] as String? ?? 'LKR',
    );
  }
}

double _double(Object? value) {
  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value?.toString() ?? '') ?? 0;
}

class DeviceActivationForm {
  const DeviceActivationForm({
    required this.activationCode,
    required this.deviceName,
    required this.deviceFingerprint,
    required this.deviceType,
    required this.platform,
    required this.appVersion,
  });

  final String activationCode;
  final String deviceName;
  final String deviceFingerprint;
  final String deviceType;
  final String platform;
  final String appVersion;
}

class DeviceActivationException implements Exception {
  const DeviceActivationException(this.message);

  final String message;
}
