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

  if (method == 'GET' && path == '/api/tenant-admin/context') {
    return _context;
  }

  if (method == 'GET' && path == '/api/tenant-admin/menu') {
    return _menu;
  }

  if (method == 'GET' && path == '/api/tenant-admin/dashboard') {
    return _dashboard;
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

  if (method == 'GET' && path == '/api/tenant-admin/outlets') {
    return _outlets;
  }

  if (method == 'GET' && path == '/api/tenant-admin/staff/managers') {
    return _managers;
  }

  if (method == 'GET' && path.startsWith('/api/tenant-admin/outlets/')) {
    return _outletDetails(path.split('/').last);
  }

  if (method == 'POST' && path == '/api/tenant-admin/outlets') {
    return _createdOutlet(options.data);
  }

  if (method == 'PUT' && path.startsWith('/api/tenant-admin/outlets/')) {
    return _createdOutlet(options.data, id: path.split('/').last);
  }

  if (method == 'PATCH' &&
      path.startsWith('/api/tenant-admin/outlets/') &&
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
      'outlets.view',
      'outlets.create',
      'outlets.update',
      'tenant.till.manage',
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
    'route': '/tenant-admin/stock',
    'iconKey': 'inventory',
    'featureCode': 'inventory.stock',
    'permissionCode': 'inventory.view',
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

const _dashboard = {
  'metrics': [
    {
      'key': 'sales',
      'title': "Today's Sales",
      'value': '£3,245.50',
      'subtitle': 'vs yesterday',
      'iconKey': 'sales',
      'trend': '+12.5%',
      'status': 'success',
    },
    {
      'key': 'orders',
      'title': 'Orders',
      'value': '128',
      'subtitle': 'vs yesterday',
      'iconKey': 'orders',
      'trend': '+8.7%',
      'status': 'success',
    },
    {
      'key': 'outlets',
      'title': 'Active Outlets',
      'value': '5',
      'subtitle': 'All outlets are online',
      'iconKey': 'store',
      'status': 'success',
    },
    {
      'key': 'stock',
      'title': 'Stock Alerts',
      'value': '14',
      'subtitle': 'items need attention',
      'iconKey': 'warning',
      'status': 'warning',
    },
  ],
  'salesThisWeek': {
    'title': 'Sales this week',
    'total': '£18,245.75',
    'subtitle': '+15.3% vs last week',
    'points': [
      {'label': 'Mon', 'value': 1200},
      {'label': 'Tue', 'value': 2000},
      {'label': 'Wed', 'value': 1750},
      {'label': 'Thu', 'value': 3500},
      {'label': 'Fri', 'value': 2400},
      {'label': 'Sat', 'value': 1500},
      {'label': 'Sun', 'value': 2900},
    ],
  },
  'needsAttention': [
    {
      'title': '2 tills are offline',
      'message': 'Bring them back online',
      'status': 'danger',
      'route': '/tenant-admin/tills',
    },
    {
      'title': '14 low stock items',
      'message': 'Restock to avoid running out',
      'status': 'warning',
      'route': '/tenant-admin/stock',
    },
    {
      'title': '3 pending staff invites',
      'message': 'Review and send invites',
      'status': 'pending',
      'route': '/tenant-admin/staff',
    },
  ],
  'quickActions': [
    {
      'key': 'add-outlet',
      'title': 'Add outlet',
      'route': '/tenant-admin/outlets/add',
      'featureCode': 'tenant_admin.outlets',
      'permissionCode': 'outlets.create',
      'iconKey': 'store',
    },
    {
      'key': 'add-till',
      'title': 'Add till',
      'route': '/tenant-admin/tills/add',
      'featureCode': 'tenant.tills',
      'permissionCode': 'tenant.till.manage',
      'iconKey': 'till',
    },
    {
      'key': 'add-staff',
      'title': 'Add staff',
      'route': '/tenant-admin/staff/add',
      'featureCode': 'tenant.users',
      'permissionCode': 'tenant.user.manage',
      'iconKey': 'users',
    },
    {
      'key': 'add-product',
      'title': 'Add product',
      'route': '/tenant-admin/products/add',
      'featureCode': 'catalog.product',
      'permissionCode': 'catalog.product.create',
      'iconKey': 'products',
    },
  ],
  'recentActivity': [
    {
      'title': 'New outlet added',
      'subtitle': 'High Street Store',
      'timeLabel': 'Today, 09:30 AM',
      'iconKey': 'store',
    },
    {
      'title': 'Stock adjusted',
      'subtitle': 'Basmati Rice 5kg',
      'timeLabel': 'Today, 08:15 AM',
      'iconKey': 'inventory',
    },
    {
      'title': 'Staff invite sent',
      'subtitle': 'Emma Patel',
      'timeLabel': 'Yesterday, 06:45 PM',
      'iconKey': 'users',
    },
  ],
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

  return {
    'id': item['id'],
    'name': item['name'],
    'code': item['code'],
    'address': item['location'],
    'status': item['status'],
    'managerName': 'Aisha Khan',
    'managerPhone': '+44 7700 900123',
    'openingHours': '08:00 – 20:00',
    'todaysStatus': 'Operating as normal today',
    'metrics': [
      {
        'title': 'Tills',
        'value': '${item['tillCount']}',
        'subtitle': '${item['onlineTillCount']} online',
        'iconKey': 'till',
      },
      {
        'title': 'Staff',
        'value': '${item['staffCount']}',
        'subtitle': 'Assigned staff',
        'iconKey': 'users',
      },
      {
        'title': "Today's sales",
        'value': '${item['todaysSales']}',
        'subtitle': '+12.5% vs yesterday',
        'iconKey': 'sales',
      },
      {
        'title': 'This week',
        'value': '£8,920.30',
        'subtitle': '+8.3% vs last week',
        'iconKey': 'reports',
      },
    ],
    'assignedTills': [
      {
        'id': 'till-1',
        'title': 'Front Counter Till',
        'subtitle': 'TILL-001',
        'status': 'online'
      },
      {
        'id': 'till-2',
        'title': 'Kiosk Till',
        'subtitle': 'TILL-002',
        'status': 'online'
      },
      {
        'id': 'till-3',
        'title': 'Back Office Till',
        'subtitle': 'TILL-003',
        'status': 'offline'
      },
    ],
    'staff': [
      {
        'id': 'staff-1',
        'title': 'Aisha Khan',
        'subtitle': 'Manager',
        'status': 'active'
      },
      {
        'id': 'staff-2',
        'title': 'Ravi Sharma',
        'subtitle': 'Cashier',
        'status': 'active'
      },
      {
        'id': 'staff-3',
        'title': 'Emma Patel',
        'subtitle': 'Supervisor',
        'status': 'active'
      },
    ],
    'needsAttention': [
      {
        'title': '1 till offline',
        'message': 'Back Office Till is offline',
        'status': 'danger'
      },
      {
        'title': '2 low stock items',
        'message': 'View and restock soon',
        'status': 'warning'
      },
    ],
  };
}

Map<String, Object?> _createdOutlet(Object? data, {String id = 'outlet-new'}) {
  final body = data is Map ? Map<String, dynamic>.from(data) : const {};

  return {
    'id': id,
    'name': body['outletName']?.toString() ?? 'New Outlet',
    'code': body['outletCode']?.toString() ?? 'OUT-NEW',
    'location': body['addressLine1']?.toString() ?? '',
    'status': 'active',
    'tillCount': 0,
    'onlineTillCount': 0,
    'staffCount': 0,
    'todaysSales': '£0.00',
  };
}
