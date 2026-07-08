import '../../data/models/outlet_detail_dtos.dart';

class OutletDetail {
  const OutletDetail({
    required this.outletId,
    required this.outletName,
    required this.outletCode,
    required this.outletType,
    required this.status,
    this.addressLine1,
    this.addressLine2,
    this.city,
    this.districtOrProvince,
    this.postalCode,
    this.phoneNumber,
    this.emailAddress,
    this.managerName,
    this.operatingHours,
    this.openingDate,
    this.taxRegistrationId,
    this.notes,
  });

  final String outletId;
  final String outletName;
  final String outletCode;
  final String outletType;
  final String status;
  final String? addressLine1;
  final String? addressLine2;
  final String? city;
  final String? districtOrProvince;
  final String? postalCode;
  final String? phoneNumber;
  final String? emailAddress;
  final String? managerName;
  final String? operatingHours;
  final String? openingDate;
  final String? taxRegistrationId;
  final String? notes;

  String get displayOutletType {
    switch (outletType.toUpperCase()) {
      case 'STORE':
        return 'Retail';
      case 'WAREHOUSE':
        return 'Warehouse';
      default:
        return outletType;
    }
  }
}

class OutletRevenueSummary {
  const OutletRevenueSummary({
    required this.totalRevenue,
    required this.averageOrderValue,
    required this.totalOrders,
    required this.refunds,
    this.revenueChangePercent,
    this.averageOrderValueChangePercent,
    this.ordersChangePercent,
    this.refundsChangePercent,
    required this.revenueOverTime,
    required this.revenueByPaymentMethod,
    required this.revenueSummary,
  });

  final double totalRevenue;
  final double averageOrderValue;
  final int totalOrders;
  final double refunds;
  final double? revenueChangePercent;
  final double? averageOrderValueChangePercent;
  final double? ordersChangePercent;
  final double? refundsChangePercent;
  final List<OutletRevenuePoint> revenueOverTime;
  final List<OutletPaymentMethodShare> revenueByPaymentMethod;
  final OutletRevenueBreakdown revenueSummary;
}

class OutletRevenuePoint {
  const OutletRevenuePoint({required this.label, required this.amount});

  final String label;
  final double amount;
}

class OutletPaymentMethodShare {
  const OutletPaymentMethodShare({
    required this.method,
    required this.amount,
    required this.percent,
  });

  final String method;
  final double amount;
  final double percent;
}

class OutletRevenueBreakdown {
  const OutletRevenueBreakdown({
    required this.grossRevenue,
    required this.discounts,
    required this.returns,
    required this.netRevenue,
    required this.taxCollected,
  });

  final double grossRevenue;
  final double discounts;
  final double returns;
  final double netRevenue;
  final double taxCollected;
}

class OutletAssignedUsersResult {
  const OutletAssignedUsersResult({
    required this.summary,
    required this.items,
  });

  final OutletAssignedUsersSummary summary;
  final List<OutletAssignedUser> items;
}

class OutletAssignedUsersSummary {
  const OutletAssignedUsersSummary({
    required this.totalAssignedUsers,
    required this.activeUsers,
    required this.pendingInvites,
    required this.managers,
  });

  final int totalAssignedUsers;
  final int activeUsers;
  final int pendingInvites;
  final int managers;
}

class OutletAssignedUser {
  const OutletAssignedUser({
    required this.userId,
    required this.displayName,
    required this.roleName,
    this.assignedTillOrDepartment,
    this.phoneNumber,
    this.email,
    this.outletAccess,
    required this.status,
    this.lastActivity,
  });

  final String userId;
  final String displayName;
  final String roleName;
  final String? assignedTillOrDepartment;
  final String? phoneNumber;
  final String? email;
  final String? outletAccess;
  final String status;
  final String? lastActivity;
}

class OutletTillsDetailResult {
  const OutletTillsDetailResult({
    required this.summary,
    required this.items,
  });

  final OutletTillsSummary summary;
  final List<OutletTillDetailItem> items;
}

class OutletTillsSummary {
  const OutletTillsSummary({
    required this.totalTills,
    required this.activeTills,
    required this.currentlyOpenTills,
    required this.tillsNeedingAttention,
  });

  final int totalTills;
  final int activeTills;
  final int currentlyOpenTills;
  final int tillsNeedingAttention;
}

