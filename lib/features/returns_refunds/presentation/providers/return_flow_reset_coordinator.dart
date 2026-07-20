import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'exchange_replacement_provider.dart';
import 'return_create_credit_provider.dart';
import 'return_eligibility_provider.dart';
import 'return_exchange_flow_provider.dart';
import 'return_flow_provider.dart';
import 'return_inspection_provider.dart';
import 'return_reason_provider.dart';
import 'return_receipt_provider.dart';
import 'return_refund_details_provider.dart';
import 'return_resolution_provider.dart';
import 'return_review_provider.dart';
import 'return_search_provider.dart';
import 'return_settlement_provider.dart';

/// Clears every Return/Exchange draft provider without deleting backend records.
void resetReturnExchangeFlow(Ref ref) {
  ref.read(returnFlowProvider.notifier).reset();
  ref.invalidate(returnSearchProvider);
  ref.invalidate(returnEligibilityProvider);
  ref.invalidate(returnReasonProvider);
  ref.invalidate(returnInspectionProvider);
  ref.invalidate(returnResolutionProvider);
  ref.invalidate(returnCreateCreditProvider);
  ref.invalidate(returnSettlementProvider);
  ref.invalidate(returnReviewProvider);
  ref.invalidate(returnReceiptProvider);
  ref.invalidate(returnRefundDetailsProvider);
  ref.invalidate(exchangeReplacementSearchProvider);
  ref.invalidate(returnExchangeFlowProvider);
}
