import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/tenant_admin/online_store/data/datasources/online_store_remote_datasource.dart';
import 'package:nytroz_pos/features/tenant_admin/online_store/data/models/online_store_dtos.dart';
import 'package:nytroz_pos/features/tenant_admin/online_store/data/repositories/online_store_repository_impl.dart';

void main() {
  test('repository preserves create-domain verification token', () async {
    final repository = OnlineStoreRepositoryImpl(_FakeRemoteDatasource());

    final token = await repository.createDomain(
      domainName: 'store.example.com',
      domainType: 'CUSTOM',
      isPrimary: false,
    );

    expect(token.domainId, 'domain-1');
    expect(token.domainName, 'store.example.com');
    expect(token.verificationToken, 'dns-token');
  });

  test('repository preserves rotated verification token', () async {
    final repository = OnlineStoreRepositoryImpl(_FakeRemoteDatasource());

    final token = await repository.rotateDomainToken('domain-1');

    expect(token.verificationToken, 'rotated-token');
  });

  test('repository maps normalized support response', () async {
    final repository = OnlineStoreRepositoryImpl(_FakeRemoteDatasource());

    final support = await repository.updateSupport(
      email: ' help@example.test ',
      phone: '+94 11 000 0000',
      contactUsEnabled: true,
      supportHours: 'Mon - Fri: 9:00 AM - 6:00 PM',
      businessAddress: 'Example support address',
    );

    expect(support.email, 'help@example.test');
    expect(support.phone, '+94110000000');
  });
}

class _FakeRemoteDatasource extends OnlineStoreRemoteDatasource {
  _FakeRemoteDatasource() : super(Dio());

  @override
  Future<OnlineStoreDomainTokenDto> createDomain({
    required String domainName,
    required String domainType,
    required bool isPrimary,
  }) async {
    return OnlineStoreDomainTokenDto(
      domainId: 'domain-1',
      domainName: domainName,
      verificationToken: 'dns-token',
    );
  }

  @override
  Future<OnlineStoreDomainTokenDto> rotateDomainToken(String domainId) async {
    return const OnlineStoreDomainTokenDto(
      domainId: 'domain-1',
      domainName: 'store.example.com',
      verificationToken: 'rotated-token',
    );
  }

  @override
  Future<OnlineStoreSupportDto> updateSupport({
    String? email,
    String? phone,
    String? whatsapp,
    String? helpUrl,
    required bool contactUsEnabled,
    String? supportHours,
    String? businessAddress,
  }) async {
    return OnlineStoreSupportDto(
      email: email?.trim(),
      phone: '+94110000000',
      whatsapp: whatsapp,
      helpUrl: helpUrl,
      contactUsEnabled: contactUsEnabled,
      supportHours: supportHours,
      businessAddress: businessAddress,
    );
  }
}
