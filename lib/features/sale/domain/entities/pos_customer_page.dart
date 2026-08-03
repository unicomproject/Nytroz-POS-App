import 'pos_customer.dart';

class PosCustomerPage {
  const PosCustomerPage({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.totalCount,
    required this.totalPages,
  });

  final List<PosCustomer> items;
  final int page;
  final int pageSize;
  final int totalCount;
  final int totalPages;

  bool get hasPrevious => page > 1;
  bool get hasNext => totalPages > 0 && page < totalPages;

  factory PosCustomerPage.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] ?? json['Items'];
    final items = rawItems is List
        ? rawItems
            .whereType<Map>()
            .map(
                (item) => PosCustomer.fromJson(Map<String, dynamic>.from(item)))
            .toList(growable: false)
        : const <PosCustomer>[];

    final page = _intValue(json['page'] ?? json['Page'], fallback: 1);
    final pageSize =
        _intValue(json['pageSize'] ?? json['PageSize'], fallback: 20);
    final totalCount = _intValue(
      json['totalCount'] ?? json['TotalCount'],
      fallback: items.length,
    );
    final totalPages = _intValue(
      json['totalPages'] ?? json['TotalPages'],
      fallback: pageSize <= 0
          ? 0
          : (totalCount == 0 ? 0 : (totalCount / pageSize).ceil()),
    );

    return PosCustomerPage(
      items: items,
      page: page < 1 ? 1 : page,
      pageSize: pageSize < 1 ? 20 : pageSize,
      totalCount: totalCount < 0 ? 0 : totalCount,
      totalPages: totalPages < 0 ? 0 : totalPages,
    );
  }

  static int _intValue(Object? value, {required int fallback}) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value) ?? fallback;
    }
    return fallback;
  }
}

class PosCustomerOrderPage {
  const PosCustomerOrderPage({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.totalCount,
    required this.totalPages,
  });

  final List<PosCustomerOrder> items;
  final int page;
  final int pageSize;
  final int totalCount;
  final int totalPages;

  bool get hasPrevious => page > 1;
  bool get hasNext => totalPages > 0 && page < totalPages;

  factory PosCustomerOrderPage.fromJson(Map<String, dynamic> json) {
    final rawItems =
        json['items'] ?? json['Items'] ?? json['data'] ?? json['Data'];
    final items = rawItems is List
        ? rawItems
            .whereType<Map>()
            .map((item) =>
                PosCustomerOrder.fromJson(Map<String, dynamic>.from(item)))
            .toList(growable: false)
        : const <PosCustomerOrder>[];

    final page =
        PosCustomerPage._intValue(json['page'] ?? json['Page'], fallback: 1);
    final pageSize = PosCustomerPage._intValue(
        json['pageSize'] ?? json['PageSize'],
        fallback: 20);
    final totalCount = PosCustomerPage._intValue(
      json['totalCount'] ?? json['TotalCount'],
      fallback: items.length,
    );
    final totalPages = PosCustomerPage._intValue(
      json['totalPages'] ?? json['TotalPages'],
      fallback: pageSize <= 0
          ? 0
          : (totalCount == 0 ? 0 : (totalCount / pageSize).ceil()),
    );

    return PosCustomerOrderPage(
      items: items,
      page: page < 1 ? 1 : page,
      pageSize: pageSize < 1 ? 20 : pageSize,
      totalCount: totalCount < 0 ? 0 : totalCount,
      totalPages: totalPages < 0 ? 0 : totalPages,
    );
  }
}
