class CreateTillRequestDto {
  const CreateTillRequestDto({
    required this.name,
    required this.code,
    required this.outletId,
    required this.status,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name.trim(),
      'code': code.trim(),
      'outletId': outletId,
      'status': status.trim(),
    };
  }

  final String name;
  final String code;
  final String outletId;
  final String status;
}
