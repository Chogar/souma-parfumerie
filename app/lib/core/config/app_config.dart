/// Configuration boutique — surcharge possible au build :
/// `flutter build windows --release --dart-define=SOUMA_DB_USER=postgres ...`
class AppConfig {
  static const String appName = 'Souma Parfumerie';
  static const String windowTitle = 'Souma Perfumery Management System';
  static const String projectFooter = 'Réalisé par Expérience Tech';
  static const String experienceTechUrl = 'https://www.experiencetech-td.com';
  static const String appVersion = '1.0.0';

  static const String dbHost = String.fromEnvironment(
    'SOUMA_DB_HOST',
    defaultValue: '127.0.0.1',
  );
  static const int dbPort = int.fromEnvironment(
    'SOUMA_DB_PORT',
    defaultValue: 5432,
  );
  static const String dbName = String.fromEnvironment(
    'SOUMA_DB_NAME',
    defaultValue: 'souma_parfumerie',
  );
  static const String dbUser = String.fromEnvironment(
    'SOUMA_DB_USER',
    defaultValue: 'hassanechogar',
  );
  static const String dbPassword = String.fromEnvironment(
    'SOUMA_DB_PASSWORD',
    defaultValue: '',
  );

  static const String defaultApiBaseUrl = String.fromEnvironment(
    'SOUMA_API_URL',
    defaultValue:
        'http://localhost:8888/Souma%20Parfumerie/api/public',
  );

  /// Sync cloud LWS désactivée par défaut (PostgreSQL local uniquement).
  /// Activer au build : `--dart-define=SOUMA_CLOUD_SYNC=true`
  static const bool cloudSyncEnabled = bool.fromEnvironment(
    'SOUMA_CLOUD_SYNC',
    defaultValue: false,
  );

  static const String currencySymbol = 'FCFA';
  static const String deviceId = String.fromEnvironment(
    'SOUMA_DEVICE_ID',
    defaultValue: 'boutique-01',
  );
}
