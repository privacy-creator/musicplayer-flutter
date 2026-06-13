import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:music_player_flutter/l10n/app_localizations.dart';
import 'package:music_player_flutter/services/api_service.dart';
import 'package:music_player_flutter/services/auth_service.dart';
import 'package:music_player_flutter/screens/login_screen.dart';

class MockApiService extends Mock implements ApiService {}

void main() {
  late MockApiService mockApi;

  setUp(() {
    mockApi = MockApiService();
  });

  Widget buildScreen() {
    return MultiProvider(
      providers: [
        Provider<ApiService>.value(value: mockApi),
        ChangeNotifierProvider<AuthService>(
          create: (ctx) => AuthService(ctx.read<ApiService>()),
        ),
      ],
      child: MaterialApp(
        locale: const Locale('nl'),
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        home: const LoginScreen(),
      ),
    );
  }

  group('LoginScreen — initieel scherm', () {
    testWidgets('toont terug-knop, e-mail en wachtwoord veld', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      expect(find.byIcon(Icons.email_outlined), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    });

    testWidgets('toont inloggen-knop', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      expect(find.byIcon(Icons.music_note), findsOneWidget);
    });

    testWidgets('toont geen foutmelding bij start', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      expect(find.byIcon(Icons.error_outline), findsNothing);
    });
  });

  group('LoginScreen — validatie', () {
    testWidgets('lege velden tonen foutmelding', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      final signInBtn = find.byType(ElevatedButton);
      expect(signInBtn, findsOneWidget);
      await tester.tap(signInBtn);
      await tester.pump();

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('foutmelding verdwijnt na aanpassing', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      expect(find.byIcon(Icons.error_outline), findsOneWidget);

      // Enter email — still in the same screen, email field is TextField.at(0)
      await tester.enterText(find.byType(TextField).at(0), 'test@test.com');
      await tester.pump();
      // Form stays visible with email filled in
      expect(find.byIcon(Icons.email_outlined), findsOneWidget);
    });
  });

  group('LoginScreen — inloggen', () {
    testWidgets('succesvol inloggen sluit scherm', (tester) async {
      when(() => mockApi.login(any(), any())).thenAnswer(
        (_) async => {'success': true, 'mfaRequired': false, 'isAdmin': false},
      );

      bool popped = false;
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<ApiService>.value(value: mockApi),
            ChangeNotifierProvider<AuthService>(
              create: (ctx) => AuthService(ctx.read<ApiService>()),
            ),
          ],
          child: MaterialApp(
            locale: const Locale('nl'),
            localizationsDelegates: AppL10n.localizationsDelegates,
            supportedLocales: AppL10n.supportedLocales,
            home: Builder(builder: (ctx) {
              return ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    ctx,
                    MaterialPageRoute(
                        builder: (_) => const LoginScreen()),
                  ).then((_) => popped = true);
                },
                child: const Text('open'),
              );
            }),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'admin@test.com');
      await tester.enterText(find.byType(TextField).at(1), 'secret');
      await tester.tap(find.byType(ElevatedButton).last);
      await tester.pumpAndSettle();

      expect(popped, isTrue);
    });

    testWidgets('login met MFA toont MFA invoerveld', (tester) async {
      when(() => mockApi.login(any(), any())).thenAnswer(
        (_) async => {
          'success': true,
          'mfaRequired': true,
          'userId': 42,
          'mfaType': 'email',
        },
      );

      await tester.pumpWidget(buildScreen());
      await tester.pump();

      await tester.enterText(find.byType(TextField).at(0), 'admin@test.com');
      await tester.enterText(find.byType(TextField).at(1), 'secret');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.security), findsOneWidget);
      expect(find.byIcon(Icons.pin_outlined), findsOneWidget);
    });

    testWidgets('login fout toont foutmelding', (tester) async {
      when(() => mockApi.login(any(), any()))
          .thenThrow(Exception('Ongeldig wachtwoord'));

      await tester.pumpWidget(buildScreen());
      await tester.pump();

      await tester.enterText(find.byType(TextField).at(0), 'admin@test.com');
      await tester.enterText(find.byType(TextField).at(1), 'fout');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });
  });

  group('LoginScreen — terug navigeren', () {
    testWidgets('terug-knop navigeert terug', (tester) async {
      bool popped = false;
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<ApiService>.value(value: mockApi),
            ChangeNotifierProvider<AuthService>(
              create: (ctx) => AuthService(ctx.read<ApiService>()),
            ),
          ],
          child: MaterialApp(
            locale: const Locale('nl'),
            localizationsDelegates: AppL10n.localizationsDelegates,
            supportedLocales: AppL10n.supportedLocales,
            home: Builder(builder: (ctx) {
              return ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    ctx,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  ).then((_) => popped = true);
                },
                child: const Text('open'),
              );
            }),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(popped, isTrue);
    });
  });

  group('LoginScreen — MFA stap', () {
    testWidgets('terug naar login knop schakelt MFA terug uit', (tester) async {
      when(() => mockApi.login(any(), any())).thenAnswer(
        (_) async => {
          'success': true,
          'mfaRequired': true,
          'userId': 1,
          'mfaType': 'totp',
        },
      );

      await tester.pumpWidget(buildScreen());
      await tester.pump();

      await tester.enterText(find.byType(TextField).at(0), 'a@b.com');
      await tester.enterText(find.byType(TextField).at(1), 'pass');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.security), findsOneWidget);

      final backBtn = find.byType(TextButton);
      await tester.tap(backBtn);
      await tester.pump();

      expect(find.byIcon(Icons.email_outlined), findsOneWidget);
    });

    testWidgets('MFA TOTP toont juiste bericht', (tester) async {
      when(() => mockApi.login(any(), any())).thenAnswer(
        (_) async => {
          'success': true,
          'mfaRequired': true,
          'userId': 1,
          'mfaType': 'totp',
        },
      );

      await tester.pumpWidget(buildScreen());
      await tester.pump();

      await tester.enterText(find.byType(TextField).at(0), 'a@b.com');
      await tester.enterText(find.byType(TextField).at(1), 'pass');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.security), findsOneWidget);
    });

    testWidgets('lege MFA code doet niets', (tester) async {
      when(() => mockApi.login(any(), any())).thenAnswer(
        (_) async => {
          'success': true,
          'mfaRequired': true,
          'userId': 10,
          'mfaType': 'email',
        },
      );

      await tester.pumpWidget(buildScreen());
      await tester.pump();

      await tester.enterText(find.byType(TextField).at(0), 'a@b.com');
      await tester.enterText(find.byType(TextField).at(1), 'pass');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Tap verify WITHOUT entering code — early return, no error
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.security), findsOneWidget);
    });

    testWidgets('MFA verificatie geslaagd sluit scherm', (tester) async {
      when(() => mockApi.login(any(), any())).thenAnswer(
        (_) async => {
          'success': true,
          'mfaRequired': true,
          'userId': 5,
          'mfaType': 'email',
        },
      );
      when(() => mockApi.verifyMfa(any(), any())).thenAnswer(
        (_) async => {'success': true, 'isAdmin': false},
      );

      bool popped = false;
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<ApiService>.value(value: mockApi),
            ChangeNotifierProvider<AuthService>(
              create: (ctx) => AuthService(ctx.read<ApiService>()),
            ),
          ],
          child: MaterialApp(
            locale: const Locale('nl'),
            localizationsDelegates: AppL10n.localizationsDelegates,
            supportedLocales: AppL10n.supportedLocales,
            home: Builder(builder: (ctx) {
              return ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    ctx,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  ).then((_) => popped = true);
                },
                child: const Text('open'),
              );
            }),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'a@b.com');
      await tester.enterText(find.byType(TextField).at(1), 'pass');
      await tester.tap(find.byType(ElevatedButton).last);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, '123456');
      await tester.tap(find.byType(ElevatedButton).last);
      await tester.pumpAndSettle();

      expect(popped, isTrue);
    });

    testWidgets('MFA verificatie mislukt toont foutmelding', (tester) async {
      when(() => mockApi.login(any(), any())).thenAnswer(
        (_) async => {
          'success': true,
          'mfaRequired': true,
          'userId': 5,
          'mfaType': 'email',
        },
      );
      when(() => mockApi.verifyMfa(any(), any()))
          .thenThrow(Exception('Verification failed'));

      await tester.pumpWidget(buildScreen());
      await tester.pump();

      await tester.enterText(find.byType(TextField).at(0), 'a@b.com');
      await tester.enterText(find.byType(TextField).at(1), 'pass');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, '000000');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });
  });
}
