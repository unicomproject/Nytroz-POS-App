import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/tenant_admin/pricing_tax/tax_management/data/tax_dtos.dart';
import 'package:nytroz_pos/features/tenant_admin/pricing_tax/tax_management/domain/tax_status.dart';
import 'package:nytroz_pos/features/tenant_admin/pricing_tax/tax_management/domain/tax_treatment.dart';
import 'package:nytroz_pos/features/tenant_admin/pricing_tax/tax_management/presentation/utils/tax_formatters.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/tenant_product_create_options.dart';

void main() {
  group('TaxTreatment', () {
    test('parses canonical values', () {
      expect(TaxTreatment.parse('TAXABLE'), TaxTreatment.taxable);
      expect(TaxTreatment.parse('ZERO_RATED'), TaxTreatment.zeroRated);
      expect(TaxTreatment.parse('EXEMPT'), TaxTreatment.exempt);
    });

    test('does not collapse EXEMPT into ZERO_RATED', () {
      expect(TaxTreatment.parse('EXEMPT'), isNot(TaxTreatment.zeroRated));
    });
  });

  group('Tax formatters', () {
    test('TAXABLE shows percent', () {
      expect(
        formatCurrentRateDisplay(
          treatment: TaxTreatment.taxable,
          currentRate: 18,
        ),
        '18%',
      );
    });

    test('ZERO_RATED shows 0%', () {
      expect(
        formatCurrentRateDisplay(
          treatment: TaxTreatment.zeroRated,
          currentRate: 0,
        ),
        '0%',
      );
    });

    test('EXEMPT shows Exempt not 0%', () {
      expect(
        formatCurrentRateDisplay(
          treatment: TaxTreatment.exempt,
          currentRate: 0,
        ),
        'Exempt',
      );
    });

    test('next change formats rate and date', () {
      expect(
        formatNextChange(
          nextRate: 20,
          nextRateEffectiveFrom: DateTime(2027, 1, 1),
        ),
        '20% on 01 Jan 2027',
      );
    });

    test('no next change shows dash', () {
      expect(
        formatNextChange(nextRate: null, nextRateEffectiveFrom: null),
        '—',
      );
    });
  });

  group('TaxSetupDto', () {
    test('deserializes canonical list item fields', () {
      final dto = TaxSetupDto.fromJson({
        'id': 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
        'name': 'Standard Tax',
        'code': 'STD-TAX',
        'taxTreatment': 'TAXABLE',
        'status': 'ACTIVE',
        'currentRate': 18,
        'currentRateEffectiveFrom': '2026-01-01',
        'nextRate': 20,
        'nextRateEffectiveFrom': '2027-01-01',
        'productCount': 12,
      });

      final domain = dto.toDomain();
      expect(domain.name, 'Standard Tax');
      expect(domain.code, 'STD-TAX');
      expect(domain.taxTreatment, TaxTreatment.taxable);
      expect(domain.status, TaxStatus.active);
      expect(domain.currentRate, 18);
      expect(domain.nextRate, 20);
      expect(domain.productCount, 12);
    });

    test('create request omits initialRate for EXEMPT', () {
      final json = TaxSetupCreateRequestDto(
        name: 'Exempt Tax',
        code: 'EXEMPT',
        taxTreatment: TaxTreatment.exempt,
        effectiveFrom: DateTime(2026, 1, 1),
      ).toJson();

      expect(json['taxTreatment'], 'EXEMPT');
      expect(json.containsKey('initialRate'), isFalse);
      expect(json['effectiveFrom'], '2026-01-01');
    });

    test('create request sends ZERO_RATED rate 0', () {
      final json = TaxSetupCreateRequestDto(
        name: 'Zero',
        code: 'ZR',
        taxTreatment: TaxTreatment.zeroRated,
        initialRate: 0,
        effectiveFrom: DateTime(2026, 1, 1),
      ).toJson();

      expect(json['taxTreatment'], 'ZERO_RATED');
      expect(json['initialRate'], 0);
    });
  });

  group('ProductTaxOption labels', () {
    test('TAXABLE label includes rate', () {
      expect(
        const ProductTaxOption(
          id: '1',
          code: 'STD',
          name: 'Standard Tax',
          taxTreatment: 'TAXABLE',
          currentRate: 18,
        ).dropdownLabel,
        'Standard Tax — 18%',
      );
    });

    test('ZERO_RATED label', () {
      expect(
        const ProductTaxOption(
          id: '2',
          code: 'ZR',
          name: 'Zero Rated',
          taxTreatment: 'ZERO_RATED',
          currentRate: 0,
        ).dropdownLabel,
        'Zero Rated — 0%',
      );
    });

    test('EXEMPT label', () {
      expect(
        const ProductTaxOption(
          id: '3',
          code: 'EX',
          name: 'Tax Exempt',
          taxTreatment: 'EXEMPT',
        ).dropdownLabel,
        'Tax Exempt — Exempt',
      );
    });
  });

  group('TaxPriceMode', () {
    test('maps inclusive exclusive', () {
      expect(TaxPriceMode.parse('INCLUSIVE'), TaxPriceMode.inclusive);
      expect(TaxPriceMode.parse('EXCLUSIVE'), TaxPriceMode.exclusive);
      expect(TaxPriceMode.exclusive.apiValue, 'EXCLUSIVE');
    });
  });
}
