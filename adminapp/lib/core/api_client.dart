import 'dart:async';
import 'package:dio/dio.dart';
import 'constants.dart';
import 'result.dart';
import 'secure_store.dart';

/// Central HTTP API Client built on top of [Dio].
///
/// Implements `ARCHITECTURE.md` §4, §5.1, §9 and `CODING_STANDARDS.md` §1.
/// Handles:
/// - Base URL configuration (dev/prod split)
/// - Timeouts
/// - JWT authentication header attachment via request interceptor
/// - Central 401 handling: clears stored token and notifies listeners without UI imports
/// - DioException to [Failure] parsing
class ApiClient {
  final Dio dio;
  final SecureStore secureStore;

  /// Broadcast stream notifying listeners whenever a 401 Unauthorized response is received.
  /// Top-level app or auth provider listens to this stream to navigate to the login screen.
  final StreamController<void> _unauthorizedController =
      StreamController<void>.broadcast();

  Stream<void> get onUnauthorized => _unauthorizedController.stream;

  /// Optional callback invoked on 401 Unauthorized.
  void Function()? onUnauthorizedCallback;

  ApiClient({
    Dio? customDio,
    SecureStore? customSecureStore,
    String? baseUrl,
  })  : secureStore = customSecureStore ?? SecureStore(),
        dio = customDio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl ?? AppConstants.apiBaseUrl,
                connectTimeout: AppConstants.connectTimeout,
                receiveTimeout: AppConstants.receiveTimeout,
                sendTimeout: AppConstants.sendTimeout,
                headers: {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                },
              ),
            ) {
    _setupInterceptors();
  }

  void _setupInterceptors() {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Do not attach token for login endpoint or if Authorization is already set
          final isLoginEndpoint = options.path.endsWith('/api/admin/login');
          final hasAuthHeader = options.headers.containsKey('Authorization');

          if (!isLoginEndpoint && !hasAuthHeader) {
            final token = await secureStore.getToken();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          final isLoginEndpoint =
              error.requestOptions.path.endsWith('/api/admin/login');
          if (error.response?.statusCode == 401 && !isLoginEndpoint) {
            // Central 401 on protected requests: clear persisted token and notify listeners
            await secureStore.clearToken();
            if (!_unauthorizedController.isClosed) {
              _unauthorizedController.add(null);
            }
            onUnauthorizedCallback?.call();
          }
          return handler.next(error);
        },
      ),
    );
  }

  /// Parses a [DioException] into a domain [Failure] with backend error message and code.
  ///
  /// Conforms to `ARCHITECTURE.md` §4 error envelope:
  /// ```json
  /// {
  ///   "error": {
  ///     "code": "INVALID_TRANSITION",
  ///     "message": "Cannot complete a pending order."
  ///   }
  /// }
  /// ```
  static Failure<T> failureFromDioException<T>(DioException error) {
    final statusCode = error.response?.statusCode;
    String? errorCode;
    String? errorMessage;

    final responseData = error.response?.data;
    if (responseData is Map<String, dynamic>) {
      final errorObj = responseData['error'];
      if (errorObj is Map<String, dynamic>) {
        if (errorObj['message'] is String) {
          errorMessage = errorObj['message'] as String;
        }
        if (errorObj['code'] is String) {
          errorCode = errorObj['code'] as String;
        }
      } else if (errorObj is String) {
        errorMessage = errorObj;
      } else if (responseData['message'] is String) {
        errorMessage = responseData['message'] as String;
      }
    } else if (responseData is String && responseData.isNotEmpty) {
      errorMessage = responseData;
    }

    if (errorMessage == null || errorMessage.trim().isEmpty) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          errorMessage =
              'Connection timed out. Please check your internet connection.';
          break;
        case DioExceptionType.connectionError:
          errorMessage =
              'Unable to reach the server. Please check your internet connection.';
          break;
        case DioExceptionType.cancel:
          errorMessage = 'Request was cancelled.';
          break;
        case DioExceptionType.badResponse:
          if (statusCode == 401) {
            errorMessage = 'Session expired or unauthorized. Please log in again.';
          } else if (statusCode == 403) {
            errorMessage = 'Access forbidden.';
          } else if (statusCode == 404) {
            errorMessage = 'Requested resource not found.';
          } else if (statusCode != null && statusCode >= 500) {
            errorMessage = 'Server error ($statusCode). Please try again later.';
          } else {
            errorMessage = 'Request failed with status code $statusCode.';
          }
          break;
        default:
          errorMessage = 'An unexpected network error occurred.';
          break;
      }
    }

    return Failure<T>(
      errorMessage,
      statusCode: statusCode,
      errorCode: errorCode,
    );
  }

  /// Disposes the unauthorized stream controller.
  void dispose() {
    _unauthorizedController.close();
  }
}
