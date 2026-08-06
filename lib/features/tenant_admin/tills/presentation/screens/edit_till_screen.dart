import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../auth/presentation/providers/session_provider.dart';
import '../../../presentation/widgets/tenant_admin_page_scaffold.dart';
import '../../../presentation/widgets/tenant_admin_states.dart';
import '../../domain/entities/till.dart';
import '../providers/till_providers.dart';
import '../providers/till_visibility_provider.dart';
import '../utils/till_api_errors.dart';
import '../widgets/till_form.dart';

class EditTillScreen extends ConsumerStatefulWidget {
  const EditTillScreen({
    super.key,
    required this.tillId,
  });

  final String tillId;

  @override
  ConsumerState<EditTillScreen> createState() => _EditTillScreenState();
}

class _EditTillScreenState extends ConsumerState<EditTillScreen> {
  var _submitting = false;
  Map<String, String> _fieldErrors = const {};

  @override
  Widget build(BuildContext context) {
    final canUpdate = ref.watch(tillUpdateAccessProvider);

    if (!canUpdate) {
      return const TenantAdminPageScaffold(
        title: 'No access',
        child: TenantAdminEmptyState(
          title: 'No access',
          message: 'You do not have permission to edit tills.',
        ),
      );
    }

    final detailState = ref.watch(tillDetailProvider(widget.tillId));
    final outletsState = ref.watch(tillOutletOptionsProvider);
    final canViewHardware = ref.watch(tillHardwareViewAccessProvider);
    final canManageHardware = ref.watch(tillHardwareManageAccessProvider);

    return detailState.when(
      loading: () => const TenantAdminPageScaffold(
        title: 'Edit till',
        subtitle: 'Update till details.',
        child: TenantAdminLoadingSkeleton(rowCount: 8),
      ),
      error: (error, stackTrace) => TenantAdminPageScaffold(
        title: 'Edit till',
        subtitle: 'Update till details.',
        child: TenantAdminErrorState(
          title: 'Unable to load till',
          message: 'Please try again.',
          onRetry: () => ref.invalidate(tillDetailProvider(widget.tillId)),
        ),
      ),
      data: (detail) {
        if (detail == null) {
          return const TenantAdminPageScaffold(
            title: 'Edit till',
            child: TenantAdminEmptyState(
              title: 'Till not found',
              message: 'This till could not be found.',
            ),
          );
        }

        return TenantAdminPageScaffold(
          title: 'Edit till',
          subtitle: 'Update till details.',
          child: outletsState.when(
            loading: () => const TenantAdminLoadingSkeleton(rowCount: 4),
            error: (error, stackTrace) => TenantAdminErrorState(
              title: 'Unable to load outlets',
              message: 'Please try again.',
              onRetry: () => ref.invalidate(tillOutletOptionsProvider),
            ),
            data: (outlets) {
              if (outlets.isEmpty) {
                return const TenantAdminEmptyState(
                  title: 'No outlets available',
                  message: 'No outlets are available for this till.',
                );
              }

              return TillForm(
                outlets: outlets,
                initialValue: detail.toFormData(),
                submitLabel: 'Save changes',
                showHardwareSection: canViewHardware,
                hardwareReadOnly: !canManageHardware,
                backendErrors: _fieldErrors,
                submitting: _submitting,
                onSubmit: (form) => _submit(form),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _submit(TillFormData form) async {
    setState(() {
      _submitting = true;
      _fieldErrors = const {};
    });

    try {
      await ref.read(updateTillProvider).call(
            id: widget.tillId,
            form: form,
          );

      ref
        ..invalidate(tillListResultFutureProvider)
        ..invalidate(tillDetailProvider(widget.tillId));

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Till updated successfully.')),
      );
      context.go('/tenant-admin/tills/${widget.tillId}');
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
      final duplicateCode = error.response?.statusCode == 409 &&
          (error.response?.data is Map) &&
          (error.response?.data as Map)['code'] == 'till.duplicate_code';

      setState(() {
        _fieldErrors = duplicateCode
            ? {
                ...fieldErrors,
                'code': tillSubmitErrorMessage(
                  error,
                  fieldErrors,
                  fallback: 'Till code already exists for this tenant.',
                ),
              }
            : fieldErrors;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              tillSubmitErrorMessage(
                error,
                fieldErrors,
                fallback: 'Failed to update till',
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
