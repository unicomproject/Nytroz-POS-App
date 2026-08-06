import '../../domain/entities/outlet.dart';

enum OutletStatusFilter {
  all,
  active,
  inactive,
}

extension OutletStatusFilterX on OutletStatusFilter {
  String get label {
    switch (this) {
      case OutletStatusFilter.all:
        return 'All';
      case OutletStatusFilter.active:
        return 'Active';
      case OutletStatusFilter.inactive:
        return 'Inactive';
    }
  }

  String? get apiStatus {
    switch (this) {
      case OutletStatusFilter.all:
        return null;
      case OutletStatusFilter.active:
        return 'active';
      case OutletStatusFilter.inactive:
        return 'inactive';
    }
  }
}

bool outletMatchesStatusFilter(Outlet outlet, OutletStatusFilter filter) {
  switch (filter) {
    case OutletStatusFilter.all:
      return true;
    case OutletStatusFilter.active:
      return _normalizedOutletStatus(outlet.status) == 'active';
    case OutletStatusFilter.inactive:
      return _normalizedOutletStatus(outlet.status) == 'inactive';
  }
}

List<Outlet> filterOutletsByStatus(
  List<Outlet> outlets,
  OutletStatusFilter filter,
) {
  if (filter == OutletStatusFilter.all) {
    return outlets;
  }

  return outlets
      .where((outlet) => outletMatchesStatusFilter(outlet, filter))
      .toList(growable: false);
}

String displayOutletStatus(String status) {
  final normalized = _normalizedOutletStatus(status);
  if (normalized.isEmpty) {
    return 'Active';
  }

  if (normalized == 'active') {
    return 'Active';
  }

  if (normalized == 'inactive') {
    return 'Inactive';
  }

  return status.trim().isEmpty ? 'Active' : status;
}

String _normalizedOutletStatus(String status) {
  return status.trim().toLowerCase();
}

enum OutletTypeFilter {
  all,
  store,
  warehouse,
}

extension OutletTypeFilterX on OutletTypeFilter {
  String get label {
    switch (this) {
      case OutletTypeFilter.all:
        return 'All Types';
      case OutletTypeFilter.store:
        return 'Store';
      case OutletTypeFilter.warehouse:
        return 'Warehouse';
    }
  }

  String? get apiType {
    switch (this) {
      case OutletTypeFilter.all:
        return null;
      case OutletTypeFilter.store:
        return 'store';
      case OutletTypeFilter.warehouse:
        return 'warehouse';
    }
  }
}
