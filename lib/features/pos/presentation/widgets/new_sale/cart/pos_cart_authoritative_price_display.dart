import 'package:flutter/material.dart';

import '../../../../../sale/domain/entities/pos_checkout_summary.dart';
import '../../../../../sale/presentation/providers/pos_checkout_summary_provider.dart';
import '../../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

class PosCartAuthoritativeUnitPriceDisplay extends StatelessWidget {
  const PosCartAuthoritativeUnitPriceDisplay({
    required this.catalogUnitPrice,
    required this.currency,
    required this.isAuthoritative,
    this.linePricing,
    super.key,
  });

  final int catalogUnitPrice;
  final String currency;
  final bool isAuthoritative;
  final PosCalculatedCartLinePayload? linePricing;

  @override
  Widget build(BuildContext context) {
    final pricing = isAuthoritative ? linePricing : null;
    if (pricing == null) {
      return Text(
        formatCheckoutMoney(currency, catalogUnitPrice),
        textAlign: TextAlign.right,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Color(0xFF2563EB),
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      );
    }

    if (pricing.hasMeaningfulEffectiveUnitPrice) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            formatCheckoutMoney(currency, pricing.effectiveUnitPrice!),
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: TenantAdminColors.posHomeAccentOrange,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          Text(
            formatCheckoutMoney(currency, pricing.baseUnitPrice!),
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: TenantAdminColors.mutedText,
                  decoration: TextDecoration.lineThrough,
                  fontSize: 11,
                ),
          ),
        ],
      );
    }

    if (pricing.hasAutomaticPromotion) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            formatCheckoutMoney(currency, pricing.unitPrice),
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF2563EB),
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      );
    }

    return Text(
      formatCheckoutMoney(currency, pricing.unitPrice),
      textAlign: TextAlign.right,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: Color(0xFF2563EB),
        fontWeight: FontWeight.w700,
        fontSize: 13,
      ),
    );
  }
}

class PosCartAuthoritativeLineTotalDisplay extends StatelessWidget {
  const PosCartAuthoritativeLineTotalDisplay({
    required this.catalogLineTotal,
    required this.currency,
    required this.isAuthoritative,
    this.linePricing,
    super.key,
  });

  final int catalogLineTotal;
  final String currency;
  final bool isAuthoritative;
  final PosCalculatedCartLinePayload? linePricing;

  @override
  Widget build(BuildContext context) {
    if (!isAuthoritative || linePricing == null) {
      return Text(
        '—',
        textAlign: TextAlign.right,
        maxLines: 1,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: TenantAdminColors.mutedText,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
      );
    }

    return Text(
      formatCheckoutMoney(currency, linePricing!.lineTotal),
      textAlign: TextAlign.right,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: TenantAdminColors.bodyText,
        fontWeight: FontWeight.w900,
        fontSize: 13,
      ),
    );
  }
}
