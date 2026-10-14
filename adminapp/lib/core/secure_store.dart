import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'constants.dart';

/// Secure token storage wrapping [FlutterSecureStorage].
///
/// Implements `ARCHITECTURE.md` §9 and `TASKS.md` 1B-1.
/// Strictly dedicated to sensitive credentials such as the admin JWT.
/// Never use SharedPreferences for authentication tokens.
class SecureStore {
  final FlutterSecureStorage _storage;

  /// Creates a [SecureStore] instance with optional injectable [FlutterSecureStorage].
  SecureStore({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(
                resetOnError: true,
              ),
            );

  /// Persists the admin JWT token securely.
  Future<void> saveToken(String token) async {
    await _storage.write(
      key: AppConstants.secureStorageJwtKey,
      value: token,
    );
  }

  /// Retrieves the persisted admin JWT token, or `null` if none exists.
  Future<String?> getToken() async {
    return await _storage.read(key: AppConstants.secureStorageJwtKey);
  }

  /// Deletes the admin JWT token from secure storage.
  Future<void> clearToken() async {
    await _storage.delete(key: AppConstants.secureStorageJwtKey);
  }

  /// Returns true if an admin JWT token exists.
  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
