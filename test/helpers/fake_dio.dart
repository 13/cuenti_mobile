import 'package:dio/dio.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

/// Builds a dio Response for stubbing.
Response<T> ok<T>(T data, {int status = 200}) => Response<T>(
      requestOptions: RequestOptions(path: '/'),
      statusCode: status,
      data: data,
    );
