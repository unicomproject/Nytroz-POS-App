import 'package:dio/dio.dart';

class TenantAdminDevApiInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final response = _responseFor(options);

    if (response == null) {
      handler.next(options);
      return;
    }

    handler.resolve(
      Response<dynamic>(
        requestOptions: options,
        statusCode: 200,
        data: response,
      ),
    );
  }
}

final Map<String, String> _activatedTenantAdminPasswords = {};

Object? _responseFor(RequestOptions options) {
  final method = options.method.toUpperCase();
  final path = options.path;

  if (method == 'GET' &&
      (path == '/api/tenant-admin/context' ||
          path == '/api/v1/tenant-admin/context')) {
    return _context;
  }

  if (method == 'GET' && path == '/api/tenant-admin/menu') {
    return _menu;
  }

  if (method == 'GET' &&
      (path == '/api/tenant-admin/dashboard' ||
          path == '/api/v1/tenant-admin/dashboard' ||
          path == '/api/v1/tenant-admin/dashboard/summary')) {
    return _dashboardSummary;
  }

  if (method == 'GET' && path == '/api/tenant-admin/onboarding/auth-branding') {
    return const {
      // Backend/database can return uploaded image URLs here.
      // Keep null in dev to use built-in fallback illustration.
      'logoUrl': null,
      'loginIllustrationUrl': null,
    };
  }

  if (method == 'GET' &&
      path.startsWith('/api/tenant-admin/onboarding/payment-summary/')) {
    return _paymentSummary(path.split('/').last);
  }

  if (method == 'POST' &&
      path == '/api/tenant-admin/onboarding/start-payment') {
    final data = options.data is Map
        ? Map<String, dynamic>.from(options.data as Map)
        : const {};
    return {
      'paymentToken': data['paymentToken']?.toString() ?? 'payment-dev',
      'status': 'processing',
      'message': 'Payment started',
    };
  }

  if (method == 'GET' &&
      path.startsWith('/api/tenant-admin/onboarding/payment-status/')) {
    return {
      'paymentToken': path.split('/').last,
      'status': 'success',
      'message': 'Payment completed successfully',
    };
  }

  if (method == 'GET' &&
      path.startsWith('/api/tenant-admin/onboarding/setup-token/') &&
      path.endsWith('/validate')) {
    final parts = path.split('/');
    final token = parts.length > 2 ? parts[parts.length - 2] : 'setup-dev';
    return {
      'setupToken': token,
      'valid': token != 'invalid',
      'expired': token == 'expired',
      'email': _emailForSetupToken(token),
      'message': token == 'expired' ? 'This setup link has expired.' : null,
    };
  }

  if (method == 'POST' &&
      path == '/api/tenant-admin/onboarding/setup-password') {
    final data = options.data is Map
        ? Map<String, dynamic>.from(options.data as Map)
        : const {};
    final setupToken = data['setupToken']?.toString() ?? 'setup-dev';
    final password = data['password']?.toString() ?? '';
    final confirmPassword = data['confirmPassword']?.toString() ?? '';
    final email = _emailForSetupToken(setupToken);

    if (password.isEmpty || password != confirmPassword) {
      return {
        'success': false,
        'errors': {
          'password': ['Password is invalid.'],
        },
      };
    }

    _activatedTenantAdminPasswords[email.toLowerCase()] = password;
    return {'success': true};
  }

  if (method == 'POST' && path == '/api/tenant-admin/auth/login') {
    final data = options.data is Map
        ? Map<String, dynamic>.from(options.data as Map)
        : const {};
    final email = data['email']?.toString().trim().toLowerCase() ?? '';
    final password = data['password']?.toString() ?? '';
    final storedPassword = _activatedTenantAdminPasswords[email];

    if (storedPassword == null || storedPassword != password) {
      return {
        'accessToken': '',
        'userId': '',
        'userDisplayName': '',
        'error': 'INVALID_CREDENTIALS',
      };
    }

    return {
      'accessToken': 'dev-access-token',
      'refreshToken': 'dev-refresh-token',
      'userId': 'user-dev',
      'userDisplayName': email,
      'expiresAt':
          DateTime.now().add(const Duration(hours: 8)).toIso8601String(),
    };
  }

  if (method == 'GET' &&
      (path == '/api/tenant-admin/outlets' ||
          path == '/api/v1/tenant-admin/outlets')) {
    return _outlets;
  }

  if (method == 'GET' && path == '/api/tenant-admin/staff/managers') {
    return _managers;
  }

  if (method == 'GET' &&
      (path.startsWith('/api/v1/tenant-admin/outlets/') ||
          path.startsWith('/api/tenant-admin/outlets/'))) {
    return _outletDetails(path.split('/').last);
  }

  if (method == 'POST' &&
      (path == '/api/tenant-admin/outlets' ||
          path == '/api/v1/tenant-admin/outlets')) {
    return _createdOutlet(options.data);
  }

  if (method == 'GET' && path == '/api/v1/tenant-admin/outlets/options') {
    return _outletOptions;
  }

  if (method == 'GET' && path == '/api/v1/tenant-admin/tills') {
    return _tills;
  }

  if (method == 'POST' && path == '/api/v1/tenant-admin/tills') {
    return _createdTill(options.data);
  }

  if (method == 'PUT' &&
      (path.startsWith('/api/v1/tenant-admin/outlets/') ||
          path.startsWith('/api/tenant-admin/outlets/'))) {
    return _createdOutlet(options.data, id: path.split('/').last);
  }

  if (method == 'PATCH' &&
      (path.startsWith('/api/v1/tenant-admin/outlets/') ||
          path.startsWith('/api/tenant-admin/outlets/')) &&
      path.endsWith('/status')) {
    return const {'success': true};
  }

  return null;
}

