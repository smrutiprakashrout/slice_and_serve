import 'package:flutter/foundation.dart';

/// Core application constants and network configuration.
///
/// Implements `ARCHITECTURE.md` §4 and §9, and `PROJECT_CONTEXT.md` §6.
class AppConstants {
  // DEV ONLY — Tailscale IP for local developer testing.
  // See PROJECT_CONTEXT.md §6 and ARCHITECTURE.md §9.
  static const String devApiBaseUrl = '';

  // Production API base URL (Vercel deployment)
  static const String prodApiBaseUrl = 'https://sliceandserve.vercel.app';

  /// Active base URL selected based on build mode.
  ///
  /// In debug mode (kDebugMode == true), routes to the local/Tailscale dev server.
  /// In release mode (kDebugMode == false), strictly routes to production.
  static String get apiBaseUrl {
    if (kDebugMode) {
      return devApiBaseUrl;
    }
    return prodApiBaseUrl;
  }

  /// Network request timeouts
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
  static const Duration sendTimeout = Duration(seconds: 15);

  /// Key used by [SecureStore] to persist the admin JWT
  static const String secureStorageJwtKey = 'admin_jwt_token';
}
