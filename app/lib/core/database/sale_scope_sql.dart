/// Filtre SQL : caissier = uniquement ses ventes ; manager = toutes.
class SaleScopeSql {
  SaleScopeSql._();

  /// `null` = toutes les ventes (manager).
  static String clause({
    String? onlyUserId,
    Map<String, dynamic>? params,
    String tableAlias = 's',
  }) {
    if (onlyUserId == null || onlyUserId.isEmpty) return '';
    params?['scope_user_id'] = onlyUserId;
    return ' AND $tableAlias.user_id = @scope_user_id';
  }
}