String _emailForSetupToken(String setupToken) {
  if (setupToken == 'staff-dev') {
    return 'staff@coffeecorner.test';
  }

  return 'admin@coffeecorner.test';
}

const _features = [
  {'featureCode': 'tenant_admin.dashboard', 'featureName': 'Dashboard'},
  {'featureCode': 'tenant_admin.outlets', 'featureName': 'Outlets'},
  {'featureCode': 'tenant.tills', 'featureName': 'Tills'},
  {'featureCode': 'tenant.users', 'featureName': 'Staff'},
  {'featureCode': 'tenant.roles', 'featureName': 'Roles & Access'},
  {'featureCode': 'catalog.product', 'featureName': 'Products'},
  {'featureCode': 'inventory.stock', 'featureName': 'Stock'},
  {'featureCode': 'reports', 'featureName': 'Reports'},
  {'featureCode': 'sales', 'featureName': 'Sales'},
  {'featureCode': 'subscription.billing', 'featureName': 'Billing'},
  {'featureCode': 'tenant.settings', 'featureName': 'Settings'},
  {'featureCode': 'tenant.activity', 'featureName': 'Activity'},
];

final _context = {
  'tenantId': 'tenant-dev',
  'tenantName': 'Coffee Corner Ltd',
  'userId': 'user-dev',
  'userDisplayName': 'Sarah Ahmed',
  'roleNames': ['Owner'],
  'outletScope': [
    {
      'outletId': 'outlet-1',
      'outletName': 'High Street Store',
      'isDefault': true
    },
    {'outletId': 'outlet-2', 'outletName': 'Central Store', 'isDefault': false},
    {
      'outletId': 'outlet-3',
      'outletName': 'West End Store',
      'isDefault': false
    },
  ],
  'featureEntitlements': [
    for (final feature in _features) {...feature, 'enabled': true},
  ],
  'permissions': [
    for (final code in [
      'dashboard.view',
      'dashboard.summary.view',
      'dashboard.alerts.view',
      'dashboard.filter.date',
      'dashboard.filter.outlet',
      'sales.summary.view',
      'sales.orders.view',
      'analytics.sales_trend.view',
      'reports.sales.view',
      'outlets.view',
      'outlets.create',
      'outlets.activity.view',
      'tills.status.view',
      'users.invites.view',
      'users.activity.view',
      'inventory.stock_alerts.view',
      'inventory.activity.view',
      'billing.view',
      'subscription.view',
      'notifications.view',
      'profile.view',
      'tenant.context.view',
      'activity.view',
      'outlets.view',
      'outlets.create',
      'outlets.update',
      'tenant.till.manage',
      'till.view',
      'till.create',
      'tenant.user.manage',
      'tenant.role.manage',
      'catalog.product.view',
      'catalog.product.create',
      'catalog.product.update',
      'tenant.product.import',
      'inventory.view',
      'inventory.adjust',
      'reports.view',
      'tenant.billing.view',
      'tenant.settings.manage',
      'tenant.activity.view',
    ])
      {'permissionCode': code, 'permissionName': code},
  ],
  'runtimeFlags': [
    for (final feature in _features)
      {'featureCode': feature['featureCode'], 'enabled': true},
  ],
  'subscriptionStatus': 'Active',
};

