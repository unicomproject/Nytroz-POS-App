class UpdateRoleStatusRequestDto {
  const UpdateRoleStatusRequestDto({
    required this.isActive,
    this.expectedUpdatedAt,
  });

  final bool isActive;
  final DateTime? expectedUpdatedAt;

  Map<String, dynamic> toJson() {
    return {
      'isActive': isActive,
      if (expectedUpdatedAt != null) 'expectedUpdatedAt': expectedUpdatedAt!.toIso8601String(),
    };
  }
}
