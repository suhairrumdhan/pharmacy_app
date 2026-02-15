abstract class DefaultPermissions {
  const DefaultPermissions();

  static const Map<String, bool> adminPermissions = {
    // Dashboard
    'dashboard.view': true,
    'dashboard.analytics.view': true,
    'dashboard.reports.view': true,
    'shifts.view' :true,
    'purchases.view':true,
    // Sales
    'sales.view': true,
    'sales.create': true,
    'sales.edit': true,
    'sales.delete': true,
    'sales.refund': true,
    'sales.override_price': true,
    'sales.view_history': true,

    // Inventory
    'inventory.view': true,
    'inventory.create': true,
    'inventory.update': true,
    'inventory.delete': true,
    'inventory.adjust_quantity': true,
    'inventory.view_cost': true,
    'inventory.expiry.manage': true,

    // Orders
    'orders.view': true,
    'orders.create': true,
    'orders.update_status': true,
    'orders.cancel': true,
    'orders.assign': true,
    'orders.external_sync': true,

    // Employees & Roles
    'employees.view': true,
    'employees.create': true,
    'employees.update': true,
    'employees.delete': true,
    'roles.manage': true,

    'settings.view': true,
    'settings.update': true,            // تعديل المعلومات الأساسية
    'settings.edit_image': true,        // رفع الصورة
    'settings.delete_image': true,      // حذف الصورة
    'settings.update_online': true,     // تعديل حالة الاونلاين
    'settings.update_24h': true,

  };
  static const Map<String, bool> pharmacistPermissions = {
    // Dashboard
    'dashboard.view': true,
    'dashboard.analytics.view': false,
    'dashboard.reports.view': false,
    'shifts.view' :true,
    'purchases.view':true,
    // Sales
    'sales.view': true,
    'sales.create': true,
    'sales.edit': true,
    'sales.delete': false,
    'sales.refund': true,
    'sales.override_price': false,
    'sales.view_history': true,

    // Inventory
    'inventory.view': true,
    'inventory.create': true,
    'inventory.update': true,
    'inventory.delete': false,
    'inventory.adjust_quantity': true,
    'inventory.view_cost': false,
    'inventory.expiry.manage': true,

    // Orders
    'orders.view': true,
    'orders.create': true,
    'orders.update_status': true,
    'orders.cancel': false,
    'orders.assign': true,
    'orders.external_sync': false,

    // Employees & Roles
    'employees.view': true,
    'employees.create': false,
    'employees.update': false,
    'employees.delete': false,
    'roles.manage': false,

    // Settings
    'settings.view': true,
    'settings.update': true,            // تعديل المعلومات الأساسية
    'settings.edit_image': true,        // رفع الصورة
    'settings.delete_image': true,      // حذف الصورة
    'settings.update_online': true,     // تعديل حالة الاونلاين
    'settings.update_24h': true,
  };
  static const Map<String, bool> cashierPermissions = {
    // Dashboard
    'dashboard.view': true,
    'dashboard.analytics.view': false,
    'dashboard.reports.view': false,
    'shifts.view' :true,
    'purchases.view':true,
    // Sales
    'sales.view': true,
    'sales.create': true,
    'sales.edit': false,
    'sales.delete': false,
    'sales.refund': false,
    'sales.override_price': false,
    'sales.view_history': false,

    // Inventory
    'inventory.view': true,
    'inventory.create': false,
    'inventory.update': false,
    'inventory.delete': false,
    'inventory.adjust_quantity': false,
    'inventory.view_cost': false,
    'inventory.expiry.manage': false,

    // Orders
    'orders.view': false,
    'orders.create': false,
    'orders.update_status': false,
    'orders.cancel': false,
    'orders.assign': false,
    'orders.external_sync': false,

    // Employees & Roles
    'employees.view': false,
    'employees.create': false,
    'employees.update': false,
    'employees.delete': false,
    'roles.manage': false,

    'settings.view': true,
    'settings.update': true,            // تعديل المعلومات الأساسية
    'settings.edit_image': true,        // رفع الصورة
    'settings.delete_image': true,      // حذف الصورة
    'settings.update_online': true,     // تعديل حالة الاونلاين
    'settings.update_24h': true,
  };
  static const List<Map<String, dynamic>> defaultRoles = [
  {
    'id': 'admin',
    'name': 'Administrator',
    'isSystem': true,
  },
  {
    'id': 'pharmacist',
    'name': 'Pharmacist',
    'isSystem': true,
  },
  {
    'id': 'cashier',
    'name': 'Cashier',
    'isSystem': true,
  },
];
}

class DefaultPermissionsHelper {
  static Map<String, bool> getPermissionsForRole(String roleId) {
    switch (roleId) {
      case 'admin':
        return DefaultPermissions.adminPermissions;
      case 'pharmacist':
        return DefaultPermissions.pharmacistPermissions;
      case 'cashier':
        return DefaultPermissions.cashierPermissions;
      default:
        return DefaultPermissions.pharmacistPermissions;
    }
  }

  static List<String> getDefaultRoles() {
    return ['admin', 'pharmacist', 'cashier'];
  }

  static String getRoleDisplayName(String roleId) {
    switch (roleId) {
      case 'admin':
        return 'مدير النظام';
      case 'pharmacist':
        return 'صيدلي';
      case 'cashier':
        return 'كاشير';
      default:
        return 'صيدلي';
    }
  }

