import 'package:flutter/material.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../domain/entities/return_resolution_type.dart';

class ReturnResolutionOptionCard extends StatelessWidget {
  const ReturnResolutionOptionCard({
    super.key,
    required this.type,
    required this.title,
    required this.description,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.enabled = true,
  });

  final ReturnResolutionType type;
  final String title;
  final String description;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: title,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
          child: Opacity(
            opacity: enabled ? 1 : 0.45,
            child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 220),
            padding: const EdgeInsets.all(TenantAdminSpacing.xl),
            decoration: BoxDecoration(
              color: TenantAdminColors.surface,
              borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
              border: Border.all(
                color: selected
                    ? TenantAdminColors.primary
                    : TenantAdminColors.border,
                width: selected ? 2 : 1,
              ),
              boxShadow: selected ? TenantAdminShadows.card : null,
            ),
            child: Stack(
              children: [
                if (selected)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: TenantAdminColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: TenantAdminColors.primary.withValues(alpha: 0.08),
                        borderRadius:
                            BorderRadius.circular(TenantAdminRadius.md),
                      ),
                      child: Icon(
                        icon,
                        color: TenantAdminColors.primary,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: TenantAdminSpacing.lg),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: TenantAdminSpacing.sm),
                    Text(
                      description,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: TenantAdminColors.mutedText,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                    ),
                  ],
                ),
              ],
            ),
            ),
          ),
        ),
      ),
    );
  }
}
