import 'package:cuentimobile/core/api/api_exception.dart';
import 'package:cuentimobile/features/user/data/user_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import '../../helpers/fake_dio.dart';

void main() {
  late MockDio dio;
  late UserRepository repo;

  setUp(() {
    dio = MockDio();
    repo = UserRepository(dio);
  });

  test('getProfile parses profile JSON', () async {
    when(() => dio.get<Map<String, dynamic>>('/user/profile'))
        .thenAnswer((_) async => ok({
              'id': 1,
              'username': 'ben',
              'email': 'ben@example.com',
              'firstName': 'Ben',
              'lastName': 'Egger',
              'defaultCurrency': 'EUR',
              'darkMode': true,
              'locale': 'de-DE',
              'apiEnabled': false,
              'roles': ['ROLE_USER'],
            }));

    final profile = await repo.getProfile();

    expect(profile.id, 1);
    expect(profile.username, 'ben');
    expect(profile.email, 'ben@example.com');
    expect(profile.firstName, 'Ben');
    expect(profile.lastName, 'Egger');
    expect(profile.defaultCurrency, 'EUR');
    expect(profile.darkMode, true);
    expect(profile.locale, 'de-DE');
    expect(profile.apiEnabled, false);
    expect(profile.roles, {'ROLE_USER'});
    expect(profile.isAdmin, false);
  });

  test('getProfile maps DioException to ApiException', () async {
    when(() => dio.get<Map<String, dynamic>>('/user/profile')).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/user/profile'),
        type: DioExceptionType.connectionError,
      ),
    );

    expect(() => repo.getProfile(), throwsA(isA<NetworkException>()));
  });

  test('updateProfile PUTs exactly email/firstName/lastName', () async {
    when(() => dio.put<Map<String, dynamic>>('/user/profile',
            data: any(named: 'data')))
        .thenAnswer((_) async => ok({
              'id': 1,
              'username': 'ben',
              'email': 'new@example.com',
              'firstName': 'New',
              'lastName': 'Name',
            }));

    final profile = await repo.updateProfile(
      email: 'new@example.com',
      firstName: 'New',
      lastName: 'Name',
    );

    expect(profile.email, 'new@example.com');
    final captured = verify(() => dio.put<Map<String, dynamic>>('/user/profile',
            data: captureAny(named: 'data')))
        .captured
        .single as Map<String, dynamic>;
    expect(captured, {
      'email': 'new@example.com',
      'firstName': 'New',
      'lastName': 'Name',
    });
  });

  test('updatePassword PUTs old and new password', () async {
    when(() => dio.put<void>('/user/password', data: any(named: 'data')))
        .thenAnswer((_) async => ok(null));

    await repo.updatePassword('old', 'newPw');

    final captured = verify(() =>
            dio.put<void>('/user/password', data: captureAny(named: 'data')))
        .captured
        .single as Map<String, dynamic>;
    expect(captured, {'oldPassword': 'old', 'newPassword': 'newPw'});
  });

  test('updatePreferences sends only the provided sparse keys', () async {
    when(() => dio.put<Map<String, dynamic>>('/user/preferences',
            data: any(named: 'data')))
        .thenAnswer((_) async => ok({
              'id': 1,
              'username': 'ben',
              'darkMode': false,
            }));

    final profile = await repo.updatePreferences({'darkMode': false});

    expect(profile.darkMode, false);
    final captured = verify(() => dio.put<Map<String, dynamic>>(
            '/user/preferences',
            data: captureAny(named: 'data')))
        .captured
        .single as Map<String, Object?>;
    expect(captured, {'darkMode': false});
  });

  test('updatePreferences passes through a different subset unmodified',
      () async {
    when(() => dio.put<Map<String, dynamic>>('/user/preferences',
            data: any(named: 'data')))
        .thenAnswer((_) async => ok({'id': 1, 'username': 'ben'}));

    await repo.updatePreferences({'defaultCurrency': 'USD', 'locale': 'en-US'});

    final captured = verify(() => dio.put<Map<String, dynamic>>(
            '/user/preferences',
            data: captureAny(named: 'data')))
        .captured
        .single as Map<String, Object?>;
    expect(captured, {'defaultCurrency': 'USD', 'locale': 'en-US'});
  });

  test('getAllUsers parses list of profiles', () async {
    when(() => dio.get<List<dynamic>>('/user/admin/users')).thenAnswer(
        (_) async => ok([
              {'id': 1, 'username': 'ben', 'roles': ['ROLE_ADMIN']},
              {'id': 2, 'username': 'jane', 'roles': <String>[]},
            ]));

    final users = await repo.getAllUsers();

    expect(users, hasLength(2));
    expect(users[0].username, 'ben');
    expect(users[0].isAdmin, true);
    expect(users[1].username, 'jane');
    expect(users[1].isAdmin, false);
  });

  test('setUserEnabled PUTs enabled flag to the user endpoint', () async {
    when(() => dio.put<void>('/user/admin/users/5/enabled',
            data: any(named: 'data')))
        .thenAnswer((_) async => ok(null));

    await repo.setUserEnabled(5, false);

    verify(() => dio.put<void>('/user/admin/users/5/enabled',
        data: {'enabled': false})).called(1);
  });

  test('deleteUser calls DELETE on the user endpoint', () async {
    when(() => dio.delete<void>('/user/admin/users/7'))
        .thenAnswer((_) async => ok(null));

    await repo.deleteUser(7);

    verify(() => dio.delete<void>('/user/admin/users/7')).called(1);
  });

  test('getAdminSettings maps JSON to an admin settings record', () async {
    when(() => dio.get<Map<String, dynamic>>('/user/admin/settings'))
        .thenAnswer((_) async => ok({
              'registrationEnabled': false,
              'apiEnabled': true,
            }));

    final settings = await repo.getAdminSettings();

    expect(settings.registrationEnabled, false);
    expect(settings.apiEnabled, true);
  });

  test('getAdminSettings defaults missing fields', () async {
    when(() => dio.get<Map<String, dynamic>>('/user/admin/settings'))
        .thenAnswer((_) async => ok(<String, dynamic>{}));

    final settings = await repo.getAdminSettings();

    expect(settings.registrationEnabled, true);
    expect(settings.apiEnabled, false);
  });

  test('updateAdminSettings sends only the provided sparse fields', () async {
    when(() => dio.put<void>('/user/admin/settings', data: any(named: 'data')))
        .thenAnswer((_) async => ok(null));

    await repo.updateAdminSettings(apiEnabled: true);

    verify(() => dio.put<void>('/user/admin/settings',
        data: {'apiEnabled': true})).called(1);
  });
}