  static Map<String, String> getRoleDisplayNames() {
    return {
      'admin': 'مدير النظام',
      'pharmacist': 'صيدلي',
      'cashier': 'كاشير',
    };
  }

  static List<Map<String, String>> getRoleOptions() {
    return [
      {'id': 'admin', 'name': 'مدير النظام'},
      {'id': 'pharmacist', 'name': 'صيدلي'},
      {'id': 'cashier', 'name': 'كاشير'},
    ];
  }
}

// القائمة الكاملة للصلاحيات (بالإنجليزية)
const List<String> ALL_PERMISSIONS = [
  // Dashboard
  'dashboard.view',
  'dashboard.analytics.view',
  'dashboard.reports.view',

  // Sales
  'sales.view',
  'sales.create',
  'sales.edit',
  'sales.delete',
  'sales.refund',
  'sales.override_price',
  'sales.view_history',

  // Inventory
  'inventory.view',
  'inventory.create',
  'inventory.update',
  'inventory.delete',
  'inventory.adjust_quantity',
  'inventory.view_cost',
  'inventory.expiry.manage',

  // Orders
  'orders.view',
  'orders.create',
  'orders.update_status',
  'orders.cancel',
  'orders.assign',
  'orders.external_sync',

  // Employees & Roles
  'employees.view',
  'employees.create',
  'employees.update',
  'employees.delete',
  'roles.manage',

  // Settings
  'settings.view',
  'settings.update',
  'settings.edit_image',
  'settings.delete_image',
  'settings.update_online',
  'settings.update_24h',
];

// Map لتحويل أسماء الصلاحيات من الإنجليزية إلى العربية
final Map<String, String> permissionTranslations = {
  // Dashboard
  'dashboard.view': 'عرض لوحة التحكم',
  'dashboard.analytics.view': 'عرض التحليلات',
  'dashboard.reports.view': 'عرض التقارير',

  // Sales
  'sales.view': 'عرض المبيعات',
  'sales.create': 'إنشاء مبيعات',
  'sales.edit': 'تعديل المبيعات',
  'sales.delete': 'حذف المبيعات',
  'sales.refund': 'إرجاع المبيعات',
  'sales.override_price': 'تجاوز السعر',
  'sales.view_history': 'عرض تاريخ المبيعات',

  // Inventory
  'inventory.view': 'عرض المخزون',
  'inventory.create': 'إضافة منتجات',
  'inventory.update': 'تعديل المنتجات',
  'inventory.delete': 'حذف المنتجات',
  'inventory.adjust_quantity': 'ضبط الكميات',
  'inventory.view_cost': 'عرض التكلفة',
  'inventory.expiry.manage': 'إدارة تاريخ الصلاحية',

  // Orders
  'orders.view': 'عرض الطلبات',
  'orders.create': 'إنشاء طلبات',
  'orders.update_status': 'تحديث حالة الطلبات',
  'orders.cancel': 'إلغاء الطلبات',
  'orders.assign': 'تعيين الطلبات',
  'orders.external_sync': 'مزامنة خارجية',

  // Employees & Roles
  'employees.view': 'عرض الموظفين',
  'employees.create': 'إضافة موظفين',
  'employees.update': 'تعديل الموظفين',
  'employees.delete': 'حذف الموظفين',
  'roles.manage': 'إدارة الأدوار',

  // Settings
  'settings.view': 'عرض الإعدادات',
  'settings.update': 'تحديث الإعدادات',
  'settings.edit_image': 'تعديل الصورة',
  'settings.delete_image': 'حذف الصورة',
  'settings.update_online': 'تحديث حالة الاتصال',
  'settings.update_24h': 'تحديث حالة العمل 24 ساعة',
};

// Map لتجميع الصلاحيات حسب الفئة (للعرض في مجموعات)
final Map<String, List<String>> permissionGroups = {
  'لوحة التحكم': [
    'dashboard.view',
    'dashboard.analytics.view',
    'dashboard.reports.view',
  ],
  'المبيعات': [
    'sales.view',
    'sales.create',
    'sales.edit',
    'sales.delete',
    'sales.refund',
    'sales.override_price',
    'sales.view_history',
  ],
  'المخزون': [
    'inventory.view',
    'inventory.create',
    'inventory.update',
    'inventory.delete',
    'inventory.adjust_quantity',
    'inventory.view_cost',
    'inventory.expiry.manage',
  ],
  'الطلبات': [
    'orders.view',
    'orders.create',
    'orders.update_status',
    'orders.cancel',
    'orders.assign',
    'orders.external_sync',
  ],
  'الموظفين والأدوار': [
    'employees.view',
    'employees.create',
    'employees.update',
    'employees.delete',
    'roles.manage',
  ],
  'الإعدادات': [
    'settings.view',
    'settings.update',
    'settings.edit_image',
    'settings.delete_image',
    'settings.update_online',
    'settings.update_24h',
  ],
};

// دالة مساعدة للحصول على الصلاحيات الفعلية بناءً على الدور
List<String> getActualPermissionsForRole(Map<String, bool> rolePermissions) {
  final allPermissions = rolePermissions.keys.toList();
  final actualPermissions = <String>[];

  for (final group in permissionGroups.values) {
    for (final permission in group) {
      if (allPermissions.contains(permission)) {
        actualPermissions.add(permission);
      }
    }
  }

  return actualPermissions;
}
