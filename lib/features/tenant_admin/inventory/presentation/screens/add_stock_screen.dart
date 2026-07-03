import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../auth/presentation/providers/session_provider.dart';
import '../../../presentation/widgets/tenant_admin_page_scaffold.dart';
import '../../../presentation/widgets/tenant_admin_states.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../../domain/entities/inventory.dart';
import '../providers/inventory_providers.dart';
import '../providers/inventory_visibility_provider.dart';
import '../utils/inventory_api_errors.dart';
import '../widgets/add_stock_form.dart';
import '../widgets/inventory_form_widgets.dart';

class AddStockScreen extends ConsumerStatefulWidget {
  const AddStockScreen({super.key});

  @override
  ConsumerState<AddStockScreen> createState() => _AddStockScreenState();
}

class _AddStockScreenState extends ConsumerState<AddStockScreen> {
  final _formKey = GlobalKey<AddStockFormState>();
  bool _submitting = false;
  Map<String, String> _fieldErrors = const {};
  String? _bannerError;

  Future<void> _handleSave() async {
    final submitted = await _formKey.currentState?.submit() ?? false;
    if (!submitted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in the required fields.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(authHeaderSyncProvider);
    final visibilityState = ref.watch(addStockVisibilityProvider);

    return visibilityState.when(
      loading: () => const TenantAdminPageScaffold(
        title: 'Add Stock (Stock In)',
        subtitle: 'Add new stock to your inventory.',
        child: TenantAdminLoadingSkeleton(rowCount: 8),
      ),
      error: (error, stackTrace) => TenantAdminPageScaffold(
        title: 'Add Stock (Stock In)',
        subtitle: 'Add new stock to your inventory.',
        child: TenantAdminErrorState(
          title: 'Unable to load permissions',
          message: 'Please try again.',
          onRetry: () => ref.invalidate(addStockVisibilityProvider),
        ),
      ),
      data: (visibility) {
        if (!visibility.showPage) {
          return const TenantAdminPageScaffold(
            title: 'Add Stock (Stock In)',
            subtitle: 'Add new stock to your inventory.',
            child: TenantAdminEmptyState(
              title: 'Permission denied',
              message:
                  'You do not have permission to adjust stock (inventory.stock.adjust).',
            ),
          );
        }

        return TenantAdminPageScaffold(
          title: 'Add Stock (Stock In)',
          subtitle: 'Add new stock to your inventory.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_bannerError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: InventoryApiBanner(message: _bannerError!),
                ),
              AddStockForm(
                key: _formKey,
                visibility: visibility,
                backendErrors: _fieldErrors,
                submitting: _submitting,
                onCancel: () => context.go('/tenant-admin/stock/current'),
                onSave: _handleSave,
                onSubmit: _submit,
              ),
            ],
          ),
        );
      },
    );
  }

  Future<bool> _submit(StockInFormData data) async {
    setState(() {
      _submitting = true;
      _fieldErrors = const {};
      _bannerError = null;
    });

    try {
      await ref.read(inventoryRepositoryProvider).submitStockIn(data);

      ref.invalidate(inventoryBalancesProvider);

      if (!mounted) {
        return true;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Stock added successfully.'),
        ),
      );

      context.go('/tenant-admin/stock/current');
      return true;
    } on InventoryApiUnavailable catch (error) {
      if (!mounted) {
        return false;
      }

      setState(() {
        _bannerError = inventoryLoadErrorMessage(error);
      });
      return false;
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        await ref.read(authSessionProvider.notifier).clear();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Your session has expired. Please sign in again.'),
            ),
          );
        }
        return false;
      }

      final fieldErrors = inventoryValidationErrors(error);
      if (!mounted) {
        return false;
      }

      setState(() {
        _fieldErrors = fieldErrors;
        _bannerError = inventorySubmitErrorMessage(
          error,
          fieldErrors,
        );
      });
      return false;
    } catch (_) {
      if (!mounted) {
        return false;
      }

      setState(() {
        _bannerError = 'Failed to save stock. Please try again.';
      });
      return false;
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }
}
