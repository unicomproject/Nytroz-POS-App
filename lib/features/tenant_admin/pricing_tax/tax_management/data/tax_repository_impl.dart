import 'package:dio/dio.dart';

import '../domain/tax_aggregate.dart';
import 'tax_dtos.dart';
import 'tax_repository.dart';

class TaxRepositoryImpl implements TaxRepository {
  const TaxRepositoryImpl(this._apiClient);

  final Dio _apiClient;

  @override
  Future<TaxAggregateListResult> getTaxes({
    int pageNumber = 1,
    int pageSize = 100,
  }) async {
    try {
      final response = await _apiClient.get(
        '/api/v1/tax',
        queryParameters: {
          'pageNumber': pageNumber,
          'pageSize': pageSize,
        },
      );
      final dto = TaxAggregateListResultDto.fromJson(response.data);
      return TaxAggregateListResult(
        pageNumber: dto.pageNumber,
        pageSize: dto.pageSize,
        totalCount: dto.totalCount,
        items: dto.items.map(_mapTaxAggregateDto).toList(),
      );
    } on DioException catch (_) {
      rethrow;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<TaxAggregate?> getTax(String id) async {
    try {
      final response = await _apiClient.get('/api/v1/tax/$id');
      if (response.data == null) return null;
      final dto = TaxAggregateDto.fromJson(response.data);
      return _mapTaxAggregateDto(dto);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<String> createTax(TaxAggregateUpsertInput input) async {
    try {
      final dto = TaxAggregateCreateRequestDto(
        taxCode: input.taxCode,
        taxName: input.taxName,
        taxType: input.taxType,
        taxPercentage: input.taxPercentage,
        description: input.description,
        status: input.status,
      );
      final response = await _apiClient.post(
        '/api/v1/tax',
        data: dto.toJson(),
      );
      return response.data?.toString() ?? '';
    } on DioException catch (_) {
      rethrow;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<void> updateTax(String id, TaxAggregateUpsertInput input) async {
    try {
      final dto = TaxAggregateUpdateRequestDto(
        taxName: input.taxName,
        taxType: input.taxType,
        taxPercentage: input.taxPercentage,
        description: input.description,
        status: input.status,
      );
      await _apiClient.put(
        '/api/v1/tax/$id',
        data: dto.toJson(),
      );
    } on DioException catch (_) {
      rethrow;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<void> deleteTax(String id) async {
    try {
      await _apiClient.delete('/api/v1/tax/$id');
    } on DioException catch (_) {
      rethrow;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  TaxAggregate _mapTaxAggregateDto(TaxAggregateDto dto) {
    return TaxAggregate(
      id: dto.id,
      taxCode: dto.taxCode,
      taxName: dto.taxName,
      taxType: dto.taxType,
      taxPercentage: dto.taxPercentage,
      status: dto.status,
      description: dto.description,
    );
  }
}
