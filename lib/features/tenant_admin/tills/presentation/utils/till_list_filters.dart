enum TillStatusFilter {
  all,
  online,
  offline,
  inactive,
  needsAttention,
}

extension TillStatusFilterX on TillStatusFilter {
  String get label {
    switch (this) {
      case TillStatusFilter.all:
        return 'All';
      case TillStatusFilter.online:
        return 'Online';
      case TillStatusFilter.offline:
        return 'Offline';
      case TillStatusFilter.inactive:
        return 'Inactive';
      case TillStatusFilter.needsAttention:
        return 'Needs attention';
    }
  }

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
