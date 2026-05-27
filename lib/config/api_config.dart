/// Runtime-конфиг API.
///
/// Передаётся через `--dart-define=API_BASE_URL=https://...` при сборке APK:
///
/// ```
/// flutter build apk --debug --dart-define=API_BASE_URL=https://modular-chef-production.up.railway.app
/// ```
///
/// Если пустая строка — клиент остаётся в offline-режиме и использует
/// `StubMenuGenerator` (детерминированный генератор без сети).
abstract final class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  /// Когда true — `HttpMenuGenerator` направит запросы на baseUrl;
  /// когда false — клиент работает оффлайн через `StubMenuGenerator`.
  static bool get isBackendConfigured => baseUrl.isNotEmpty;
}
