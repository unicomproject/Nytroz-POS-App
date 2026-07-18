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

class EditOutletScreen extends ConsumerStatefulWidget {
  const EditOutletScreen({
    super.key,
    required this.outletId,
  });

  final String outletId;

  @override
  ConsumerState<EditOutletScreen> createState() => _EditOutletScreenState();
}

class _EditOutletScreenState extends ConsumerState<EditOutletScreen> {
  var _submitting = false;
  Map<String, String> _fieldErrors = const {};

  @override
  Widget build(BuildContext context) {
    final detailsState = ref.watch(outletDetailsProvider(widget.outletId));
    final optionsState = ref.watch(outletCreateOptionsProvider);

    if (detailsState.isLoading || optionsState.isLoading) {
      return const TenantAdminPageScaffold(
        title: 'Edit outlet',
        subtitle: 'Update outlet details.',
        child: TenantAdminLoadingSkeleton(rowCount: 8),
      );
    }

    final error = detailsState.error ?? optionsState.error;
    if (error != null) {
      return TenantAdminPageScaffold(
        title: 'Edit outlet',
        subtitle: 'Update outlet details.',
        child: TenantAdminErrorState(
          title: 'Unable to load outlet',
          message: 'Please try again.',
          onRetry: () {
            ref.invalidate(outletDetailsProvider(widget.outletId));
            ref.invalidate(outletCreateOptionsProvider);
          },
        ),
      );
    }

    return detailsState.when(
      loading: () => const TenantAdminPageScaffold(
        title: 'Edit outlet',
        subtitle: 'Update outlet details.',
        child: TenantAdminLoadingSkeleton(rowCount: 8),
      ),
      error: (error, stackTrace) => TenantAdminPageScaffold(
        title: 'Edit outlet',
        subtitle: 'Update outlet details.',
        child: TenantAdminErrorState(
          title: 'Unable to load outlet',
          message: 'Please try again.',
          onRetry: () {
            ref
                .refresh(outletDetailsProvider(widget.outletId))
                .maybeWhen(orElse: () {});
          },
        ),
      ),
      data: (outlet) => TenantAdminPageScaffold(
        title: 'Edit outlet',
        subtitle: 'Update outlet details.',
        child: OutletForm(
          initialValue: _initialForm(outlet),
          createOptions: optionsState.value,
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
      final outlet =
          await ref.read(updateOutletProvider).call(widget.outletId, form);
      ref.refresh(outletListProvider).maybeWhen(orElse: () {});
      ref
          .refresh(outletDetailsProvider(widget.outletId))
          .maybeWhen(orElse: () {});
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
                fallback: 'Failed to update outlet',
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

OutletFormData _initialForm(OutletDetails outlet) {
  return OutletFormData(
    outletName: outlet.name,
    outletCode: outlet.code,
    outletType: outlet.outletType ?? 'STORE',
    status: outlet.status,
    mainPhoneNumber: outlet.phone ?? outlet.managerPhone ?? '',
    emailAddress: outlet.email ?? '',
    isDefaultOutlet: outlet.isDefaultOutlet,
    addressLine1: outlet.addressLine1 ?? outlet.address,
    addressLine2: outlet.addressLine2,
    city: outlet.city ?? '',
    state: outlet.state,
    country: outlet.countryCode ?? '',
    postalCode: outlet.postalCode ?? '',
    timezone: outlet.timezone ?? 'UTC',
    openingHours: outlet.businessHours,
  );
}
