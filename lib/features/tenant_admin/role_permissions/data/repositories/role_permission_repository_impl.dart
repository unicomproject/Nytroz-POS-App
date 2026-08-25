import '../../domain/entities/permission_catalog.dart';
import '../../domain/entities/role_assignment.dart';
import '../../domain/entities/role_details.dart';
import '../../domain/entities/role_list_item.dart';
import '../../domain/entities/role_list_query.dart';
import '../../domain/entities/role_permissions.dart';
import '../../domain/entities/role_setup.dart';
import '../../domain/repositories/role_permission_repository.dart';
import '../datasources/role_permission_remote_datasource.dart';
import '../mappers/role_permission_mapper.dart';
import '../models/create_role_request_dto.dart';
import '../models/role_assignments_dto.dart';
import '../models/role_setup_dto.dart';
import '../models/update_role_assignments_request_dto.dart';
import '../models/update_role_permissions_request_dto.dart';
import '../models/update_role_request_dto.dart';
import '../models/update_role_status_request_dto.dart';

class RolePermissionRepositoryImpl implements RolePermissionRepository {
  const RolePermissionRepositoryImpl(this._remoteDatasource);

  final RolePermissionRemoteDatasource _remoteDatasource;

  @override
  Future<PermissionCatalog> getPermissionCatalog() async {
    final dto = await _remoteDatasource.getPermissionCatalog();
    return dto.toEntity();
  }

  @override
  Future<List<RoleSetupOption>> getSetupOptions() async {
    final dto = await _remoteDatasource.getSetupOptions();
    return dto.roles
        .where((role) =>
            role.roleCode == 'TENANT_ADMIN' || role.roleCode == 'CASHIER')
        .map(
          (role) => RoleSetupOption(
            id: role.roleId,
            code: role.roleCode,
            name: role.roleName,
            description: role.roleDescription,
            isActive: role.isActive,
            isSystem: role.isSystem,
            permissionCount: role.permissionCount,
            userCount: role.userCount,
            updatedAt: role.updatedAt,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<SaveRoleSetupResult> saveRoleSetup(
    String roleId,
    SaveRoleSetupRequest request,
  ) async {
    final payload = await _remoteDatasource.saveRoleSetup(
      roleId,
      SaveRoleSetupRequestDto(
        permissionCodes: request.permissionCodes,
        assignments: request.assignments
            .map(
              (assignment) => UserRoleAssignmentDto(
                userId: assignment.userId,
                accessScope: assignment.scopeType.value,
                outletIds: assignment.outletIds,
              ),
            )
            .toList(growable: false),
        expectedUpdatedAt: request.expectedUpdatedAt,
      ),
    );

    return SaveRoleSetupResult(
      roleId: payload['roleId']?.toString() ?? roleId,
      updatedAt: DateTime.tryParse(payload['updatedAt']?.toString() ?? ''),
    );
  }

  @override
  Future<RolePermissions> getRolePermissions(String roleId) async {
    final dto = await _remoteDatasource.getRolePermissions(roleId);
    return dto.toEntity();
  }

  @override
  Future<RolePermissions> updateRolePermissions(
    String roleId,
    UpdateRolePermissionsRequest request,
  ) async {
    final dto = await _remoteDatasource.updateRolePermissions(
      roleId,
      UpdateRolePermissionsRequestDto(
        permissionCodes: request.permissionCodes,
      ),
    );
    return dto.toEntity();
  }

  @override
  Future<RoleDetails> createRole(
    String roleName,
    String? description,
    String roleCode, {
    List<String>? permissionCodes,
    List<RoleAssignment>? assignments,
  }) async {
    final payload = await _remoteDatasource.createRole(
      CreateRoleRequestDto(
        roleName: roleName,
        roleCode: roleCode,
        roleDescription: description,
        permissionCodes: permissionCodes,
        assignments: assignments
            ?.map((e) => UserRoleAssignmentDto(
                  userId: e.userId,
                  accessScope: e.scopeType.value,
                  outletIds: e.outletIds,
                ))
            .toList(growable: false),
      ),
    );
    return RoleDetails(
      id: payload['roleId']?.toString() ?? '',
      name: payload['roleName']?.toString() ?? roleName,
      description: payload['roleDescription']?.toString() ?? description,
      templateCode: payload['roleCode']?.toString() ?? roleCode,
      status: payload['status']?.toString() ?? 'Active',
      isSystem: payload['isSystem'] as bool? ?? false,
    );
  }

  @override
  Future<PaginatedRoleList> getRoles(RoleListQuery query) async {
    final response = await _remoteDatasource.getRoles(
      query.page,
      query.pageSize,
      query.search,
      query.status,
    );
    return RolePermissionMapper.toPaginatedRoleList(response);
  }

  @override
  Future<RoleDetails> getRoleById(String roleId) async {
    final response = await _remoteDatasource.getRoleById(roleId);
    return RolePermissionMapper.toRoleDetails(response);
  }

  @override
  Future<void> updateRole(
    String roleId,
    String roleName,
    String? description,
    String roleCode,
    DateTime? expectedUpdatedAt,
  ) async {
    final request = UpdateRoleRequestDto(
      roleName: roleName,
      roleDescription: description,
      roleCode: roleCode,
      expectedUpdatedAt: expectedUpdatedAt,
    );
    await _remoteDatasource.updateRole(roleId, request);
  }

  @override
  Future<void> updateRoleStatus(
    String roleId,
    bool isActive,
    DateTime? expectedUpdatedAt,
  ) async {
    final request = UpdateRoleStatusRequestDto(
      isActive: isActive,
      expectedUpdatedAt: expectedUpdatedAt,
    );
    await _remoteDatasource.updateRoleStatus(roleId, request);
  }

  @override
  Future<void> deleteRole(String roleId, DateTime? expectedUpdatedAt) async {
    await _remoteDatasource.deleteRole(roleId, expectedUpdatedAt);
  }

  @override
  Future<List<RoleAssignment>> getRoleAssignments(String roleId) async {
    final dto = await _remoteDatasource.getRoleAssignments(roleId);
    return dto.assignments
        .map((e) => RoleAssignment(
              userId: e.userId,
              scopeType: RoleAccessScopeType.fromValue(e.accessScope),
              outletIds: e.outletIds,
              fullName: e.fullName,
              email: e.email,
            ))
        .toList(growable: false);
  }

  @override
  Future<void> updateRoleAssignments(
      String roleId, List<RoleAssignment> assignments) async {
    await _remoteDatasource.updateRoleAssignments(
      roleId,
      UpdateRoleAssignmentsRequestDto(
        assignments: assignments
            .map((e) => UserRoleAssignmentDto(
                  userId: e.userId,
                  accessScope: e.scopeType.value,
                  outletIds: e.outletIds,
                ))
            .toList(growable: false),
      ),
    );
  }
}
