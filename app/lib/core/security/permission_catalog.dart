/// Droits configurables pour le rôle gestionnaire (caissier).
class PermissionCatalog {
  PermissionCatalog._();

  static const List<PermissionEntry> entries = [
    PermissionEntry(
      key: 'view_catalog',
      defaultGestionnaire: true,
      labelFr: 'Voir le catalogue produits',
      labelAr: 'عرض كتالوج المنتجات',
    ),
    PermissionEntry(
      key: 'manage_products',
      defaultGestionnaire: false,
      labelFr: 'Gérer les produits (ajout, modification)',
      labelAr: 'إدارة المنتجات (إضافة، تعديل)',
    ),
    PermissionEntry(
      key: 'view_stock',
      defaultGestionnaire: true,
      labelFr: 'Voir le stock et les alertes',
      labelAr: 'عرض المخزون والتنبيهات',
    ),
    PermissionEntry(
      key: 'adjust_stock',
      defaultGestionnaire: false,
      labelFr: 'Ajuster le stock (entrées / sorties)',
      labelAr: 'تعديل المخزون',
    ),
    PermissionEntry(
      key: 'view_sales_history',
      defaultGestionnaire: true,
      labelFr: 'Historique des ventes',
      labelAr: 'سجل المبيعات',
    ),
    PermissionEntry(
      key: 'manage_clients',
      defaultGestionnaire: true,
      labelFr: 'Gérer les clients et la fidélité',
      labelAr: 'إدارة العملاء والولاء',
    ),
    PermissionEntry(
      key: 'view_reports',
      defaultGestionnaire: true,
      labelFr: 'Accéder aux rapports',
      labelAr: 'الوصول إلى التقارير',
    ),
    PermissionEntry(
      key: 'view_financial_reports',
      defaultGestionnaire: false,
      labelFr: 'Voir les montants (CA, bénéfices, exports)',
      labelAr: 'عرض المبالغ (إيرادات، أرباح، تصدير)',
    ),
    PermissionEntry(
      key: 'view_expenses',
      defaultGestionnaire: false,
      labelFr: 'Voir les dépenses',
      labelAr: 'عرض المصروفات',
    ),
    PermissionEntry(
      key: 'manage_expenses',
      defaultGestionnaire: false,
      labelFr: 'Saisir et modifier les dépenses',
      labelAr: 'إدخال وتعديل المصروفات',
    ),
  ];

  static Map<String, dynamic> defaultsMap() {
    return {for (final e in entries) e.key: e.defaultGestionnaire};
  }

  static Map<String, dynamic> mergeWithStored(Map<String, dynamic>? stored) {
    final map = defaultsMap();
    if (stored == null) return map;
    for (final e in entries) {
      final v = stored[e.key];
      if (v is bool) map[e.key] = v;
    }
    return map;
  }

  static String labelFor(String key, String locale) {
    final e = entries.firstWhere(
      (x) => x.key == key,
      orElse: () => PermissionEntry(
        key: key,
        defaultGestionnaire: false,
        labelFr: key,
        labelAr: key,
      ),
    );
    return locale.startsWith('ar') ? e.labelAr : e.labelFr;
  }
}

class PermissionEntry {
  const PermissionEntry({
    required this.key,
    required this.defaultGestionnaire,
    required this.labelFr,
    required this.labelAr,
  });

  final String key;
  final bool defaultGestionnaire;
  final String labelFr;
  final String labelAr;
}
