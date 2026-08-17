class RoleDetails {
  const RoleDetails({
    required this.id,
    required this.name,
    this.description,
    required this.templateCode,
    required this.status,
    required this.isSystem,
  });

  final String id;
  final String name;
  final String? description;
  final String templateCode;
  final String status;
  final bool isSystem;
}