const _menu = [
  {
    'key': 'dashboard',
    'label': 'Dashboard',
    'route': '/tenant-admin/dashboard',
    'iconKey': 'dashboard',
    'featureCode': 'tenant_admin.dashboard',
    'permissionCode': 'dashboard.view',
    'visible': true,
    'order': 1,
  },
  {
    'key': 'outlets',
    'label': 'Outlets',
    'route': '/tenant-admin/outlets',
    'iconKey': 'store',
    'featureCode': 'tenant_admin.outlets',
    'permissionCode': 'outlets.view',
    'visible': true,
    'order': 2,
  },
  {
    'key': 'tills',
    'label': 'Tills',
    'route': '/tenant-admin/tills',
    'iconKey': 'till',
    'featureCode': 'tenant.tills',
    'permissionCode': 'tenant.till.manage',
    'visible': true,
    'order': 3,
  },
  {
    'key': 'staff',
    'label': 'Staff',
    'route': '/tenant-admin/staff',
    'iconKey': 'users',
    'featureCode': 'tenant.users',
    'permissionCode': 'tenant.user.manage',
    'visible': true,
    'order': 4,
  },
  {
    'key': 'roles-access',
    'label': 'Roles & Access',
    'route': '/tenant-admin/roles',
    'iconKey': 'shield',
    'featureCode': 'tenant.roles',
    'permissionCode': 'tenant.role.manage',
    'visible': true,
    'order': 5,
  },
  {
    'key': 'products',
    'label': 'Products',
    'route': '/tenant-admin/products',
    'iconKey': 'products',
    'featureCode': 'catalog.product',
    'permissionCode': 'catalog.product.view',
    'visible': true,
    'order': 6,
  },
  {
    'key': 'stock',
    'label': 'Stock',
    'route': '/tenant-admin/stock/current',
    'iconKey': 'inventory',
    'featureCode': 'inventory.stock',
    'permissionCode': 'tenant.stock.view',
    'visible': true,
    'order': 7,
  },
  {
    'key': 'reports',
    'label': 'Reports',
    'route': '/tenant-admin/reports',
    'iconKey': 'reports',
    'featureCode': 'reports',
    'permissionCode': 'reports.view',
    'visible': true,
    'order': 8,
  },
  {
    'key': 'billing',
    'label': 'Billing',
    'route': '/tenant-admin/billing',
    'iconKey': 'billing',
    'featureCode': 'subscription.billing',
    'permissionCode': 'tenant.billing.view',
    'visible': true,
    'order': 9,
  },
  {
    'key': 'settings',
    'label': 'Settings',
    'route': '/tenant-admin/settings',
    'iconKey': 'settings',
    'featureCode': 'tenant.settings',
    'permissionCode': 'tenant.settings.manage',
    'visible': true,
    'order': 10,
  },
  {
    'key': 'activity',
    'label': 'Activity',
    'route': '/tenant-admin/activity',
    'iconKey': 'activity',
    'featureCode': 'tenant.activity',
    'permissionCode': 'tenant.activity.view',
    'visible': true,
    'order': 11,
  },
];

const _dashboardSummary = {
  'success': true,
  'message': 'Tenant admin dashboard summary loaded successfully.',
  'data': {
    'todaySales': {
      'amount': 3245.50,
      'currency': 'LKR',
      'growthPercent': 12.5,
    },
    'orders': {
      'count': 128,
      'growthPercent': 8.7,
    },
    'activeOutlets': {
      'count': 5,
      'onlineCount': 5,
    },
    'stockAlerts': {
      'count': 14,
    },
    'tills': {
      'onlineCount': 10,
      'offlineCount': 2,
    },
    'needsAttention': {
      'offlineTills': 2,
      'lowStockItems': 14,
      'pendingStaffInvites': 3,
      'paymentDue': {
        'amount': 120.00,
        'currency': 'LKR',
        'dueDate': '2026-06-15',
      },
    },
  },
};