class OutletTillDetailItem {
  const OutletTillDetailItem({
    required this.tillId,
    required this.tillName,
    required this.tillCode,
    required this.status,
    this.currentBalance,
    this.openingAmount,
    this.lastOpenedAt,
    this.lastClosedAt,
    this.assignedCashierName,
    required this.deviceStatus,
  });

  final String tillId;
  final String tillName;
  final String tillCode;
  final String status;
  final double? currentBalance;
  final double? openingAmount;
  final String? lastOpenedAt;
  final String? lastClosedAt;
  final String? assignedCashierName;
  final String deviceStatus;
}

extension OutletDetailDtoMapper on OutletDetailDto {
  OutletDetail toEntity() => OutletDetail(
        outletId: outletId,
        outletName: outletName,
        outletCode: outletCode,
        outletType: outletType,
        status: status,
        addressLine1: addressLine1,
        addressLine2: addressLine2,
        city: city,
        districtOrProvince: districtOrProvince,
        postalCode: postalCode,
        phoneNumber: phoneNumber,
        emailAddress: emailAddress,
        managerName: managerName,
        operatingHours: operatingHours,
        openingDate: openingDate,
        taxRegistrationId: taxRegistrationId,
        notes: notes,
      );
}

extension OutletRevenueSummaryDtoMapper on OutletRevenueSummaryDto {
  OutletRevenueSummary toEntity() => OutletRevenueSummary(
        totalRevenue: totalRevenue,
        averageOrderValue: averageOrderValue,
        totalOrders: totalOrders,
        refunds: refunds,
        revenueChangePercent: revenueChangePercent,
        averageOrderValueChangePercent: averageOrderValueChangePercent,
        ordersChangePercent: ordersChangePercent,
        refundsChangePercent: refundsChangePercent,
        revenueOverTime: revenueOverTime
            .map((point) => OutletRevenuePoint(
                  label: point.label,
                  amount: point.amount,
                ))
            .toList(growable: false),
        revenueByPaymentMethod: revenueByPaymentMethod
            .map((item) => OutletPaymentMethodShare(
                  method: item.method,
                  amount: item.amount,
                  percent: item.percent,
                ))
            .toList(growable: false),
        revenueSummary: OutletRevenueBreakdown(
          grossRevenue: revenueSummary.grossRevenue,
          discounts: revenueSummary.discounts,
          returns: revenueSummary.returns,
          netRevenue: revenueSummary.netRevenue,
          taxCollected: revenueSummary.taxCollected,
        ),
      );
}

extension OutletAssignedUsersDtoMapper on OutletAssignedUsersDto {
  OutletAssignedUsersResult toEntity() => OutletAssignedUsersResult(
        summary: OutletAssignedUsersSummary(
          totalAssignedUsers: summary.totalAssignedUsers,
          activeUsers: summary.activeUsers,
          pendingInvites: summary.pendingInvites,
          managers: summary.managers,
        ),
        items: items
            .map((user) => OutletAssignedUser(
                  userId: user.userId,
                  displayName: user.displayName,
                  roleName: user.roleName,
                  assignedTillOrDepartment: user.assignedTillOrDepartment,
                  phoneNumber: user.phoneNumber,
                  email: user.email,
                  outletAccess: user.outletAccess,
                  status: user.status,
                  lastActivity: user.lastActivity,
                ))
            .toList(growable: false),
      );
}

extension OutletTillsDetailDtoMapper on OutletTillsDetailDto {
  OutletTillsDetailResult toEntity() => OutletTillsDetailResult(
        summary: OutletTillsSummary(
          totalTills: summary.totalTills,
          activeTills: summary.activeTills,
          currentlyOpenTills: summary.currentlyOpenTills,
          tillsNeedingAttention: summary.tillsNeedingAttention,
        ),
        items: items
            .map((till) => OutletTillDetailItem(
                  tillId: till.tillId,
                  tillName: till.tillName,
                  tillCode: till.tillCode,
                  status: till.status,
                  currentBalance: till.currentBalance,
                  openingAmount: till.openingAmount,
                  lastOpenedAt: till.lastOpenedAt,
                  lastClosedAt: till.lastClosedAt,
                  assignedCashierName: till.assignedCashierName,
                  deviceStatus: till.deviceStatus,
                ))
            .toList(growable: false),
      );
}
