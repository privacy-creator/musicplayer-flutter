import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:music_player_flutter/l10n/app_localizations.dart';
import 'package:music_player_flutter/models/song.dart';
import 'package:music_player_flutter/services/language_service.dart';
import 'package:music_player_flutter/services/translation_service.dart';
import 'package:music_player_flutter/widgets/lyrics_section.dart';
import 'package:dio/dio.dart';

class _FakeDio extends Fake implements Dio {
  final Map<String, dynamic> responseData;

  _FakeDio(this.responseData);

  @override
  Future<Response<T>> get<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    return Response<T>(
      data: responseData as T,
      statusCode: 200,
      requestOptions: RequestOptions(path: path),
    );
  }
}

Song _songWith(String? lyrics) => Song(
      id: 1,
      title: 'Test',
      artist: 'Artist',
      genre: 'Pop',
      language: 'English',
      year: 2024,
      duration: 120,
      audioUrl: 'https://example.com/1.mp3',
      lyrics: lyrics,
    );

void main() {
  late LanguageService languageService;
  late TranslationService translationService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    languageService = LanguageService(prefs);
    translationService = TranslationService(prefs);
  });

  Widget buildWidget(Song song) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<LanguageService>.value(value: languageService),
        Provider<TranslationService>.value(value: translationService),
      ],
      child: MaterialApp(
        locale: const Locale('nl'),
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: LyricsSection(song: song),
          ),
        ),
      ),
    );
  }

  group('LyricsSection — geen tekst', () {
    testWidgets('toont niets als lyrics null is', (tester) async {
      await tester.pumpWidget(buildWidget(_songWith(null)));
      await tester.pump();

      expect(find.byType(Divider), findsNothing);
    });

    testWidgets('toont niets als lyrics leeg is', (tester) async {
      await tester.pumpWidget(buildWidget(_songWith('')));
      await tester.pump();

      expect(find.byType(Divider), findsNothing);
    });
  });

  group('LyricsSection — met tekst', () {
    testWidgets('toont songtekst', (tester) async {
      await tester.pumpWidget(buildWidget(_songWith('Vers één\nRefrein')));
      await tester.pump();

      expect(find.text('Vers één\nRefrein'), findsOneWidget);
    });

    testWidgets('toont vertaal-knop', (tester) async {
      await tester.pumpWidget(buildWidget(_songWith('Hello world')));
      await tester.pump();

      expect(find.byIcon(Icons.translate), findsOneWidget);
    });

    testWidgets('toont Lyrics header', (tester) async {
      await tester.pumpWidget(buildWidget(_songWith('Some lyrics')));
      await tester.pump();

      expect(find.byType(Divider), findsOneWidget);
    });
  });

  group('LyricsSection — vertaling', () {
    testWidgets('na vertaling toont disclaimer en vertaalde tekst', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final fakeDio = _FakeDio({
        'responseStatus': 200,
        'responseData': {'translatedText': 'Hallo wereld'},
      });
      final fakeTranslationService = TranslationService(prefs, dio: fakeDio);

      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider<LanguageService>.value(
              value: languageService),
          Provider<TranslationService>.value(value: fakeTranslationService),
        ],
        child: MaterialApp(
          locale: const Locale('nl'),
          localizationsDelegates: AppL10n.localizationsDelegates,
          supportedLocales: AppL10n.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: LyricsSection(song: _songWith('Hello world')),
            ),
          ),
        ),
      ));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.translate));
      await tester.pumpAndSettle();

      expect(find.text('Hallo wereld'), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    testWidgets('tonen origineel-knop na vertaling', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final fakeDio = _FakeDio({
        'responseStatus': 200,
        'responseData': {'translatedText': 'Translated'},
      });
      final fakeTranslationService = TranslationService(prefs, dio: fakeDio);

      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider<LanguageService>.value(value: languageService),
          Provider<TranslationService>.value(value: fakeTranslationService),
        ],
        child: MaterialApp(
          locale: const Locale('nl'),
          localizationsDelegates: AppL10n.localizationsDelegates,
          supportedLocales: AppL10n.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: LyricsSection(song: _songWith('Original')),
            ),
          ),
        ),
      ));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.translate));
      await tester.pumpAndSettle();

      expect(find.byType(TextButton), findsOneWidget);

      await tester.tap(find.byType(TextButton));
      await tester.pump();

      expect(find.text('Original'), findsOneWidget);
    });

    testWidgets('vertalingsfout toont foutmelding', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final fakeDio = _FakeDio({
        'responseStatus': 403,
        'responseData': {'translatedText': ''},
      });
      final fakeTranslationService = TranslationService(prefs, dio: fakeDio);

      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider<LanguageService>.value(value: languageService),
          Provider<TranslationService>.value(value: fakeTranslationService),
        ],
        child: MaterialApp(
          locale: const Locale('nl'),
          localizationsDelegates: AppL10n.localizationsDelegates,
          supportedLocales: AppL10n.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: LyricsSection(song: _songWith('Hello')),
            ),
          ),
        ),
      ));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.translate));
      await tester.pumpAndSettle();

      // On error, translate button is shown again (not show-original)
      expect(find.byIcon(Icons.translate), findsOneWidget);
      // No disclaimer icon (translation failed, nothing displayed)
      expect(find.byIcon(Icons.info_outline), findsNothing);
    });
  });
}
