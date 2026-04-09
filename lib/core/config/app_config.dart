/// Application configuration constants.
///
/// Change [serverUrl] when switching between environments
/// (e.g., test vs production).
class AppConfig {
  AppConfig._();

  /// The base URL of the Open-WebUI server.
  ///
  /// Test environment: `https://1.94.62.87`
  /// Production environment: update this value accordingly.
  static const String serverUrl = 'https://1.94.62.87';

  /// Whether to trust self-signed TLS certificates.
  ///
  /// Enable this for servers that use self-signed certificates
  /// (common in test environments with IP-based URLs).
  static const bool allowSelfSignedCertificates = true;
}
