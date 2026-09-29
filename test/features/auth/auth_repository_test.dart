import 'package:cuentimobile/core/api/api_client.dart';
import 'package:cuentimobile/core/api/api_exception.dart';
import 'package:cuentimobile/core/storage/secure_storage.dart';
import 'package:cuentimobile/features/auth/data/auth_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import '../../helpers/fake_dio.dart';

class MemoryStorage extends SecureStorage {
  MemoryStorage() : super();
  final Map<String, String> _data = {};
  @override
  Future<String?> read(String key) async => _data[key];
  @override
  Future<void> write(String key, String value) async => _data[key] = value;
  @override
  Future<void> delete(String key) async => _data.remove(key);
}

void main() {
  late MockDio dio;
  late ApiClient client;
  late AuthRepository repo;

  setUp(() {
    dio = MockDio();
    client = ApiClient(MemoryStorage(), dioOverride: dio);
    repo = AuthRepository(client);
  });

  test('login saves token and returns profile', () async {
    when(
      () => dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: any(named: 'data'),
      ),
    ).thenAnswer(
      (_) async => ok({
        'token': 'jwt-abc',
        'username': 'demo',
        'email': 'd@x',
        'firstName': 'D',
        'lastName': 'M',
        'roles': ['ROLE_USER'],
      }),
    );

    final user = await repo.login('demo', 'pw');

    expect(user.username, 'demo');
    expect(await client.getToken(), 'jwt-abc');
  });

  test(
    'login asks for a refresh token, sends the code, keeps both tokens',
    () async {
      when(
        () => dio.post<Map<String, dynamic>>(
          '/auth/login',
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => ok({
          'token': 'jwt-abc',
          'refreshToken': 'refresh-abc',
          'username': 'demo',
        }),
      );

      await repo.login('demo', 'pw', code: '123456');

      final sent =
          verify(
                () => dio.post<Map<String, dynamic>>(
                  '/auth/login',
                  data: captureAny(named: 'data'),
                ),
              ).captured.single
              as Map<String, dynamic>;
      expect(sent['refresh'], true);
      expect(sent['code'], '123456');
      expect(await client.getToken(), 'jwt-abc');
    },
  );

  for (final (body, expected) in [
    ({'error': 'two_factor_required'}, twoFactorRequiredMessage),
    ({'error': 'invalid_code'}, invalidCodeMessage),
  ]) {
    test('login maps a 401 ${body['error']} body', () async {
      when(
        () => dio.post<Map<String, dynamic>>(
          '/auth/login',
          data: any(named: 'data'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/auth/login'),
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: RequestOptions(path: '/auth/login'),
            statusCode: 401,
            data: body,
          ),
        ),
      );

      expect(
        () => repo.login('demo', 'pw'),
        throwsA(
          isA<UnauthorizedException>().having(
            (e) => e.message,
            'message',
            expected,
          ),
        ),
      );
    });
  }

  test('login maps 401 to UnauthorizedException', () async {
    when(
      () => dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: any(named: 'data'),
      ),
    ).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/auth/login'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/auth/login'),
          statusCode: 401,
        ),
      ),
    );

    expect(
      () => repo.login('demo', 'bad'),
      throwsA(
        isA<UnauthorizedException>().having(
          (e) => e.message,
          'message',
          'Invalid username or password',
        ),
      ),
    );
  });

  test('logout clears token', () async {
    await client.saveToken('t');
    await repo.logout();
    expect(await client.hasToken(), false);
  });
}
