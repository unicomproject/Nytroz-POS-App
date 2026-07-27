import 'dart:developer' as developer;

import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_error_message.dart';

class PosHomeRemoteDatasource {
  const PosHomeRemoteDatasource(this._dio);

  final Dio _dio;

  Future<PosHomeDashboardPayload> getPosHome({
    String? outletId,
    String? tillId,
    String? deviceId,
    String? deviceFingerprint,
  }) async {
    final stopwatch = Stopwatch()..start();
    final queryParameters = <String, dynamic>{};

    if (outletId != null && outletId.trim().isNotEmpty) {
      queryParameters['outletId'] = outletId.trim();
    }
    if (tillId != null && tillId.trim().isNotEmpty) {
      queryParameters['tillId'] = tillId.trim();
    }
    if (deviceId != null && deviceId.trim().isNotEmpty) {
      queryParameters['deviceId'] = deviceId.trim();
    }
    if (deviceFingerprint != null && deviceFingerprint.trim().isNotEmpty) {
      queryParameters['deviceFingerprint'] = deviceFingerprint.trim();
    }

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.posHome,
        queryParameters: queryParameters,
      );
      stopwatch.stop();
      final fingerprintAttached = deviceFingerprint?.trim().isNotEmpty == true;
      developer.log(
        'API success. step=pos-home endpoint=${ApiEndpoints.posHome} '
        'status=${response.statusCode} '
        'durationMs=${stopwatch.elapsedMilliseconds} '
        'authAttached=${_hasAuthHeader()} deviceId=${deviceId ?? 'none'} '
        'tillId=${tillId ?? 'none'} fingerprintAttached=$fingerprintAttached',
        name: 'pos.home',
      );

      return PosHomeDashboardPayload.fromJson(
        _unwrapApiData(response.data ?? const {}),
      );
    } on DioException catch (error) {
      stopwatch.stop();
      developer.log(
        'POS home API failed. endpoint=${ApiEndpoints.posHome}, '
        'status=${error.response?.statusCode ?? 'none'}, '
        'durationMs=${stopwatch.elapsedMilliseconds}, '
        'authAttached=${_hasAuthHeader()}, '
        'reason=${_messageFromDio(error)}',
        name: 'pos.home',
      );
      throw PosHomeException(_messageFromDio(error));
    }
  }

  Map<String, dynamic> _unwrapApiData(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    return json;
  }

  String _messageFromDio(DioException error) {
    return messageFromDioException(
      error,
      contextPrefix:
          'POS home dashboard failed at ${error.requestOptions.path}',
      fallback: 'Try again.',
    );
  }

  bool _hasAuthHeader() {
    final value = _dio.options.headers['Authorization'];
    return value is String && value.trim().isNotEmpty;
  }
}

class PosHomeDashboardPayload {
  const PosHomeDashboardPayload({
    required this.contextResolved,
    this.reasonCode,
    this.resolutionMessage,
    this.requiredAction,
    required this.userDisplayName,
    required this.outletName,
    required this.tillName,
    required this.tillAreaName,
    required this.tillNumber,
    required this.tillStatusLabel,
    required this.tillDisplayLabel,
    required this.isTillOpen,
    required this.statusMessage,
    required this.notificationCount,
    required this.permissions,
    required this.cards,
    this.serverNowUtc,
    this.outletTimezone,
    this.businessDate,
    this.cashierRoleLabel = '',
    this.businessDisplayName = '',
    this.businessLogoUrl,
    this.deviceName = '',
    this.deviceStatus = '',
    this.summary,
  });

  final bool contextResolved;
  final String? reasonCode;
  final String? resolutionMessage;
  final String? requiredAction;
  final String userDisplayName;
  final String outletName;
  final String tillName;
  final String tillAreaName;
  final int tillNumber;
  final String tillStatusLabel;
  final String tillDisplayLabel;
  final bool isTillOpen;
  final String statusMessage;
  final int notificationCount;
  final List<String> permissions;
  final PosHomeCardsPayload cards;
  final DateTime? serverNowUtc;
  final String? outletTimezone;
  final DateTime? businessDate;
  final String cashierRoleLabel;
  final String businessDisplayName;
  final String? businessLogoUrl;
  final String deviceName;
  final String deviceStatus;
  final PosHomeSummaryPayload? summary;

