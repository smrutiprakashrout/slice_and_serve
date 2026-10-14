import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../core/result.dart';
import '../core/secure_store.dart';

/// Authentication service managing admin login, session restoration, and token persistence.
///
/// Implements `ARCHITECTURE.md` §4, §5.1 and `PRD.md` §3.1 (A-1, A-3, A-4).
class AuthService {
  final ApiClient _apiClient;
  final SecureStore _secureStore;

  AuthService({
    ApiClient? apiClient,
    SecureStore? secureStore,
  })  : _secureStore = secureStore ?? apiClient?.secureStore ?? SecureStore(),
        _apiClient = apiClient ??
            ApiClient(
              customSecureStore:
                  secureStore ?? apiClient?.secureStore ?? SecureStore(),
            );

  /// Authenticates with the backend via `POST /api/admin/login`.
  ///
  /// Request shape:
  /// ```json
  /// { "username": "<username>", "password": "<password>" }
  /// ```
  /// Response on 200:
  /// ```json
  /// { "token": "<jwt>" }
  /// ```
  /// On success, extracts and persists JWT to [SecureStore] and returns [Result.success].
  /// On failure, catches error and returns [Result.failure] with safe, friendly message:
  /// - 401: "Invalid username or password."
  /// - Any other error: "Something went wrong, please try again."
  Future<Result<String>> login(String username, String password) async {
    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        '/api/admin/login',
        data: {
          'username': username,
          'password': password,
        },
      );

      final data = response.data;
      final token = data?['token'];
      if (token is String && token.isNotEmpty) {
        await _secureStore.saveToken(token);
        return Result.success(token);
      } else {
        return const Result.failure('Something went wrong, please try again.');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return const Result.failure(
          'Invalid username or password.',
          statusCode: 401,
          errorCode: 'INVALID_CREDENTIALS',
        );
      }
      return Result.failure(
        'Something went wrong, please try again.',
        statusCode: e.response?.statusCode,
      );
    } catch (_) {
      return const Result.failure('Something went wrong, please try again.');
    }
  }

  /// Checks if an existing JWT token is saved in secure storage.
  /// Used for cold-start session restore decisions per `PRD.md` A-4.
  Future<bool> hasValidSession() async {
    return await _secureStore.hasToken();
  }

  /// Clears stored token from secure storage.
  Future<void> logout() async {
    await _secureStore.clearToken();
  }
}
