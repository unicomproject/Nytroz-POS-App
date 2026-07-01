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

  int get total => totalTills;

  double? get onlinePercent =>
      totalTills == 0 ? null : (onlineCount / totalTills) * 100;

  double? get offlinePercent =>
      totalTills == 0 ? null : (offlineCount / totalTills) * 100;

  double? get needsAttentionPercent =>
      totalTills == 0 ? null : (needsAttentionCount / totalTills) * 100;
}

class TillListResult {
  const TillListResult({
    required this.summary,
    required this.items,
    required this.page,
    required this.pageSize,
    required this.totalCount,
  });

  final TillListSummary summary;
  final List<Till> items;
  final int page;
  final int pageSize;
  final int totalCount;
}

class CreateTillInput {
  const CreateTillInput({
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

class TillOutletOption {
  const TillOutletOption({
    required this.id,
    required this.name,
    required this.code,
  });

  final String id;
  final String name;
  final String code;
}
