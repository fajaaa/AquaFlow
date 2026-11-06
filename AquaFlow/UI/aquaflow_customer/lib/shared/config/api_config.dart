import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Central place for the backend base URL.
///
/// Never hardcode the host anywhere else in the app - always read
/// [ApiConfig.baseUrl]. The host is chosen automatically per platform so the
/// same code runs on Windows/macOS/Linux desktop, the Android emulator, the
/// iOS simulator, the web and physical phones.
///
/// Platform mapping:
///   * Android emulator -> 10.0.2.2 (the emulator's alias for the host machine)
///   * iOS simulator / desktop / web -> localhost
///   * Physical phone -> run with
///     `--dart-define=API_BASE_URL=http://<PC-LAN-IP>:5161`; no IP is ever
///     committed to the repository
///
/// The backend runs over plain HTTP (see AGENTS.md, http profile on port 5161),
/// so mobile platforms block cleartext traffic by default. DEV-ONLY exceptions
/// are added in android/app/src/debug/AndroidManifest.xml and
/// ios/Runner/Info.plist. In production the backend must be served over HTTPS
/// and those exceptions removed.
class ApiConfig {
  static const int port = 5161;

  /// Optional compile-time override, set with `--dart-define=API_BASE_URL=...`.
  static const String _baseUrlOverride = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_baseUrlOverride.isNotEmpty) {
      return _baseUrlOverride.endsWith('/')
          ? _baseUrlOverride.substring(0, _baseUrlOverride.length - 1)
          : _baseUrlOverride;
    }
    if (kIsWeb) return "http://localhost:$port";
    if (Platform.isAndroid) return "http://10.0.2.2:$port"; // Android emulator
    return "http://localhost:$port"; // iOS simulator, Windows, macOS, Linux
  }
}
