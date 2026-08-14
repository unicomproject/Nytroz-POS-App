import 'package:flutter/material.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/theme/tenant_admin_theme.dart';
import 'package:nytroz_pos/features/tenant_admin/outlets/domain/entities/outlet.dart';

class OutletListTile extends StatelessWidget {
  const OutletListTile({
    super.key,
    required this.outlet,
    required this.isSelected,
    required this.onTap,
  });

  final Outlet outlet;
  final bool isSelected;
  final VoidCallback onTap;

  static const primaryOrange = Color(0xFFFF6A00);

  @override
  Widget build(BuildContext context) {
    final isWarehouse =
        outlet.outletType?.toLowerCase().contains('warehouse') == true ||
            outlet.name.toLowerCase().contains('warehouse');
    final isDefault = outlet.name.toLowerCase().contains('main') ||
        outlet.code.contains('001');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color:
              isSelected ? primaryOrange.withValues(alpha: 0.04) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? primaryOrange : const Color(0xFFF1F5F9),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? primaryOrange : Colors.transparent,
                border: Border.all(
                  color: isSelected ? primaryOrange : const Color(0xFFCBD5E1),
                  width: 1.5,
                ),
              ),
              alignment: Alignment.center,
              child: isSelected
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 10),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isWarehouse
                    ? const Color(0xFFF3E8FF)
                    : const Color(0xFFE0F2FE),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isWarehouse
                    ? Icons.warehouse_outlined
                    : Icons.storefront_outlined,
                size: 16,
                color: isWarehouse
                    ? const Color(0xFF9333EA)
                    : const Color(0xFF0284C7),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          outlet.name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: TenantAdminColors.bodyText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isDefault) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Default',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF16A34A),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${outlet.code.isNotEmpty ? outlet.code : "OUT"} • ${outlet.city ?? (outlet.location.isNotEmpty ? outlet.location : "Colombo")}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isWarehouse
                    ? const Color(0xFFFAF5FF)
                    : const Color(0xFFF0F9FF),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isWarehouse
                      ? const Color(0xFFE9D5FF)
                      : const Color(0xFFBAE6FD),
                ),
              ),
              child: Text(
                isWarehouse ? 'Warehouse' : 'Outlet',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isWarehouse
                      ? const Color(0xFF7E22CE)
                      : const Color(0xFF0369A1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
