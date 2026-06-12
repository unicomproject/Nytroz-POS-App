import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../presentation/widgets/tenant_admin_page_scaffold.dart';
import '../../../presentation/widgets/tenant_admin_states.dart';
import '../../domain/entities/outlet_details.dart';
import '../providers/outlet_providers.dart';
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
    final managersState = ref.watch(outletManagersProvider);

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
          managers: managersState.maybeWhen(
            data: (managers) => managers,
            orElse: () => const [],
          ),
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
      setState(() => _fieldErrors = _validationErrors(error));
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
    outletType: '',
    mainPhoneNumber: outlet.managerPhone ?? '',
    emailAddress: '',
    addressLine1: outlet.address,
    city: '',
    country: '',
    postalCode: '',
    openingHours: const [],
  );
}

Map<String, String> _validationErrors(DioException error) {
  final data = error.response?.data;
  final errors = data is Map ? data['errors'] : null;

  if (errors is! Map) {
    return const {};
  }

  return errors.map((key, value) {
    final message = value is List && value.isNotEmpty
        ? value.first.toString()
        : value.toString();
    return MapEntry(key.toString(), message);
  });
}
