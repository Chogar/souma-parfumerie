class AppConfig {
  static const String appName = 'SOUMAPARFUMERIE';
  static const String appVersion = '1.0.0';

  // PostgreSQL local — à adapter sur chaque poste boutique
  static const String dbHost = '127.0.0.1';
  static const int dbPort = 5432;
  static const String dbName = 'souma_parfumerie';
  /// Utilisateur PostgreSQL local (Mac Homebrew : nom de session macOS).
  static const String dbUser = 'hassanechogar';
  static const String dbPassword = '';

  // API LWS — configurable dans Paramètres
  static const String defaultApiBaseUrl =
      'http://localhost:8888/Souma%20Parfumerie/api/public';

  static const String currencySymbol = 'FCFA';
  static const String deviceId = 'boutique-windows-01';
}
