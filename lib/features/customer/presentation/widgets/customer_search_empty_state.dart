import 'package:flutter/material.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/theme/tenant_admin_theme.dart';

/// Shown in the Add Customer dialog when a search returns no matches. Offers a
/// shortcut to the Quick Add New Customer form.
class CustomerSearchEmptyState extends StatelessWidget {
  const CustomerSearchEmptyState({super.key, this.onAddNew});

  final VoidCallback? onAddNew;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(TenantAdminSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: TenantAdminColors.secondary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_search_outlined,
              size: 28,
              color: TenantAdminColors.info,
            ),
          ),
          const SizedBox(height: TenantAdminSpacing.md),
          Text(
            'No customer found',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: TenantAdminColors.bodyText,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: TenantAdminSpacing.xs),
          Text(
            "We couldn't find any matches for the searched phone/name.",
            textAlign: TextAlign.center,
            style: TenantAdminTextStyles.muted(context),
          ),
          if (onAddNew != null) ...[
            const SizedBox(height: TenantAdminSpacing.md),
            TextButton.icon(
              onPressed: onAddNew,
              icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
              label: const Text('Add New Customer'),
              style: TextButton.styleFrom(
                foregroundColor: TenantAdminColors.info,
                textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
