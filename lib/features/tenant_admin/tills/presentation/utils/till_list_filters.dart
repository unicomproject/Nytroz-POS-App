enum TillStatusFilter {
  all('All'),
  online('Online'),
  offline('Offline'),
  inactive('Inactive'),
  needsAttention('Needs attention');

  const TillStatusFilter(this.label);

  final String label;

  String? get apiStatus {
    switch (this) {
      case TillStatusFilter.all:
        return null;
      case TillStatusFilter.online:
        return 'online';
      case TillStatusFilter.offline:
        return 'offline';
      case TillStatusFilter.inactive:
        return 'inactive';
      case TillStatusFilter.needsAttention:
        return 'needs_attention';
    }
  }
}

int tillFilterCount(TillStatusFilter filter, {
  required int totalTills,
  required int onlineCount,
  required int offlineCount,
  required int inactiveCount,
  required int needsAttentionCount,
}) {
  switch (filter) {
    case TillStatusFilter.all:
      return totalTills;
    case TillStatusFilter.online:
      return onlineCount;
    case TillStatusFilter.offline:
      return offlineCount;
    case TillStatusFilter.inactive:
      return inactiveCount;
    case TillStatusFilter.needsAttention:
      return needsAttentionCount;
  }
}
