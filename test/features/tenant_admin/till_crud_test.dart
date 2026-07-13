import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/tenant_admin/tills/application/usecases/delete_till.dart';
import 'package:nytroz_pos/features/tenant_admin/tills/application/usecases/get_till_by_id.dart';
import 'package:nytroz_pos/features/tenant_admin/tills/application/usecases/update_till.dart';
import 'package:nytroz_pos/features/tenant_admin/tills/data/models/create_till_request_dto.dart';
import 'package:nytroz_pos/features/tenant_admin/tills/data/models/till_dto.dart';
import 'package:nytroz_pos/features/tenant_admin/tills/domain/entities/till.dart';
import 'package:nytroz_pos/features/tenant_admin/tills/domain/repositories/till_repository.dart';

void main() {
  group('TillDetailDto', () {
    test('parses tenant-admin detail payload', () {
      final dto = TillDetailDto.fromJson({
        'tillId': 'till-1',
        'tillName': 'Front Counter',
        'tillCode': 'TILL-001',
        'outletId': 'outlet-1',
        'outletName': 'High Street Store',
        'outletCode': 'OUT-001',
        'status': 'Active',
        'deviceStatus': 'Online',
        'needsAttention': false,
        'deviceName': 'POS-1',
        'printerName': 'Printer A',
        'createdAt': '2026-07-10T10:00:00Z',
        'updatedAt': '2026-07-10T11:00:00Z',
      });

      expect(dto.id, 'till-1');
      expect(dto.name, 'Front Counter');
      expect(dto.deviceName, 'POS-1');
    });
  });

  group('CreateTillRequestDto', () {
    test('sends ACTIVE status and hardware fields supported by API', () {
      final json = const CreateTillRequestDto(
        tillName: 'Front Counter',
        tillCode: 'TILL-001',
        outletId: 'outlet-1',
        status: 'active',
        deviceName: 'POS-1',
        printerName: 'Printer A',
      ).toJson();

      expect(json['status'], 'ACTIVE');
      expect(json['deviceName'], 'POS-1');
      expect(json['printerName'], 'Printer A');
      expect(json.containsKey('scannerName'), isFalse);
    });
  });

  group('Till repository use cases', () {
    test('getTillById calls repository', () async {
      final repository = _FakeTillRepository();
      final detail = await GetTillById(repository).call('till-1');

      expect(repository.getTillByIdCalled, isTrue);
      expect(detail.id, 'till-1');
    });

    test('updateTill calls repository once', () async {
      final repository = _FakeTillRepository();
      await UpdateTill(repository).call(
        id: 'till-1',
        form: const TillFormData(
          name: 'Updated',
          code: 'TILL-002',
          outletId: 'outlet-1',
          status: 'active',
        ),
      );

      expect(repository.updateTillCalled, isTrue);
    });

    test('deleteTill calls repository', () async {
      final repository = _FakeTillRepository();
      await DeleteTill(repository).call('till-1');

      expect(repository.deleteTillCalled, isTrue);
    });
  });
}

class _FakeTillRepository implements TillRepository {
  var getTillByIdCalled = false;
  var updateTillCalled = false;
  var deleteTillCalled = false;

  @override
  Future<CreatedTill> createTill(TillFormData form) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteTill(String id) async {
    deleteTillCalled = true;
  }

  @override
  Future<TillDetail> getTillById(String id) async {
    getTillByIdCalled = true;
    return TillDetail(
      id: id,
      outletId: 'outlet-1',
      outletName: 'Outlet',
      outletCode: 'OUT-001',
      name: 'Till',
      code: 'TILL-001',
      status: 'Active',
      deviceStatus: 'Online',
      needsAttention: false,
    );
  }

  @override
  Future<TillListResult> getTills({required TillListQuery query}) {
    throw UnimplementedError();
  }

  @override
  Future<List<OutletOption>> getOutletOptions() {
    throw UnimplementedError();
  }

  @override
  Future<TillDetail> updateTill(String id, TillFormData form) async {
    updateTillCalled = true;
    return TillDetail(
      id: id,
      outletId: form.outletId,
      outletName: 'Outlet',
      outletCode: 'OUT-001',
      name: form.name,
      code: form.code,
      status: form.status,
      deviceStatus: 'Online',
      needsAttention: false,
    );
  }
}
