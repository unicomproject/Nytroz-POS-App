import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../presentation/providers/tenant_admin_access_provider.dart';
import '../../../presentation/widgets/tenant_admin_page_scaffold.dart';
import '../../../presentation/widgets/tenant_admin_states.dart';
import '../../domain/entities/till.dart';
import '../providers/till_providers.dart';
import '../providers/till_visibility_provider.dart';
import '../utils/till_api_errors.dart';
import '../widgets/till_form.dart';

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
    final accessState = ref.watch(tenantAdminAccessCheckerProvider);
    final outletsState = ref.watch(tillOutletOptionsProvider);

    return accessState.when(
      loading: () => const TenantAdminPageScaffold(
        title: 'Add till',
        child: TenantAdminLoadingSkeleton(rowCount: 4),
      ),
      error: (error, stackTrace) => TenantAdminPageScaffold(
        title: 'Add till',
        child: TenantAdminErrorState(
          title: 'Unable to load access',
          message: 'Please try again.',
          onRetry: () => ref.invalidate(tenantAdminAccessCheckerProvider),
        ),
      ),
      data: (access) {
        if (!access.canCreateTill()) {
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
          subtitle: 'Create a till for an outlet.',
          child: outletsState.when(
            loading: () => const TenantAdminLoadingSkeleton(rowCount: 4),
            error: (error, stackTrace) => TillForm(
              outletOptions: const [],
              backendErrors: _fieldErrors,
              submitting: _submitting,
              onSubmit: _submit,
            ),
            data: (options) => TillForm(
              outletOptions: options
                  .map(
                    (option) => TillFormOutletOption(
                      id: option.id,
                      label: '${option.name} (${option.code})',
                    ),
                  )
                  .toList(growable: false),
              backendErrors: _fieldErrors,
              submitting: _submitting,
              onSubmit: _submit,
            ),
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
      await ref.read(createTillProvider).call(
            CreateTillInput(
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
