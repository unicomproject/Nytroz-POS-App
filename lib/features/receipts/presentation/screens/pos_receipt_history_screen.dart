import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/access/pos_access_codes.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../../device_activation/presentation/providers/device_activation_provider.dart';
import '../../../hardware/receipt_printer/models/completed_sale_receipt.dart';
import '../../../sale/presentation/providers/completed_sale_print_provider.dart';
import '../../domain/receipt_history_models.dart';
import '../providers/receipt_history_provider.dart';

class PosReceiptHistoryScreen extends ConsumerStatefulWidget {
  const PosReceiptHistoryScreen({super.key});

  @override
  ConsumerState<PosReceiptHistoryScreen> createState() =>
      _PosReceiptHistoryScreenState();
}

class _PosReceiptHistoryScreenState
    extends ConsumerState<PosReceiptHistoryScreen> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = ref.watch(receiptSearchProvider(_query));
    final audit = ref.watch(receiptReprintAuditProvider);
    return ColoredBox(
      color: const Color(0xFFF4F6FA),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Receipt History',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    )),
            const SizedBox(height: 12),
            if (audit.pending)
              MaterialBanner(
                content: const Text(
                    'Receipt print audit is pending. Retrying submits audit only and will not print again.'),
                actions: [
                  TextButton(
                    onPressed: audit.submitting
                        ? null
                        : () => ref
                            .read(receiptReprintAuditProvider.notifier)
                            .retryAuditOnly(),
                    child: const Text('Retry audit'),
                  ),
                ],
              ),
            TextField(
              controller: _search,
              textInputAction: TextInputAction.search,
              onSubmitted: (value) => setState(() => _query = value.trim()),
              decoration: InputDecoration(
                hintText: 'Search receipt or sale number',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  tooltip: 'Search',
                  onPressed: () => setState(() => _query = _search.text.trim()),
                  icon: const Icon(Icons.arrow_forward),
                ),
                filled: true,
                fillColor: Colors.white,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: result.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => _ErrorState(
                  onRetry: () => ref.invalidate(receiptSearchProvider(_query)),
                ),
                data: (page) => page.items.isEmpty
                    ? const Center(child: Text('No receipts found.'))
                    : ListView.separated(
                        itemCount: page.items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = page.items[index];
                          return Card(
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Color(0xFFFFE5D9),
                                child: Icon(Icons.receipt_long,
                                    color: Color(0xFFFF5A1F)),
                              ),
                              title: Text(item.receiptNumber,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700)),
                              subtitle: Text(
                                '${item.saleNumber} • ${item.cashierName}\n'
                                '${item.tillName} • ${item.paymentMethod}',
                              ),
                              isThreeLine: true,
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${item.currency} ${item.total.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w800),
                                  ),
                                  Text('${item.reprintCount} reprints'),
                                ],
                              ),
                              onTap: () => _showDetail(item.receiptId),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDetail(String receiptId) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _ReceiptDetailDialog(receiptId: receiptId),
    );
  }
}

