import 'package:flutter/material.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/theme/tenant_admin_theme.dart';

class ProductUploadMoreTile extends StatelessWidget {
  const ProductUploadMoreTile({
    super.key,
    required this.onTap,
    required this.disabled,
  });

  final VoidCallback onTap;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: disabled ? 'Maximum 10 product images allowed' : 'Upload image',
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
        child: Container(
          decoration: BoxDecoration(
            color: disabled ? const Color(0xFFF1F5F9) : const Color(0xFFFAFAFA),
            borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
            border: Border.all(
              color: disabled
                  ? const Color(0xFFE2E8F0)
                  : TenantAdminColors.posHomeAccentOrange,
              style: BorderStyle.solid,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_photo_alternate_outlined,
                color: disabled
                    ? const Color(0xFF94A3B8)
                    : TenantAdminColors.posHomeAccentOrange,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                'Upload More',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: disabled
                      ? const Color(0xFF94A3B8)
                      : TenantAdminColors.posHomeAccentOrange,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'PNG, JPG ≤ 5MB',
                style: TextStyle(
                  fontSize: 9,
                  color: TenantAdminColors.mutedText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
