import 'package:flutter/foundation.dart';

/// Core application constants and network configuration.
///
/// Implements `ARCHITECTURE.md` §4 and §9, and `PROJECT_CONTEXT.md` §6.
class AppConstants {
  // DEV ONLY — Tailscale IP, replace with production URL before
  // Launch-3. See PROJECT_CONTEXT.md §6 and ARCHITECTURE.md §9.
  static const String devApiBaseUrl = 'http://100.112.216.27:3000';

  // TODO: Set production API base URL at Launch-3 once backend is deployed.
  static const String prodApiBaseUrl = 'https://sliceandserve.vercel.app/';

  /// Active base URL selected based on build mode or runtime configuration.
  static String get apiBaseUrl {
    if (kDebugMode) {
      return devApiBaseUrl;
    }
    return prodApiBaseUrl.isNotEmpty ? prodApiBaseUrl : devApiBaseUrl;
  }

  /// Network request timeouts
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
  static const Duration sendTimeout = Duration(seconds: 15);

  /// Key used by [SecureStore] to persist the admin JWT
  static const String secureStorageJwtKey = 'admin_jwt_token';
}
