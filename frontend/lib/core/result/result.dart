class AppException implements Exception {
  const AppException(this.message, [this.statusCode]);

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// Outcome of a data-layer call: either a value or an [AppException].
sealed class Result<T> {
  const Result();

  /// Runs [action], converting known failures into [Err].
  static Future<Result<T>> guard<T>(Future<T> Function() action) async {
    try {
      return Ok(await action());
    } on AppException catch (error) {
      return Err(error);
    } on FormatException {
      return const Err(AppException('ข้อมูลจากเซิร์ฟเวอร์ไม่ถูกต้อง'));
    } on TypeError {
      return const Err(AppException('ข้อมูลจากเซิร์ฟเวอร์ไม่ถูกต้อง'));
    }
  }

  R when<R>({
    required R Function(T value) ok,
    required R Function(AppException error) err,
  }) => switch (this) {
    Ok<T>(:final value) => ok(value),
    Err<T>(:final error) => err(error),
  };

  T? get valueOrNull => switch (this) {
    Ok<T>(:final value) => value,
    Err<T>() => null,
  };

  String? get errorMessage => switch (this) {
    Ok<T>() => null,
    Err<T>(:final error) => error.message,
  };
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);

  final T value;
}

final class Err<T> extends Result<T> {
  const Err(this.error);

  final AppException error;
}
