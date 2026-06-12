class Outlet {
  const Outlet({
    required this.id,
    required this.name,
    required this.code,
    required this.location,
    required this.status,
    required this.tillCount,
    required this.onlineTillCount,
    required this.staffCount,
    required this.todaysSales,
  });

  final String id;
  final String name;
  final String code;
  final String location;
  final String status;
  final int tillCount;
  final int onlineTillCount;
  final int staffCount;
  final String todaysSales;
}

class OutletListSummary {
  const OutletListSummary({
    required this.totalOutlets,
    required this.activeOutlets,
    required this.inactiveOutlets,
    required this.totalLocations,
  });

  final int totalOutlets;
  final int activeOutlets;
  final int inactiveOutlets;
  final int totalLocations;
}

class OutletListResult {
  const OutletListResult({
    required this.summary,
    required this.items,
  });

  final OutletListSummary summary;
  final List<Outlet> items;
}

class OutletManagerOption {
  const OutletManagerOption({
    required this.id,
    required this.displayName,
  });

  final String id;
  final String displayName;
}