  factory PosHomeDashboardPayload.fromJson(Map<String, dynamic> json) {
    final contextResolved = json['contextResolved'] == true;
    final reasonCode = _nullableString(json['reasonCode']);
    final resolutionMessage = _nullableString(json['message']);
    final requiredAction = _nullableString(json['requiredAction']);

    if (!contextResolved) {
      return PosHomeDashboardPayload(
        contextResolved: false,
        reasonCode: reasonCode,
        resolutionMessage: resolutionMessage,
        requiredAction: requiredAction,
        userDisplayName: '',
        outletName: '',
        tillName: '',
        tillAreaName: '',
        tillNumber: 0,
        tillStatusLabel: 'Closed',
        tillDisplayLabel: '',
        isTillOpen: false,
        statusMessage: '',
        notificationCount: 0,
        permissions: const [],
        cards: PosHomeCardsPayload.empty(),
      );
    }

    final user = _map(json['user']);
    final cashier = _map(json['cashier']);
    final context = _map(json['context']);
    final till = _map(json['till']);
    final cards = _map(json['cards']);
    final time = _map(json['time']);
    final notifications = _map(json['notifications']);
    final branding = _map(json['branding']);
    final device = _map(json['device']);
    final summary = _map(json['summary']);

    final areaName = _string(till['areaName'], fallback: '');
    final number = _int(till['number']);
    final sessionStatus = _string(till['status'], fallback: 'Closed');
    final displayLabel = _string(till['displayLabel']);
    final tillName = _string(
      till['name'],
      fallback: _string(context['tillName'], fallback: 'Till'),
    );
    final resolvedDisplayLabel = displayLabel.isNotEmpty
        ? displayLabel
        : _buildTillDisplayLabel(
            areaName: areaName,
            number: number,
            statusLabel: sessionStatus,
            tillName: tillName,
          );
    final isTillOpen = sessionStatus.toLowerCase() == 'open';
    final userDisplayName = _string(
      cashier['displayName'],
      fallback: _string(user['fullName'], fallback: 'Cashier'),
    );

    return PosHomeDashboardPayload(
      contextResolved: true,
      userDisplayName: userDisplayName,
      outletName: _string(context['outletName'], fallback: 'Outlet'),
      tillName: tillName,
      tillAreaName: areaName,
      tillNumber: number,
      tillStatusLabel: sessionStatus,
      tillDisplayLabel: resolvedDisplayLabel,
      isTillOpen: isTillOpen,
      statusMessage: _buildStatusMessage(
        tillDisplayLabel: resolvedDisplayLabel,
        isTillOpen: isTillOpen,
      ),
      notificationCount: _int(
        notifications['unreadCount'],
        fallback: _int(json['unreadNotificationCount']),
      ),
      permissions: _stringList(json['permissions']),
      cards: PosHomeCardsPayload.fromJson(cards),
      serverNowUtc: _parseDateTime(time['serverNowUtc']),
      outletTimezone: _nullableString(time['outletTimezone']),
      businessDate:
          _parseDateOnly(time['businessDate'] ?? till['businessDate']),
      cashierRoleLabel: _string(cashier['roleLabel']),
      businessDisplayName: _string(branding['displayName']),
      businessLogoUrl: _nullableString(branding['logoUrl']),
      deviceName: _string(device['name']),
      deviceStatus: _string(device['status']),
      summary: summary.isEmpty
          ? PosHomeSummaryPayload.zero(
              currencyCode: _string(till['currencyCode'], fallback: 'LKR'),
            )
          : PosHomeSummaryPayload.fromJson(summary),
    );
  }

  String get userFacingErrorMessage {
    if (resolutionMessage != null && resolutionMessage!.trim().isNotEmpty) {
      return resolutionMessage!.trim();
    }

    return messageForReasonCode(reasonCode);
  }

  static String messageForReasonCode(String? reasonCode) {
    switch (reasonCode) {
      case 'USER_CONTEXT_MISSING':
        return 'Cashier profile could not be resolved. Please sign in again.';
      case 'DEVICE_CONTEXT_MISSING':
        return 'Current POS device could not be resolved. Activate this device first.';
      case 'DEVICE_NOT_TRUSTED':
        return 'This POS device is not trusted.';
      case 'DEVICE_NOT_ASSIGNED_TO_TILL':
        return 'This POS device is not assigned to a till.';
      case 'TILL_NOT_FOUND':
        return 'Assigned till could not be found.';
      case 'TILL_INACTIVE':
        return 'Assigned till is not active.';
      case 'NO_OPEN_TILL_SESSION':
        return 'No open till session found. Please open a till session first.';
      case 'OUTLET_TIMEZONE_MISSING':
        return 'Outlet timezone is not configured.';
      case 'PERMISSION_DENIED':
        return 'You do not have permission to view POS Home.';
      default:
        return 'POS home dashboard context could not be resolved.';
    }
  }

  static String _buildTillDisplayLabel({
    required String areaName,
    required int number,
    required String statusLabel,
    required String tillName,
  }) {
    if (areaName.isNotEmpty && number > 0) {
      final paddedNumber = number.toString().padLeft(2, '0');
      return '$areaName Till $paddedNumber / $statusLabel';
    }

    return '$tillName / $statusLabel';
  }

  static String _buildStatusMessage({
    required String tillDisplayLabel,
    required bool isTillOpen,
  }) {
    if (!isTillOpen) {
      return '$tillDisplayLabel is not open.';
    }

    return '$tillDisplayLabel is open and ready to take sales.';
  }

  static Map<String, dynamic> _map(Object? value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return const {};
  }

  static String _string(Object? value, {String fallback = ''}) {
    final text = value?.toString();
    if (text == null || text.trim().isEmpty) {
      return fallback;
    }

    return text;
  }

  static String? _nullableString(Object? value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) {
      return null;
    }

