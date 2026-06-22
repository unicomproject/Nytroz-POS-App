class Till {
  const Till({
    required this.id,
    required this.outletId,
    required this.outletName,
    required this.name,
    required this.code,
    required this.status,
    required this.operationalStatus,
    this.attentionLabel,
    this.todaySalesAmount,
    this.currency,
    this.lastSyncAt,
  });

  final String id;
  final String outletId;
  final String outletName;
  final String name;
  final String code;
  final String status;
  final String operationalStatus;
  final String? attentionLabel;
  final double? todaySalesAmount;
  final String? currency;
  final DateTime? lastSyncAt;
}

class TillListSummary {
  const TillListSummary({
    required this.totalTills,
    required this.onlineCount,
    required this.offlineCount,
    required this.needsAttentionCount,
  });

  final int totalTills;
  final int onlineCount;
  final int offlineCount;
  final int needsAttentionCount;
}

class TillListResult {
  const TillListResult({
    required this.summary,
    required this.items,
    this.page = 1,
    this.pageSize = 10,
    this.totalCount = 0,
  });

  final TillListSummary summary;
  final List<Till> items;
  final int page;
  final int pageSize;
  final int totalCount;

  int get totalPages {
    if (pageSize <= 0 || totalCount <= 0) {
      return totalCount > 0 ? 1 : 0;
    }

    return (totalCount / pageSize).ceil();
  }

  int get rangeStart {
    if (totalCount == 0) {
      return 0;
    }

    return ((page - 1) * pageSize) + 1;
  }

  int get rangeEnd {
    if (totalCount == 0) {
      return 0;
    }

    return (page * pageSize).clamp(0, totalCount);
  }
}

class TillListQuery {
  const TillListQuery({
    this.search,
    this.page = 1,
    this.pageSize = 10,
    this.status,
    this.sortBy = 'name',
    this.sortDirection = 'asc',
  });

  final String? search;
  final int page;
  final int pageSize;
  final String? status;
  final String sortBy;
  final String sortDirection;
}

class TillFormData {
  const TillFormData({
    required this.name,
    required this.code,
    required this.outletId,
    required this.status,
  });

  final String name;
  final String code;
  final String outletId;
  final String status;
}

class CreatedTill {
  const CreatedTill({
    required this.id,
    required this.outletId,
    required this.name,
    required this.code,
    required this.status,
  });

  final String id;
  final String outletId;
  final String name;
  final String code;
  final String status;
}
