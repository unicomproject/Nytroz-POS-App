import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';

class PosHomeRemoteDatasource {
  const PosHomeRemoteDatasource(this._dio);

  final Dio _dio;

  Future<PosHomeDashboardPayload> getPosHome({
    required String outletId,
    required String tillId,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.posHome,
        queryParameters: {
          'outletId': outletId,
          'tillId': tillId,
        },
      );

      return PosHomeDashboardPayload.fromJson(
        _unwrapApiData(response.data ?? const {}),
      );
    } on DioException catch (error) {
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
    final data = error.response?.data;
    if (data is Map) {
      final message = data['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message;
      }
    }

    return 'POS home dashboard could not be loaded. Try again.';
  }
}

class PosHomeDashboardPayload {
  const PosHomeDashboardPayload({
    required this.userDisplayName,
    required this.outletName,
    required this.tillName,
    required this.isTillOpen,
    required this.statusMessage,
    required this.notificationCount,
    required this.permissions,
    required this.cards,
  });

  final String userDisplayName;
  final String outletName;
  final String tillName;
  final bool isTillOpen;
  final String statusMessage;
  final int notificationCount;
  final List<String> permissions;
  final PosHomeCardsPayload cards;

  factory PosHomeDashboardPayload.fromJson(Map<String, dynamic> json) {
    final user = _map(json['user']);
    final context = _map(json['context']);
    final cards = _map(json['cards']);

    return PosHomeDashboardPayload(
      userDisplayName: _string(user['fullName'], fallback: 'Cashier'),
      outletName: _string(context['outletName'], fallback: 'Outlet'),
      tillName: _string(context['tillName'], fallback: 'Till'),
      isTillOpen: _string(context['tillSessionId']).isNotEmpty,
      statusMessage: _buildStatusMessage(context),
      notificationCount: _int(json['unreadNotificationCount']),
      permissions: _stringList(json['permissions']),
      cards: PosHomeCardsPayload.fromJson(cards),
    );
  }

  static String _buildStatusMessage(Map<String, dynamic> context) {
    final tillName = _string(context['tillName'], fallback: 'Till');
    if (_string(context['tillSessionId']).isEmpty) {
      return '$tillName is not open.';
    }

    return '$tillName is open and ready to take sales.';
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

  static int _int(Object? value) {
    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
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
}

class PosHomeCardsPayload {
  const PosHomeCardsPayload({
    required this.startSale,
    required this.onlineOrders,
    required this.returnsRefunds,
    required this.customers,
    required this.parkedSales,
    required this.cashDrawer,
  });

  final PosHomeCardPayload startSale;
  final PosHomeCardPayload onlineOrders;
  final PosHomeCardPayload returnsRefunds;
  final PosHomeCardPayload customers;
  final PosHomeCardPayload parkedSales;
  final PosHomeCardPayload cashDrawer;

  factory PosHomeCardsPayload.fromJson(Map<String, dynamic> json) {
    return PosHomeCardsPayload(
      startSale: PosHomeCardPayload.fromJson(_map(json['startSale'])),
      onlineOrders: PosHomeCardPayload.fromJson(_map(json['onlineOrders'])),
      returnsRefunds: PosHomeCardPayload.fromJson(_map(json['returnsRefunds'])),
      customers: PosHomeCardPayload.fromJson(_map(json['customers'])),
      parkedSales: PosHomeCardPayload.fromJson(_map(json['parkedSales'])),
      cashDrawer: PosHomeCardPayload.fromJson(_map(json['cashDrawer'])),
    );
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
