import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:music_player_flutter/l10n/app_localizations.dart';
import 'package:music_player_flutter/services/api_service.dart';
import 'package:music_player_flutter/services/auth_service.dart';
import 'package:music_player_flutter/widgets/global_app_bar_actions.dart';

class MockApiService extends Mock implements ApiService {}

Widget _wrap(AuthService authService) {
  return ChangeNotifierProvider<AuthService>.value(
    value: authService,
    child: MaterialApp(
      locale: const Locale('nl'),
      localizationsDelegates: AppL10n.localizationsDelegates,
      supportedLocales: AppL10n.supportedLocales,
      home: Scaffold(
        appBar: AppBar(
          actions: const [GlobalAppBarActions()],
        ),
      ),
    ),
  );
}

void main() {
  late MockApiService mockApi;

  setUp(() {
    mockApi = MockApiService();
  });

  group('GlobalAppBarActions — menu icoon', () {
    testWidgets('toont meer-verticaal icoon', (tester) async {
      final auth = AuthService(mockApi);
      await tester.pumpWidget(_wrap(auth));
      await tester.pump();

      expect(find.byIcon(Icons.more_vert), findsOneWidget);
    });

    testWidgets('opent popup-menu bij tikken', (tester) async {
      final auth = AuthService(mockApi);
      await tester.pumpWidget(_wrap(auth));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
    });
  });

  group('GlobalAppBarActions — navigatie', () {
    testWidgets('tikken op admin login navigeert naar login scherm', (tester) async {
      final auth = AuthService(mockApi);
      await tester.pumpWidget(_wrap(auth));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.admin_panel_settings_outlined));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.email_outlined), findsOneWidget);
    });
  });

  group('GlobalAppBarActions — niet ingelogd', () {
    testWidgets('toont instellingen optie', (tester) async {
      final auth = AuthService(mockApi);
      await tester.pumpWidget(_wrap(auth));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
    });

    testWidgets('toont admin login optie als niet ingelogd', (tester) async {
      final auth = AuthService(mockApi);
      await tester.pumpWidget(_wrap(auth));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.admin_panel_settings_outlined), findsOneWidget);
      expect(find.byIcon(Icons.logout), findsNothing);
    });
  });

  group('GlobalAppBarActions — ingelogd', () {
    testWidgets('toont admin uitloggen optie als ingelogd', (tester) async {
      when(() => mockApi.login(any(), any())).thenAnswer(
        (_) async => {'success': true, 'mfaRequired': false, 'isAdmin': true},
      );
      final auth = AuthService(mockApi);
      await auth.login('admin@test.com', 'pass');

      await tester.pumpWidget(_wrap(auth));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.logout), findsOneWidget);
      expect(find.byIcon(Icons.admin_panel_settings_outlined), findsNothing);
    });

    testWidgets('tikken op uitloggen roept logout aan', (tester) async {
      when(() => mockApi.login(any(), any())).thenAnswer(
        (_) async => {'success': true, 'mfaRequired': false, 'isAdmin': true},
      );
      when(() => mockApi.logout()).thenAnswer((_) async {});

      final auth = AuthService(mockApi);
      await auth.login('admin@test.com', 'pass');

      await tester.pumpWidget(_wrap(auth));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.logout));
      await tester.pumpAndSettle();

      verify(() => mockApi.logout()).called(1);
    });
  });
}
