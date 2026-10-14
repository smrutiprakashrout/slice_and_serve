/// A sealed Result type representing either a successful outcome or a failure.
///
/// Implements `CODING_STANDARDS.md` §1 (Error handling & `Result<T>` pattern).
/// Used across all Stage B services to prevent raw exceptions from reaching the UI.
sealed class Result<T> {
  const Result();

  /// Successful result containing [data].
  const factory Result.success(T data) = Success<T>;

  /// Failed result containing an [errorMessage], optional HTTP [statusCode],
  /// and optional backend [errorCode].
  const factory Result.failure(
    String errorMessage, {
    int? statusCode,
    String? errorCode,
  }) = Failure<T>;

  /// Whether this result represents a successful operation.
  bool get isSuccess => this is Success<T>;

  /// Whether this result represents a failed operation.
  bool get isFailure => this is Failure<T>;

  /// Returns the data if successful, or null otherwise.
  T? get dataOrNull => switch (this) {
        Success(data: final d) => d,
        Failure() => null,
      };

  /// Returns the error message if a failure, or null otherwise.
  String? get errorOrNull => switch (this) {
        Success() => null,
        Failure(errorMessage: final m) => m,
      };

  /// Transforms the data using [fn] if successful, returning a new [Result].
  Result<R> map<R>(R Function(T data) fn) {
    return switch (this) {
      Success(data: final d) => Result.success(fn(d)),
      Failure(
        errorMessage: final m,
        statusCode: final sc,
        errorCode: final ec
      ) =>
        Result.failure(m, statusCode: sc, errorCode: ec),
    };
  }

  /// Pattern matching handler executing [success] or [failure].
  R when<R>({
    required R Function(T data) success,
    required R Function(String message, int? statusCode, String? errorCode)
        failure,
  }) {
    return switch (this) {
      Success(data: final d) => success(d),
      Failure(
        errorMessage: final m,
        statusCode: final sc,
        errorCode: final ec
      ) =>
        failure(m, sc, ec),
    };
  }
}

/// Represents a successful result with data of type [T].
final class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);

  @override
  String toString() => 'Result.success($data)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Success<T> && other.data == data);

  @override
  int get hashCode => data.hashCode;
}

/// Represents a failed operation with an error message and metadata.
final class Failure<T> extends Result<T> {
  final String errorMessage;
  final int? statusCode;
  final String? errorCode;

  const Failure(this.errorMessage, {this.statusCode, this.errorCode});

  @override
  String toString() =>
      'Result.failure(message: "$errorMessage", statusCode: $statusCode, errorCode: "$errorCode")';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Failure<T> &&
          other.errorMessage == errorMessage &&
          other.statusCode == statusCode &&
          other.errorCode == errorCode);

  @override
  int get hashCode => Object.hash(errorMessage, statusCode, errorCode);
}
