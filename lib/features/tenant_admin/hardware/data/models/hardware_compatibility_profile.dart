class HardwareCompatibilityProfile {
  const HardwareCompatibilityProfile(
      {required this.id,
      required this.deviceType,
      required this.connectionType,
      required this.protocol,
      required this.adapterKey,
      required this.supportLevel,
      required this.notes});

  final String id,
      deviceType,
      connectionType,
      protocol,
      adapterKey,
      supportLevel,
      notes;
  bool get canConfigure =>
      supportLevel == 'UNVERIFIED' ||
      supportLevel == 'SUPPORTED' ||
      supportLevel == 'CERTIFIED';

  factory HardwareCompatibilityProfile.fromJson(Map<String, dynamic> json) =>
      HardwareCompatibilityProfile(
          id: json['id'] as String,
          deviceType: json['deviceType'] as String,
          connectionType: json['connectionType'] as String,
          protocol: json['protocol'] as String,
          adapterKey: json['adapterKey'] as String,
          supportLevel: json['supportLevel'] as String,
          notes: json['notes'] as String);
}
