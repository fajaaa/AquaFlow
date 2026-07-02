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
///   * Physical phone -> set [lanHostOverride] to the PC's LAN IP (see below)
///
/// The backend runs over plain HTTP (see AGENTS.md, http profile on port 5161),
/// so mobile platforms block cleartext traffic by default. DEV-ONLY exceptions
/// are added in android/app/src/debug/AndroidManifest.xml and
/// ios/Runner/Info.plist. In production the backend must be served over HTTPS
/// and those exceptions removed.
class ApiConfig {
  static const int port = 5161;

  /// Physical phone/tablet: set this to the PC's LAN IP so the device can reach
  /// the backend over Wi-Fi. Leave `null` for emulator / simulator / desktop /
  /// web (auto-detected below).
  ///
  /// NOTE: this is a machine-specific local dev value (Kenan's PC on Wi-Fi).
  /// Set it back to `null` when running on the Android emulator, and do not rely
  /// on it in committed code for other machines.
  // Type stays String? because this is a toggle: set back to null for emulator.
  // ignore: unnecessary_nullable_for_final_variable_declarations
  static const String? lanHostOverride = "192.168.18.5";

  static String get baseUrl {
    if (lanHostOverride != null) return "http://$lanHostOverride:$port";
    if (kIsWeb) return "http://localhost:$port";
    if (Platform.isAndroid) return "http://10.0.2.2:$port"; // Android emulator
    return "http://localhost:$port"; // iOS simulator, Windows, macOS, Linux
  }
}