    return text;
  }

  static int _int(Object? value, {int fallback = 0}) {
    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static List<String> _stringList(Object? value) {
    if (value is Iterable) {
      return value
          .map((item) => item.toString())
          .where((item) => item.trim().isNotEmpty)
          .toList(growable: false);
    }

    return const [];
  }

  static DateTime? _parseDateTime(Object? value) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(value.toString())?.toUtc();
  }

  static DateTime? _parseDateOnly(Object? value) {
    if (value == null) {
      return null;
    }

    final parsed = DateTime.tryParse(value.toString());
    if (parsed == null) {
      return null;
    }

    return DateTime(parsed.year, parsed.month, parsed.day);
  }
}

class PosHomeSummaryPayload {
  const PosHomeSummaryPayload({
    required this.scope,
    required this.currencyCode,
    required this.grossSalesAmount,
    required this.transactionCount,
    required this.refundAmount,
    required this.refundCount,
    required this.discountAmount,
    required this.netSalesAmount,
  });

  final String scope;
  final String currencyCode;
  final double grossSalesAmount;
  final int transactionCount;
  final double refundAmount;
  final int refundCount;
  final double discountAmount;
  final double netSalesAmount;

  factory PosHomeSummaryPayload.zero({required String currencyCode}) {
    return PosHomeSummaryPayload(
      scope: 'CURRENT_TILL_SESSION',
      currencyCode: currencyCode,
      grossSalesAmount: 0,
      transactionCount: 0,
      refundAmount: 0,
      refundCount: 0,
      discountAmount: 0,
      netSalesAmount: 0,
    );
  }

  factory PosHomeSummaryPayload.fromJson(Map<String, dynamic> json) {
    return PosHomeSummaryPayload(
      scope: json['scope']?.toString() ?? 'CURRENT_TILL_SESSION',
      currencyCode: json['currencyCode']?.toString() ?? '',
      grossSalesAmount: _number(json['grossSalesAmount']),
      transactionCount: _whole(json['transactionCount']),
      refundAmount: _number(json['refundAmount']),
      refundCount: _whole(json['refundCount']),
      discountAmount: _number(json['discountAmount']),
      netSalesAmount: _number(json['netSalesAmount']),
    );
  }

  static double _number(Object? value) =>
      value is num ? value.toDouble() : double.tryParse('$value') ?? 0;

  static int _whole(Object? value) =>
      value is num ? value.toInt() : int.tryParse('$value') ?? 0;
}

class PosHomeCardsPayload {
  const PosHomeCardsPayload({
    required this.startSale,
    this.onlineOrders,
    required this.returnsRefunds,
    required this.customers,
    required this.parkedSales,
    required this.cashDrawer,
  });

  final PosHomeCardPayload startSale;
  final PosHomeCardPayload? onlineOrders;
  final PosHomeCardPayload returnsRefunds;
  final PosHomeCardPayload customers;
  final PosHomeCardPayload parkedSales;
  final PosHomeCardPayload cashDrawer;

  factory PosHomeCardsPayload.empty() {
    const disabled = PosHomeCardPayload(enabled: false);
    return const PosHomeCardsPayload(
      startSale: disabled,
      returnsRefunds: disabled,
      customers: disabled,
      parkedSales: disabled,
      cashDrawer: disabled,
    );
  }

  factory PosHomeCardsPayload.fromJson(Map<String, dynamic> json) {
    return PosHomeCardsPayload(
      startSale: PosHomeCardPayload.fromJson(_map(json['startSale'])),
      onlineOrders: _optionalCard(json['onlineOrders']),
      returnsRefunds: PosHomeCardPayload.fromJson(_map(json['returnsRefunds'])),
      customers: PosHomeCardPayload.fromJson(_map(json['customers'])),
      parkedSales: PosHomeCardPayload.fromJson(_map(json['parkedSales'])),
      cashDrawer: PosHomeCardPayload.fromJson(_map(json['cashDrawer'])),
    );
  }

  static PosHomeCardPayload? _optionalCard(Object? value) {
    if (value is Map) {
      return PosHomeCardPayload.fromJson(Map<String, dynamic>.from(value));
    }

    return null;
  }

  static Map<String, dynamic> _map(Object? value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return const {};
  }
}

class PosHomeCardPayload {
  const PosHomeCardPayload({
    required this.enabled,
    this.count,
    this.newThisWeekCount,
    this.olderThanThirtyMinutesCount,
    this.balance,
  });

  final bool enabled;
  final int? count;
  final int? newThisWeekCount;
  final int? olderThanThirtyMinutesCount;
  final double? balance;

  factory PosHomeCardPayload.fromJson(Map<String, dynamic> json) {
    return PosHomeCardPayload(
      enabled: json['enabled'] == true,
      count: _nullableInt(json['count']),
      newThisWeekCount: _nullableInt(json['newThisWeekCount']),
      olderThanThirtyMinutesCount: _nullableInt(
        json['olderThanThirtyMinutesCount'],
      ),
      balance: _nullableDouble(json['balance']),
    );
  }

  static int? _nullableInt(Object? value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value.toString());
  }

  static double? _nullableDouble(Object? value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString());
  }
}

class PosHomeException implements Exception {
  const PosHomeException(this.message);

  final String message;
}
