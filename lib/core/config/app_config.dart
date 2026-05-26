/// Application configuration constants.
///
/// Change [serverUrl] when switching between environments
/// (e.g., test vs production).
class AppConfig {
  AppConfig._();

  /// The base URL of the Open-WebUI server.
  ///
  /// Production environment: `https://chat.focusmedia.cn`
  /// Test environment: `https://1.94.62.87`
  static const String serverUrl = 'https://chat.focusmedia.cn';

  /// Whether to trust self-signed TLS certificates.
  ///
  /// Enable this for servers that use self-signed certificates
  /// (common in test environments with IP-based URLs).
  /// Production (`chat.focusmedia.cn`) uses a CA-signed cert, so leave this
  /// `false` — it lets the system trust store reject MITM attempts.
  /// Flip to `true` only when temporarily pointing `serverUrl` back at a
  /// self-signed test environment such as `https://1.94.62.87`.
  static const bool allowSelfSignedCertificates = false;
}
