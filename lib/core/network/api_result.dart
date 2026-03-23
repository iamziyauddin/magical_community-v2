sealed class ApiResult<T> {
  const ApiResult();

  R when<R>({
    required R Function(T data) success,
    required R Function(String message, int? statusCode) failure,
  });
}

class ApiSuccess<T> extends ApiResult<T> {
  final T data;
  const ApiSuccess(this.data);

  @override
  R when<R>({
    required R Function(T data) success,
    required R Function(String message, int? statusCode) failure,
  }) => success(data);
}

class ApiFailure<T> extends ApiResult<T> {
  final String message;
  final int? statusCode;
  const ApiFailure(this.message, {this.statusCode});

  @override
  R when<R>({
    required R Function(T data) success,
    required R Function(String message, int? statusCode) failure,
  }) => failure(message, statusCode);
}
