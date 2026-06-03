import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_player_flutter/services/api_service.dart';
import 'package:music_player_flutter/services/auth_service.dart';

class MockApiService extends Mock implements ApiService {}

void main() {
  late MockApiService api;
  late AuthService auth;

  setUp(() {
    api = MockApiService();
    auth = AuthService(api);
  });

  group('AuthService — beginwaarden', () {
    test('isAuthenticated is false bij aanmaak', () {
      expect(auth.isAuthenticated, false);
    });

    test('isAdmin is false bij aanmaak', () {
      expect(auth.isAdmin, false);
    });
  });

  group('AuthService.login', () {
    test('stelt isAuthenticated in bij succesvolle login zonder MFA', () async {
      when(() => api.login(any(), any())).thenAnswer(
        (_) async => {'success': true, 'isAdmin': false},
      );

      await auth.login('user@test.com', 'password');

      expect(auth.isAuthenticated, true);
      expect(auth.isAdmin, false);
    });

    test('stelt isAdmin in wanneer backend isAdmin true retourneert', () async {
      when(() => api.login(any(), any())).thenAnswer(
        (_) async => {'success': true, 'isAdmin': true},
      );

      await auth.login('admin@test.com', 'admin123');

      expect(auth.isAuthenticated, true);
      expect(auth.isAdmin, true);
    });

    test('stelt isAuthenticated niet in wanneer MFA vereist is', () async {
      when(() => api.login(any(), any())).thenAnswer(
        (_) async => {'success': true, 'mfaRequired': true, 'userId': 42, 'mfaType': 'email'},
      );

      final result = await auth.login('user@test.com', 'password');

      expect(auth.isAuthenticated, false);
      expect(result['mfaRequired'], true);
      expect(result['userId'], 42);
    });

    test('geeft exception door wanneer API een fout gooit', () async {
      when(() => api.login(any(), any())).thenThrow(Exception('Netwerk fout'));

      expect(() => auth.login('user@test.com', 'fout'), throwsException);
    });

    test('retourneert de ruwe response data', () async {
      when(() => api.login(any(), any())).thenAnswer(
        (_) async => {'success': true, 'isAdmin': false, 'token': 'abc123'},
      );

      final result = await auth.login('user@test.com', 'pass');

      expect(result['token'], 'abc123');
    });
  });

  group('AuthService.verifyMfa', () {
    test('stelt isAuthenticated in na succesvolle MFA verificatie', () async {
      when(() => api.verifyMfa(any(), any())).thenAnswer(
        (_) async => {'success': true, 'isAdmin': false},
      );

      await auth.verifyMfa(42, '123456');

      expect(auth.isAuthenticated, true);
    });

    test('stelt isAdmin in na succesvolle admin MFA verificatie', () async {
      when(() => api.verifyMfa(any(), any())).thenAnswer(
        (_) async => {'success': true, 'isAdmin': true},
      );

      await auth.verifyMfa(1, '000000');

      expect(auth.isAdmin, true);
    });

    test('gooit exception wanneer verificatie mislukt', () async {
      when(() => api.verifyMfa(any(), any())).thenAnswer(
        (_) async => {'success': false, 'message': 'Ongeldige code'},
      );

      expect(() => auth.verifyMfa(42, '999999'), throwsException);
      expect(auth.isAuthenticated, false);
    });

    test('gooit exception wanneer API een fout gooit', () async {
      when(() => api.verifyMfa(any(), any())).thenThrow(Exception('Time-out'));

      expect(() => auth.verifyMfa(42, '123456'), throwsException);
    });
  });

  group('AuthService.logout', () {
    setUp(() async {
      when(() => api.login(any(), any())).thenAnswer(
        (_) async => {'success': true, 'isAdmin': true},
      );
      await auth.login('admin@test.com', 'pass');
    });

    test('wist isAuthenticated na uitloggen', () async {
      when(() => api.logout()).thenAnswer((_) async {});

      await auth.logout();

      expect(auth.isAuthenticated, false);
    });

    test('wist isAdmin na uitloggen', () async {
      when(() => api.logout()).thenAnswer((_) async {});

      await auth.logout();

      expect(auth.isAdmin, false);
    });
  });

  group('AuthService.checkAuth', () {
    test('stelt isAuthenticated in bij actieve sessie', () async {
      when(() => api.checkAuth()).thenAnswer(
        (_) async => {'success': true, 'isAdmin': false},
      );

      await auth.checkAuth();

      expect(auth.isAuthenticated, true);
    });

    test('stelt isAdmin in bij actieve admin sessie', () async {
      when(() => api.checkAuth()).thenAnswer(
        (_) async => {'success': true, 'isAdmin': true},
      );

      await auth.checkAuth();

      expect(auth.isAdmin, true);
    });

    test('stelt isAuthenticated niet in bij geen actieve sessie', () async {
      when(() => api.checkAuth()).thenAnswer(
        (_) async => {'success': false},
      );

      await auth.checkAuth();

      expect(auth.isAuthenticated, false);
    });

    test('blijft uitgelogd wanneer API een fout gooit', () async {
      when(() => api.checkAuth()).thenThrow(Exception('Verbinding geweigerd'));

      await auth.checkAuth();

      expect(auth.isAuthenticated, false);
    });
  });
}