Map<String, Object?> _paymentSummary(String paymentToken) {
  return {
    'paymentToken': paymentToken,
    'tenantName': 'Coffee Corner Ltd',
    'planName': 'Professional',
    'billingPeriod': 'Monthly',
    'amount': '120.00',
    'currency': 'GBP',
    'taxAmount': '24.00',
    'totalPayable': '144.00',
    'paymentStatus': 'Pending',
  };
}

const _outlets = {
  'summary': {
    'totalOutlets': 5,
    'activeOutlets': 4,
    'inactiveOutlets': 1,
    'totalLocations': 5,
  },
  'items': [
    {
      'id': 'outlet-1',
      'name': 'High Street Store',
      'code': 'OUT-001',
      'location': '123 High Street, London',
      'status': 'active',
      'tillCount': 3,
      'onlineTillCount': 3,
      'staffCount': 6,
      'todaysSales': '£1,245.50',
    },
    {
      'id': 'outlet-2',
      'name': 'Central Store',
      'code': 'OUT-002',
      'location': '45 Central Road, London',
      'status': 'active',
      'tillCount': 2,
      'onlineTillCount': 2,
      'staffCount': 4,
      'todaysSales': '£892.30',
    },
    {
      'id': 'outlet-3',
      'name': 'West End Store',
      'code': 'OUT-003',
      'location': '78 West End Lane, London',
      'status': 'active',
      'tillCount': 3,
      'onlineTillCount': 3,
      'staffCount': 5,
      'todaysSales': '£654.20',
    },
    {
      'id': 'outlet-4',
      'name': 'North Road Store',
      'code': 'OUT-004',
      'location': '88 North Road, London',
      'status': 'active',
      'tillCount': 2,
      'onlineTillCount': 0,
      'staffCount': 3,
      'todaysSales': '£321.10',
    },
    {
      'id': 'outlet-5',
      'name': 'Old Street Store',
      'code': 'OUT-005',
      'location': '12 Old Street, London',
      'status': 'inactive',
      'tillCount': 2,
      'onlineTillCount': 0,
      'staffCount': 0,
      'todaysSales': '£0.00',
    },
  ],
};

const _managers = [
  {'id': 'user-1', 'displayName': 'Aisha Khan'},
  {'id': 'user-2', 'displayName': 'Ravi Sharma'},
  {'id': 'user-3', 'displayName': 'Emma Patel'},
];

Map<String, Object?> _outletDetails(String id) {
  final items = (_outlets['items']! as List<Map<String, Object?>>);
  final item = items.firstWhere(
    (outlet) => outlet['id'] == id,
    orElse: () => items.first,
  );
  final tillCount = item['tillCount'] ?? 0;
  final onlineTillCount = item['onlineTillCount'] ?? 0;
  final staffCount = item['staffCount'] ?? 0;

  return {
    'success': true,
    'message': 'Outlet loaded successfully.',
    'data': {
      'id': item['id'],
      'name': item['name'],
      'code': item['code'],
      'addressLine1': item['location'],
      'city': 'London',
      'country': 'UK',
      'phone': '+44 7700 900123',
      'email': 'outlet@coffeecorner.test',
      'status': item['status'],
      'managerName': 'Aisha Khan',
      'managerPhone': '+44 7700 900123',
      'openingHours': '08:00 – 20:00, Mon – Sun',
      'todaysStatus': 'Operating as normal today',
      'tillCount': tillCount,
      'onlineTillCount': onlineTillCount,
      'staffCount': staffCount,
      'todaySales': {
        'amount': 1245.50,
        'currency': 'GBP',
      },
      'weekSales': {
        'amount': 8920.30,
        'currency': 'GBP',
      },
      'assignedTills': [
        {
          'id': 'till-1',
          'title': 'Front Counter Till',
          'subtitle': 'TILL-001',
          'status': 'Online',
        },
        {
          'id': 'till-2',
          'title': 'Kiosk Till',
          'subtitle': 'TILL-002',
          'status': 'Online',
        },
        {
          'id': 'till-3',
          'title': 'Back Office Till',
          'subtitle': 'TILL-003',
          'status': 'Offline',
        },
      ],
      'staff': [
        {
          'id': 'staff-1',
          'title': 'Aisha Khan',
          'subtitle': '+44 7700 900123',
          'status': 'Manager',
        },
        {
          'id': 'staff-2',
          'title': 'Ravi Sharma',
          'subtitle': '+44 7700 900456',
          'status': 'Cashier',
        },
        {
          'id': 'staff-3',
          'title': 'Emma Patel',
          'subtitle': '+44 7700 900789',
          'status': 'Supervisor',
        },
      ],
      'needsAttention': [
        {
          'title': '1 till offline',
          'message': 'Back Office Till is offline',
          'status': 'warning',
        },
        {
          'title': '2 low stock items',
          'message': 'View and restock soon',
          'status': 'warning',
        },
      ],
    },
  };
}