class _ReceiptDetailDialog extends ConsumerWidget {
  const _ReceiptDetailDialog({required this.receiptId});
  final String receiptId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(receiptDetailProvider(receiptId));
    final historicalReprint = ref.watch(historicalReprintProvider);
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 760),
        child: detail.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => _ErrorState(
            onRetry: () => ref.invalidate(receiptDetailProvider(receiptId)),
          ),
          data: (receipt) => Column(
            children: [
              ListTile(
                title: Text(receipt.summary.receiptNumber),
                subtitle: Text(
                    '${receipt.summary.type} • ${receipt.summary.outletName} • ${receipt.summary.tillName}'),
                trailing: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    for (final line in receipt.lines)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(line.name),
                        subtitle: Text(
                            '${line.quantity.toStringAsFixed(line.quantity % 1 == 0 ? 0 : 2)} × ${line.unitPrice.toStringAsFixed(2)}'),
                        trailing: Text(line.lineTotal.toStringAsFixed(2)),
                      ),
                    const Divider(),
                    _MoneyRow('Subtotal', receipt.subtotal),
                    _MoneyRow('Discount', receipt.discount),
                    _MoneyRow('Tax', receipt.tax),
                    _MoneyRow('Total', receipt.total, strong: true),
                    _MoneyRow('Paid', receipt.paid),
                    _MoneyRow('Change', receipt.change),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFFF5A1F)),
                    onPressed: historicalReprint.status ==
                            HistoricalReprintStatus.printing
                        ? null
                        : historicalReprint.status ==
                                HistoricalReprintStatus.auditPending
                            ? () => ref
                                .read(historicalReprintProvider.notifier)
                                .retryAuditOnly()
                            : ref.watch(authSessionProvider)?.hasPermission(
                                        PosPermissionCodes.reprintReceipts) ==
                                    true
                                ? () => _requestReprint(context, ref, receipt)
                                : null,
                    icon: const Icon(Icons.print),
                    label: Text(historicalReprint.status ==
                            HistoricalReprintStatus.auditPending
                        ? 'Retry audit only'
                        : historicalReprint.status ==
                                HistoricalReprintStatus.printing
                            ? 'Processing…'
                            : 'Reprint receipt'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _requestReprint(
      BuildContext context, WidgetRef ref, ReceiptDetail receipt) async {
    var reason = ReceiptReprintReasons.values.keys.first;
    final note = TextEditingController();
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Reprint reason'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: reason,
                items: ReceiptReprintReasons.values.entries
                    .map((e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => reason = value!),
              ),
              if (reason == 'OTHER')
                TextField(
                  controller: note,
                  maxLength: 500,
                  decoration: const InputDecoration(labelText: 'Reason note *'),
                ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: reason == 'OTHER' && note.text.trim().isEmpty
                  ? null
                  : () => Navigator.pop(context, true),
              child: const Text('Authorize'),
            ),
          ],
        ),
      ),
    );
    if (approved != true || !context.mounted) return;
    try {
      final operationId =
          await ref.read(receiptRemoteDatasourceProvider).authorizeReprint(
                receiptId: receipt.summary.receiptId,
                reasonCode: reason,
                reasonNote: note.text.trim().isEmpty ? null : note.text.trim(),
              );
      final device = ref.read(deviceActivationProvider).deviceContext;
      if (device == null || device.deviceId.trim().isEmpty) {
        throw StateError('Trusted POS device is unavailable.');
      }
      if (receipt.summary.type.trim().toUpperCase() != 'SALE') {
        await ref.read(historicalReprintProvider.notifier).print(
              detail: receipt,
              reprintOperationId: operationId,
              reasonCode: reason,
              reasonNote: note.text.trim().isEmpty ? null : note.text.trim(),
            );
        final result = ref.read(historicalReprintProvider);
        if (context.mounted) {
          if (result.status == HistoricalReprintStatus.printed) {
            ref.invalidate(receiptDetailProvider(receipt.summary.receiptId));
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result.message ?? 'Receipt reprinted.')),
          );
        }
        return;
      }
      final printReceipt = CompletedSaleReceipt(
        receiptId: receipt.summary.receiptId,
        saleId: receipt.summary.saleId,
        receiptNumber: receipt.summary.receiptNumber,
        completedAt: receipt.summary.issuedAt,
        merchantName: receipt.merchantName?.trim().isNotEmpty == true
            ? receipt.merchantName!
            : receipt.summary.outletName,
        outletName: receipt.summary.outletName,
        tillId: receipt.tillId,
        tillName: receipt.summary.tillName,
        cashierId: receipt.cashierUserId,
        cashierName: receipt.summary.cashierName,
        deviceId: device.deviceId,
        currency: receipt.summary.currency,
        items: receipt.lines
            .map((line) => CompletedSaleReceiptLine(
                  name: line.name,
                  quantity: line.quantity.round(),
                  unitPrice: line.unitPrice.round(),
                  lineTotal: line.lineTotal.round(),
                  variantOrSku: line.sku,
                  saleLineId: line.saleLineId,
                ))
            .toList(growable: false),
        subtotal: receipt.subtotal.round(),
        discountTotal: receipt.discount.round(),
        taxTotal: receipt.tax.round(),
        total: receipt.total.round(),
        paymentMethods: [receipt.summary.paymentMethod],
        amountTendered: receipt.paid.round(),
        change: receipt.change.round(),
        barcodeValue: receipt.summary.receiptNumber,
        footerLines: [
          'REPRINT',
          'Original receipt: ${receipt.summary.receiptNumber}',
          'Copy time: ${DateTime.now().toLocal().toIso8601String()}',
        ],
        tenders: receipt.tenders
            .map((line) => CompletedSaleTender(
                  methodCode: line.methodCode,
                  methodName: line.methodName,
                  methodType: line.methodType,
                  amount: line.amount,
                  amountTendered: line.amountTendered,
                  changeAmount: line.changeAmount,
                  currency: line.currency,
                  status: line.status,
                  providerName: line.providerName,
                  cardBrand: line.cardBrand,
                  maskedCardLast4: line.maskedCardLast4,
                  authorizationReference: line.authorizationReference,
                  terminalReference: line.terminalReference,
                ))
            .toList(growable: false),
        discountLines: receipt.discountLines
            .map((line) => CompletedSaleDiscount(
                  scope: line.scope,
                  saleLineId: line.saleLineId,
                  name: line.name,
                  code: line.code,
                  promotionReference: line.promotionReference,
                  amount: line.amount,
                ))
            .toList(growable: false),
        taxLines: receipt.taxLines
            .map((line) => CompletedSaleTax(
                  taxCode: line.taxCode,
                  taxName: line.taxName,
                  rate: line.rate,
                  taxableAmount: line.taxableAmount,
                  taxAmount: line.taxAmount,
                ))
            .toList(growable: false),
        copyPolicy: CompletedSaleCopyPolicy(
          customerCopyCount: receipt.copyPolicy.customerCopyCount,
          merchantCopyCount: receipt.copyPolicy.merchantCopyCount,
          printCustomerCopy: receipt.copyPolicy.printCustomerCopy,
          printMerchantCopy: receipt.copyPolicy.printMerchantCopy,
          terminalSlipExpected: receipt.copyPolicy.terminalSlipExpected,
          terminalSlipPrintedByExternalTerminal:
              receipt.copyPolicy.terminalSlipPrintedByExternalTerminal,
        ),
        taxRegistrationNumber: receipt.taxRegistrationNumber,
        taxInvoiceLabel: receipt.taxInvoiceLabel,
        isReprint: true,
      );
      await ref
          .read(completedSalePrintProvider.notifier)
          .printAuthorizedReprint(
            receipt: printReceipt,
            reprintOperationId: operationId,
            reasonCode: reason,
            reasonNote: note.text.trim().isEmpty ? null : note.text.trim(),
          );
      final printState = ref.read(completedSalePrintProvider);
      if (printState.status != CompletedSalePrintStatus.printed ||
          printState.auditPending) {
        throw StateError(printState.message ?? 'Receipt reprint failed.');
      }
      if (context.mounted) {
        ref.invalidate(receiptDetailProvider(receipt.summary.receiptId));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Receipt reprinted and audited.')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        final historical = ref.read(historicalReprintProvider);
        final message = receipt.summary.type.trim().toUpperCase() == 'SALE'
            ? 'Reprint authorization or printing failed.'
            : historical.message ?? 'Historical receipt reprint failed.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } finally {
      note.dispose();
    }
  }
}

class _MoneyRow extends StatelessWidget {
  const _MoneyRow(this.label, this.value, {this.strong = false});
  final String label;
  final double value;
  final bool strong;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: strong
                    ? const TextStyle(fontWeight: FontWeight.w800)
                    : null),
            Text(value.toStringAsFixed(2),
                style: strong
                    ? const TextStyle(fontWeight: FontWeight.w800)
                    : null),
          ],
        ),
      );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Receipts are unavailable.'),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      );
}
