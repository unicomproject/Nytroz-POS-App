class CreateTillRequestDto {
  const CreateTillRequestDto({
    required this.name,
    required this.code,
    required this.outletId,
    required this.status,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'code': code,
      'outletId': outletId,
      'status': status,
    };
  }

  final String name;
  final String code;
  final String outletId;
  final String status;
}
