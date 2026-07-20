import 'package:flutter/material.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

class AddInspectionPhotoButton extends StatelessWidget {
  const AddInspectionPhotoButton({
    super.key,
    required this.onPressed,
  });

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: TenantAdminColors.surface,
          borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
          border: Border.all(
            color: TenantAdminColors.primary.withValues(alpha: 0.35),
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_outlined, color: TenantAdminColors.primary),
            SizedBox(height: 2),
            Text(
              'Add Photo',
              style: TextStyle(
                color: TenantAdminColors.primary,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
