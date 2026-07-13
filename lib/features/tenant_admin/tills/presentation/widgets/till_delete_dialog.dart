import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_buttons.dart';
import '../../domain/entities/till.dart';
import '../providers/till_providers.dart';
import '../providers/till_visibility_provider.dart';
import 'till_action_menu.dart';

class TillDeleteDialog extends StatefulWidget {
  const TillDeleteDialog({
    super.key,
    required this.till,
    this.onDeleted,
  });

  final Till till;
  final VoidCallback? onDeleted;

  static Future<void> show({
    required BuildContext context,
    required WidgetRef ref,
    required Till till,
    VoidCallback? onDeleted,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => TillDeleteDialog(
        till: till,
        onDeleted: onDeleted,
      ),
    );
  }

  @override
  State<TillDeleteDialog> createState() => _TillDeleteDialogState();
}

class _TillDeleteDialogState extends State<TillDeleteDialog> {
  var _submitting = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Deactivate till'),
      content: Text(
        'Deactivate ${widget.till.name} (${widget.till.code})? '
        'This till will no longer be available for use.',
      ),
      actions: [
        TenantAdminSecondaryButton(
          label: 'Cancel',
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
        ),
        const SizedBox(width: TenantAdminSpacing.sm),
        TenantAdminPrimaryButton(
          label: 'Deactivate',
          icon: Icons.delete_outline,
          loading: _submitting,
          onPressed: _submitting ? null : _deactivate,
        ),
      ],
    );
  }

  Future<void> _deactivate() async {
    setState(() => _submitting = true);

    try {
      final container = ProviderScope.containerOf(context, listen: false);
      await container.read(deleteTillProvider).call(widget.till.id);
      container
        ..invalidate(tillListProvider)
        ..invalidate(tillDetailProvider(widget.till.id));

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop();
      widget.onDeleted?.call();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${widget.till.name} was deactivated.')),
        );
        context.go('/tenant-admin/tills');
      }
    } on DioException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tillDeleteErrorMessage(error))),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tillDeleteErrorMessage(error))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }
}
