import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../sale/domain/entities/pos_customer.dart';
import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../../shared/presentation/app_modal.dart';
import '../providers/customers_provider.dart';

Future<void> showPosCustomerPurchaseHistoryDialog({
  required BuildContext context,
  required WidgetRef ref,
  required PosCustomer customer,
}) {
  final container = ProviderScope.containerOf(context, listen: false);

  return showAppDialog<void>(
    context: context,
    builder: (_) => UncontrolledProviderScope(
      container: container,
      child: _PosCustomerPurchaseHistoryDialog(customer: customer),
    ),
  );
}

class _PosCustomerPurchaseHistoryDialog extends ConsumerStatefulWidget {
  const _PosCustomerPurchaseHistoryDialog({required this.customer});

  final PosCustomer customer;

  @override
  ConsumerState<_PosCustomerPurchaseHistoryDialog> createState() =>
      _PosCustomerPurchaseHistoryDialogState();
}

class _PosCustomerPurchaseHistoryDialogState
    extends ConsumerState<_PosCustomerPurchaseHistoryDialog> {
  static const _pageSize = 20;

  final List<PosCustomerOrder> _orders = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;
  int _page = 1;
  int _totalPages = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadInitial);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Dialog(
        backgroundColor: TenantAdminColors.surface,
        surfaceTintColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(TenantAdminSpacing.lg),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640, maxHeight: 720),
          child: Padding(
            padding: const EdgeInsets.all(TenantAdminSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Purchase History',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  color: TenantAdminColors.bodyText,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.customer.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: TenantAdminColors.mutedText,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: TenantAdminSpacing.lg),
                Expanded(child: _buildBody(context)),
                if (_canLoadMore) ...[
                  const SizedBox(height: TenantAdminSpacing.md),
                  OutlinedButton(
                    onPressed: _isLoadingMore ? null : _loadMore,
                    child: _isLoadingMore
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Load More'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool get _canLoadMore =>
      !_isLoading &&
      _errorMessage == null &&
      _totalPages > 0 &&
      _page < _totalPages;

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: TenantAdminColors.mutedText,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: TenantAdminSpacing.md),
            TextButton(
              onPressed: _loadInitial,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_orders.isEmpty) {
      return const Center(
        child: Text(
          'No purchase history for this customer.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: TenantAdminColors.mutedText,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: _orders.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final order = _orders[index];
        final amount = order.totalAmount;
        final amountLabel = amount == null
            ? '—'
            : (order.currencyCode.trim().isEmpty
                ? amount.toStringAsFixed(2)
                : '${order.currencyCode} ${amount.toStringAsFixed(2)}');
        final date = order.orderDate == null
            ? '—'
            : '${order.orderDate!.year}-${order.orderDate!.month.toString().padLeft(2, '0')}-${order.orderDate!.day.toString().padLeft(2, '0')}';

        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            order.orderNumber,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: Text(
            '$date · ${order.status}',
            style: const TextStyle(
              color: TenantAdminColors.mutedText,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          trailing: Text(
            amountLabel,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        );
      },
    );
  }

  Future<void> _loadInitial() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _orders.clear();
      _page = 1;
      _totalPages = 0;
    });

    try {
      final page =
          await ref.read(customersProvider.notifier).loadPurchaseHistory(
                customerId: widget.customer.customerId,
                page: 1,
                pageSize: _pageSize,
              );

      if (!mounted) {
        return;
      }

      if (page == null) {
        setState(() {
          _errorMessage = 'Unable to load purchase history.';
        });
        return;
      }

      setState(() {
        _orders
          ..clear()
          ..addAll(page.items);
        _page = page.page;
        _totalPages = page.totalPages;
      });
    } on DioException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.response?.statusCode == 403
            ? 'Permission Denied'
            : _mapError(error);
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = 'Unable to load purchase history.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_canLoadMore) {
      return;
    }

    setState(() => _isLoadingMore = true);

    try {
      final nextPage = _page + 1;
      final page =
          await ref.read(customersProvider.notifier).loadPurchaseHistory(
                customerId: widget.customer.customerId,
                page: nextPage,
                pageSize: _pageSize,
              );

      if (!mounted || page == null) {
        return;
      }

      setState(() {
        _orders.addAll(page.items);
        _page = page.page;
        _totalPages = page.totalPages;
      });
    } on DioException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.response?.statusCode == 403
                ? 'Permission Denied'
                : _mapError(error),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to load more orders.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  String _mapError(DioException error) {
    final data = error.response?.data;
    if (data is Map) {
      final message = data['message']?.toString() ??
          data['Message']?.toString() ??
          data['title']?.toString();
      if (message != null && message.trim().isNotEmpty) {
        return message.trim();
      }
    }
    return 'Unable to load purchase history.';
  }
}