Map<String, Object?> _createdOutlet(Object? data, {String id = 'outlet-new'}) {
  final body = data is Map ? Map<String, dynamic>.from(data) : const {};
  final name = body['name']?.toString() ??
      body['outletName']?.toString() ??
      'New Outlet';
  final code =
      body['code']?.toString() ?? body['outletCode']?.toString() ?? 'OUT-NEW';

  return {
    'success': true,
    'message': 'Outlet created successfully.',
    'data': {
      'id': id,
      'name': name,
      'code': code,
      'addressLine1': body['addressLine1']?.toString() ?? '',
      'city': body['city']?.toString() ?? '',
      'country': body['country']?.toString() ?? '',
      'phone': body['phone']?.toString() ?? '',
      'email': body['email']?.toString() ?? '',
      'status': body['status']?.toString() ?? 'Active',
      'tillCount': 0,
      'onlineTillCount': 0,
      'staffCount': 0,
      'todaySales': const {'amount': 0, 'currency': 'GBP'},
    },
  };
}

const _tills = {
  'success': true,
  'message': 'Tills loaded successfully.',
  'data': {
    'summary': {
      'totalTills': 2,
      'onlineCount': 1,
      'offlineCount': 1,
      'needsAttentionCount': 0,
    },
    'items': [
      {
        'id': 'till-1',
        'outletId': 'outlet-1',
        'outletName': 'High Street Store',
        'name': 'Front Counter Till',
        'code': 'TILL-001',
        'status': 'active',
        'operationalStatus': 'online',
        'todaySalesAmount': 1245.60,
        'currency': 'GBP',
        'lastSyncAt': '2026-06-22T10:00:00Z',
      },
      {
        'id': 'till-2',
        'outletId': 'outlet-2',
        'outletName': 'Central Store',
        'name': 'Kiosk Till',
        'code': 'TILL-002',
        'status': 'active',
        'operationalStatus': 'offline',
        'todaySalesAmount': 420.10,
        'currency': 'GBP',
        'lastSyncAt': '2026-06-22T09:30:00Z',
      },
    ],
    'page': 1,
    'pageSize': 10,
    'totalCount': 2,
  },
};

const _outletOptions = {
  'data': [
    {
      'outletId': 'outlet-1',
      'outletName': 'Development Main Store',
      'outletCode': 'DEV-STORE-01',
      'status': 'Active',
    },
  ],
};

Map<String, Object?> _createdTill(Object? data, {String id = 'till-new'}) {
  final body = data is Map ? Map<String, dynamic>.from(data) : const {};
  final tillName = body['tillName']?.toString() ?? body['name']?.toString() ?? 'New Till';
  final tillCode = body['tillCode']?.toString() ?? body['code']?.toString() ?? 'TILL-NEW';
  final status = body['status']?.toString() ?? 'Active';

  return {
    'success': true,
    'message': 'Till created successfully.',
    'data': {
      'tillId': id,
      'outletId': body['outletId']?.toString() ?? 'outlet-1',
      'outletName': 'Development Main Store',
      'outletCode': 'DEV-STORE-01',
      'tillName': tillName,
      'tillCode': tillCode,
      'status': status,
      'deviceStatus': 'Offline',
      'needsAttention': true,
      'deviceName': body['deviceName'],
      'printerName': body['printerName'],
      'scannerName': body['scannerName'],
      'cashDrawerName': body['cashDrawerName'],
      'cardReaderName': body['cardReaderName'],
      'internalNote': body['internalNote'],
      'createdAt': '2026-07-10T12:00:00Z',
      'updatedAt': '2026-07-10T12:00:00Z',
    },
  };
}
