import '../domain/tax_aggregate.dart';

abstract class TaxRepository {
  Future<TaxAggregateListResult> getTaxes({
    int pageNumber = 1,
    int pageSize = 100,
  });

  Future<TaxAggregate?> getTax(String id);

  Future<String> createTax(TaxAggregateUpsertInput input);

  Future<void> updateTax(String id, TaxAggregateUpsertInput input);

  Future<void> deleteTax(String id);
}
