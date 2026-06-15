class PosSessionContext {
  const PosSessionContext({
    required this.brandName,
    required this.brandSubtitle,
    required this.outletName,
    required this.outletLocation,
    required this.tillName,
    required this.tillStatus,
    required this.userName,
    required this.userRole,
    required this.deviceName,
    required this.deviceCode,
    required this.systemStatus,
    required this.lastSyncLabel,
  });

  final String brandName;
  final String brandSubtitle;
  final String outletName;
  final String outletLocation;
  final String tillName;
  final String tillStatus;
  final String userName;
  final String userRole;
  final String deviceName;
  final String deviceCode;
  final String systemStatus;
  final String lastSyncLabel;
}
