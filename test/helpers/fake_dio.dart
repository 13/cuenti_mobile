import 'package:dio/dio.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {
  // ApiClient's constructor always calls `dio.interceptors.add(...)`, even
  // when a mocked Dio is injected via `dioOverride`. A bare `Mock` returns
  // null for un-stubbed getters, which crashes because `interceptors` is
  // non-nullable on the real `Dio` — so give it a real, harmless instance.
  @override
  final Interceptors interceptors = Interceptors();
}

/// Builds a dio Response for stubbing.
Response<T> ok<T>(T data, {int status = 200}) => Response<T>(
      requestOptions: RequestOptions(path: '/'),
      statusCode: status,
      data: data,
    );
