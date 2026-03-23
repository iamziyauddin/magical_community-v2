import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import '../config/env.dart';
import 'auth_interceptor.dart';

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  Dio? _dio;

  /// Simple retry interceptor: retries once on connection/receive timeout
  /// Useful for flaky networks. Keeps it minimal to avoid heavy deps.
  static Interceptor _retryOnTimeout(Dio dio) =>
      _RetryOnTimeoutInterceptor(dio);

  Dio get dio {
    if (_dio != null) return _dio!;

    final options = BaseOptions(
      baseUrl: Env.finalApiBaseUrl,
      connectTimeout: Duration(milliseconds: Env.connectTimeoutMs),
      receiveTimeout: Duration(milliseconds: Env.receiveTimeoutMs),
      contentType: 'application/json',
      responseType: ResponseType.json,
    );

    final client = Dio(options);

    client.interceptors.add(AuthInterceptor());
    client.interceptors.add(_retryOnTimeout(client));
    client.interceptors.add(
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseHeader: false,
        responseBody: true,
        error: true,
        compact: true,
        maxWidth: 90,
      ),
    );

    _dio = client;
    return client;
  }
}

class _RetryOnTimeoutInterceptor extends Interceptor {
  _RetryOnTimeoutInterceptor(this._dio);

  final Dio _dio;
  final int maxRetries = 1;
  final Duration retryDelay = const Duration(seconds: 1);

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final isTimeout =
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionTimeout;
    if (!isTimeout) return handler.next(err);

    final req = err.requestOptions;
    final attempt = (req.extra['retry_attempt'] as int?) ?? 0;
    if (attempt >= maxRetries) return handler.next(err);

    // Schedule a single retry
    await Future.delayed(retryDelay);
    try {
      req.extra['retry_attempt'] = attempt + 1;
      final response = await _dio.fetch(req);
      return handler.resolve(response);
    } catch (_) {
      return handler.next(err);
    }
  }
}
