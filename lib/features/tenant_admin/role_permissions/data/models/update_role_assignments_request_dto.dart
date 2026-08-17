import 'role_assignments_dto.dart';

class UpdateRoleAssignmentsRequestDto {
  const UpdateRoleAssignmentsRequestDto({
    required this.assignments,
  });

  Map<String, dynamic> toJson() {
    return {
      'assignments': assignments.map((e) => e.toJson()).toList(growable: false),
    };
  }

  final List<UserRoleAssignmentDto> assignments;
}
