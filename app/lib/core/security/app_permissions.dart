import 'package:souma_parfumerie/core/models/user_model.dart';

/// Droits conformes au CDC SOUMAPARFUMERIE (§3 Gestionnaire / Manager).
class AppPermissions {
  AppPermissions(this.user, [Map<String, dynamic>? extra])
      : _extra = extra ?? const {};

  final UserModel user;
  final Map<String, dynamic> _extra;

  bool get isManager => user.isManager;

  bool _flag(String key, {bool defaultGestionnaire = false}) {
    if (isManager) return true;
    final v = _extra[key];
    if (v is bool) return v;
    return defaultGestionnaire;
  }

  bool get canAccessDashboard => true;
  bool get canUsePos => true;

  bool get canViewCatalog =>
      _flag('view_catalog', defaultGestionnaire: true);
  bool get canManageProducts =>
      isManager || _flag('manage_products', defaultGestionnaire: false);
  bool get canViewStock => _flag('view_stock', defaultGestionnaire: true);
  bool get canAdjustStock =>
      _flag('adjust_stock', defaultGestionnaire: false);
  bool get canViewSalesHistory =>
      _flag('view_sales_history', defaultGestionnaire: true);
  bool get canManageClients =>
      _flag('manage_clients', defaultGestionnaire: true);
  bool get canViewOperationalReports =>
      _flag('view_reports', defaultGestionnaire: true);
  bool get canViewFinancialReports =>
      isManager || _flag('view_financial_reports', defaultGestionnaire: false);
  bool get canViewGlobalRevenue => canViewFinancialReports;

  bool get scopeOwnSalesOnly => !isManager;

  bool get canViewSaleAmounts => isManager || scopeOwnSalesOnly;
  bool get canManageUsers => isManager;
  bool get canManageCategories => isManager;
  bool get canManageSuppliers => isManager;
  bool get canAccessSettings => isManager;
  bool get canRunBackup => isManager;
  bool get canEditProductPrices => canManageProducts;
  bool get canDeleteSales => false;

  bool get canRequestSaleReturn => canViewSalesHistory;
  /// Validation retour : réservée au compte administrateur (rôle manager).
  bool get canApproveSaleReturn => isManager;

  bool get canViewAlerts =>
      _flag('view_stock', defaultGestionnaire: true) && canViewCatalog;
  bool get canManageExpenses =>
      isManager || _flag('manage_expenses', defaultGestionnaire: false);
  bool get canViewExpenses =>
      isManager || _flag('view_expenses', defaultGestionnaire: false);
}
