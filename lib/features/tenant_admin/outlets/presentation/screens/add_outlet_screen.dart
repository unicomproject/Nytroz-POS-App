import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../presentation/widgets/tenant_admin_page_scaffold.dart';
import '../../../presentation/widgets/tenant_admin_states.dart';
import '../../domain/entities/outlet_details.dart';
import '../providers/outlet_providers.dart';
import '../providers/outlet_visibility_provider.dart';
import '../utils/outlet_api_errors.dart';
import '../widgets/outlet_form.dart';

class AddOutletScreen extends ConsumerStatefulWidget {
  const AddOutletScreen({super.key});

  @override
  ConsumerState<AddOutletScreen> createState() => _AddOutletScreenState();
}

class _AddOutletScreenState extends ConsumerState<AddOutletScreen> {
  var _submitting = false;
  Map<String, String> _fieldErrors = const {};

  @override
  Widget build(BuildContext context) {
    final managersState = ref.watch(outletManagersProvider);

    return TenantAdminPageScaffold(
      title: 'Add outlet',
      subtitle: 'Enter the main details for the new outlet.',
      child: managersState.when(
        loading: () => const TenantAdminLoadingSkeleton(rowCount: 4),
        error: (error, stackTrace) => OutletForm(
          managers: const [],
          backendErrors: _fieldErrors,
          submitting: _submitting,
          onSubmit: _submit,
        ),
        data: (managers) => OutletForm(
          managers: managers,
          backendErrors: _fieldErrors,
          submitting: _submitting,
          onSubmit: _submit,
        ),
      ),
    );
  }

  Future<void> _submit(OutletFormData form) async {
    setState(() {
      _submitting = true;
      _fieldErrors = const {};
    });

    try {
      final outlet = await ref.read(createOutletProvider).call(form);
      ref.refresh(outletListProvider).maybeWhen(orElse: () {});
      if (!mounted) {
        return;
      }
      context.go('/tenant-admin/outlets/${outlet.id}');
    } on DioException catch (error) {
      final fieldErrors = outletValidationErrors(error);
      setState(() => _fieldErrors = fieldErrors);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              outletSubmitErrorMessage(
                error,
                fieldErrors,
                fallback: 'Failed to create outlet',
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
