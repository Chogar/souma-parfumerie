import 'package:flutter/foundation.dart';

/// Navigation principale (menu latéral + onglets hubs).
class AppShellNavigation extends ChangeNotifier {
  static const menuAlerts = 'alerts';
  static const menuCommerce = 'commerce';
  static const commerceTabReturns = 'returns';

  String? _pendingMenuKey;
  int? _pendingAlertsTab;
  String? _pendingProductId;
  String? _pendingCommerceTabId;

  int? get pendingAlertsTab => _pendingAlertsTab;
  String? get pendingProductId => _pendingProductId;

  /// Ouvre le menu Alertes sur l'onglet « Expiration proche » (index 1).
  void openAlertsExpiryTab({String? productId}) {
    _pendingMenuKey = menuAlerts;
    _pendingAlertsTab = 1;
    _pendingProductId = productId;
    notifyListeners();
  }

  /// Commerce → onglet « Retours » (validation manager).
  void openCommerceReturnsTab() {
    _pendingMenuKey = menuCommerce;
    _pendingCommerceTabId = commerceTabReturns;
    notifyListeners();
  }

  String? takePendingMenuKey() {
    final k = _pendingMenuKey;
    _pendingMenuKey = null;
    return k;
  }

  int? takePendingAlertsTab() {
    final t = _pendingAlertsTab;
    _pendingAlertsTab = null;
    return t;
  }

  String? takePendingProductId() {
    final id = _pendingProductId;
    _pendingProductId = null;
    return id;
  }

  String? takePendingCommerceTabId() {
    final id = _pendingCommerceTabId;
    _pendingCommerceTabId = null;
    return id;
  }
}
