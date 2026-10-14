import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_client.dart';
import '../core/result.dart';
import '../core/secure_store.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';

/// Provider for the singleton/injectable [SecureStore].
final secureStoreProvider = Provider<SecureStore>((ref) {
  return SecureStore();
});

/// Provider for the singleton/injectable [ApiClient].
final apiClientProvider = Provider<ApiClient>((ref) {
  final secureStore = ref.watch(secureStoreProvider);
  final client = ApiClient(customSecureStore: secureStore);
  ref.onDispose(() => client.dispose());
  return client;
});

/// Provider for [AuthService].
final authServiceProvider = Provider<AuthService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final secureStore = ref.watch(secureStoreProvider);
  return AuthService(apiClient: apiClient, secureStore: secureStore);
});

/// Provider for [NotificationService].
final notificationServiceProvider = Provider<NotificationService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final service = NotificationService(apiClient: apiClient);
  ref.onDispose(() => service.dispose());
  return service;
});

/// Riverpod AsyncNotifier managing the administrative authentication state.
///
/// Implements `ARCHITECTURE.md` §7, `CODING_STANDARDS.md` §2, and `TASKS.md` 1B-2.
/// - State represents the active JWT token (`String?`), or `null` if unauthenticated.
/// - Listens to central 401 unauthorization signals to reset session state.
/// - Exposes [login] and [logout] workflows.
class AuthNotifier extends AsyncNotifier<String?> {
  @override
  FutureOr<String?> build() async {
    final client = ref.watch(apiClientProvider);
    final sub = client.onUnauthorized.listen((_) {
      state = const AsyncValue.data(null);
    });
    ref.onDispose(() => sub.cancel());

    final authService = ref.watch(authServiceProvider);
    final hasSession = await authService.hasValidSession();
    if (hasSession) {
      final token = await ref.watch(secureStoreProvider).getToken();
      if (token != null && token.isNotEmpty) {
        unawaited(
          ref.read(notificationServiceProvider).initializeAndRegister(),
        );
      }
      return token;
    }
    return null;
  }

  /// Submits credentials to `POST /api/admin/login` and updates the provider state.
  Future<Result<String>> login(String username, String password) async {
    state = const AsyncValue.loading();
    final authService = ref.read(authServiceProvider);
    final result = await authService.login(username, password);

    result.when(
      success: (token) {
        state = AsyncValue.data(token);
        // Register FCM device token upon successful login (Task Push-1, PRD A-30)
        unawaited(
          ref.read(notificationServiceProvider).initializeAndRegister(),
        );
      },
      failure: (message, statusCode, errorCode) {
        state = AsyncValue.error(message, StackTrace.current);
      },
    );

    return result;
  }

  /// Clears stored credentials and resets state to unauthenticated.
  Future<void> logout() async {
    state = const AsyncValue.loading();
    final authService = ref.read(authServiceProvider);
    ref.read(notificationServiceProvider).dispose();
    await authService.logout();
    state = const AsyncValue.data(null);
  }
}

/// The global auth provider watched across the admin application.
final authProvider = AsyncNotifierProvider<AuthNotifier, String?>(() {
  return AuthNotifier();
});
