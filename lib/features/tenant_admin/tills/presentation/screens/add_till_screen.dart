import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../auth/presentation/providers/session_provider.dart';
import '../../../domain/entities/tenant_admin_context.dart';
import '../../../outlets/domain/entities/outlet.dart';
import '../../../outlets/domain/entities/outlet_list_query.dart';
import '../../../outlets/presentation/providers/outlet_providers.dart';
import '../../../presentation/providers/tenant_admin_context_provider.dart';
import '../../../presentation/widgets/tenant_admin_page_scaffold.dart';
import '../../../presentation/widgets/tenant_admin_states.dart';
import '../../domain/entities/till.dart';
import '../providers/till_providers.dart';
import '../providers/till_visibility_provider.dart';
import '../utils/till_api_errors.dart';
import '../widgets/till_form.dart' show TillForm;

class AddTillScreen extends ConsumerStatefulWidget {
  const AddTillScreen({super.key});

  @override
  ConsumerState<AddTillScreen> createState() => _AddTillScreenState();
}

class _AddTillScreenState extends ConsumerState<AddTillScreen> {
  var _submitting = false;
  Map<String, String> _fieldErrors = const {};

  @override
  Widget build(BuildContext context) {
    ref.watch(authHeaderSyncProvider);
    final canCreate = ref.watch(tillCreateAccessProvider);
    final outletsState = ref.watch(tillOutletOptionsProvider);

    if (!canCreate) {
      return const TenantAdminPageScaffold(
        title: 'No access',
        child: TenantAdminEmptyState(
          title: 'No access',
          message: 'You do not have permission to create tills.',
        ),
      );
    }

    return TenantAdminPageScaffold(
      title: 'Add till',
      subtitle: 'Enter the details for the new till.',
      child: outletsState.when(
        loading: () => const TenantAdminLoadingSkeleton(rowCount: 4),
        error: (error, stackTrace) => TenantAdminErrorState(
          title: 'Unable to load outlets',
          message: _outletLoadErrorMessage(error),
          onRetry: () => ref.invalidate(tillOutletOptionsProvider),
        ),
        data: (outlets) {
          if (outlets.isEmpty) {
            return const TenantAdminEmptyState(
              title: 'No outlets available',
              message: 'Create an outlet before adding a till.',
            );
          }

          return TillForm(
            outlets: outlets,
            backendErrors: _fieldErrors,
            submitting: _submitting,
            onSubmit: _submit,
          );
        },
      ),
    );
  }

  String _outletLoadErrorMessage(Object error) {
    if (error is DioException && error.response?.statusCode == 401) {
      return 'Your session has expired. Please sign in again.';
    }

    return 'Please try again.';
  }

  Future<void> _submit(TillFormData form) async {
    setState(() {
      _submitting = true;
      _fieldErrors = const {};
    });

    try {
      await ref.read(createTillProvider).call(
            TillFormData(
              name: form.name,
              code: form.code,
              outletId: form.outletId,
              status: form.status,
            ),
          );
      ref.invalidate(tillListProvider);
      if (!mounted) {
        return;
      }
      context.go('/tenant-admin/tills');
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        await ref.read(authSessionProvider.notifier).clear();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Your session has expired. Please sign in again.'),
            ),
          );
          context.go('/tenant-login');
        }
        return;
      }

      final fieldErrors = tillValidationErrors(error);
      setState(() => _fieldErrors = fieldErrors);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              tillSubmitErrorMessage(
                error,
                fieldErrors,
                fallback: 'Failed to create till',
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }
}

final tillOutletOptionsProvider = FutureProvider<List<Outlet>>((ref) async {
  ref.watch(authHeaderSyncProvider);

  final context = await ref.watch(tenantAdminContextProvider.future);
  final scopedOutlets = _outletsFromContext(context);

  try {
    final result = await ref.read(getOutletsProvider).call(
          query: const OutletListQuery(page: 1, pageSize: 100),
        );

    if (result.items.isNotEmpty) {
      return result.items;
    }
  } on DioException catch (error) {
    if (error.response?.statusCode == 401) {
      rethrow;
    }
  }

  if (scopedOutlets.isEmpty) {
    throw StateError('No outlets are available for this tenant.');
  }

  return scopedOutlets;
});

List<Outlet> _outletsFromContext(TenantAdminContext context) {
  return context.outletScope
      .map(
        (scope) => Outlet(
          id: scope.outletId,
          name: scope.outletName,
          code: '',
          location: '',
          status: 'active',
          tillCount: 0,
          onlineTillCount: 0,
          staffCount: 0,
          todaysSales: '',
        ),
      )
      .toList(growable: false);
}
