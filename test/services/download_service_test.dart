import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_player_flutter/models/song.dart';
import 'package:music_player_flutter/services/download_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockDio extends Mock implements Dio {}

Song makeSong(int id) => Song(
      id: id,
      title: 'Song $id',
      artist: 'Artist',
      genre: 'Pop',
      language: 'Dutch',
      year: 2024,
      duration: 180,
      audioUrl: 'https://api.hiddebalestra.nl/muziek/uploads/$id.mp3',
    );

void main() {
  late MockDio mockDio;
  late Directory tempDir;
  late DownloadService service;

  setUpAll(() {
    registerFallbackValue(CancelToken());
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tempDir = await Directory.systemTemp.createTemp('dl_test_');
    mockDio = MockDio();
    service = DownloadService(testBaseDir: tempDir.path);
  });

  tearDown(() async {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  group('Beginwaarden', () {
    test('isDownloaded() is false bij aanmaak', () {
      expect(service.isDownloaded(1), false);
    });

    test('getLocalPath() is null bij aanmaak', () {
      expect(service.getLocalPath(1), isNull);
    });

    test('isDownloading() is false bij aanmaak', () {
      expect(service.isDownloading(1), false);
    });

    test('getProgress() is 0.0 bij aanmaak', () {
      expect(service.getProgress(1), 0.0);
    });
  });

  group('download()', () {
    void stubSuccessfulDownload(MockDio dio) {
      when(() => dio.download(
            any(),
            any(),
            onReceiveProgress: any(named: 'onReceiveProgress'),
            cancelToken: any(named: 'cancelToken'),
            deleteOnError: any(named: 'deleteOnError'),
            lengthHeader: any(named: 'lengthHeader'),
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenAnswer((inv) async {
        final callback =
            inv.namedArguments[#onReceiveProgress] as ProgressCallback?;
        callback?.call(50, 100);
        callback?.call(100, 100);
        final path = inv.positionalArguments[1] as String;
        await File(path).writeAsBytes([1, 2, 3]);
        return Response(
            requestOptions: RequestOptions(path: ''), statusCode: 200);
      });
    }

    test('isDownloaded() is true na succesvolle download', () async {
      stubSuccessfulDownload(mockDio);
      await service.download(makeSong(1), mockDio);
      expect(service.isDownloaded(1), true);
    });

    test('getLocalPath() geeft pad terug na download', () async {
      stubSuccessfulDownload(mockDio);
      await service.download(makeSong(1), mockDio);
      expect(service.getLocalPath(1), isNotNull);
      expect(service.getLocalPath(1)!.endsWith('1.mp3'), true);
    });

    test('bestand bestaat na download', () async {
      stubSuccessfulDownload(mockDio);
      await service.download(makeSong(1), mockDio);
      final path = service.getLocalPath(1)!;
      expect(File(path).existsSync(), true);
    });

    test('isDownloading() is false na voltooide download', () async {
      stubSuccessfulDownload(mockDio);
      await service.download(makeSong(1), mockDio);
      expect(service.isDownloading(1), false);
    });

    test('dubbele download wordt genegeerd', () async {
      stubSuccessfulDownload(mockDio);
      await service.download(makeSong(1), mockDio);
      await service.download(makeSong(1), mockDio);
      verify(() => mockDio.download(
            any(), any(),
            onReceiveProgress: any(named: 'onReceiveProgress'),
            cancelToken: any(named: 'cancelToken'),
            deleteOnError: any(named: 'deleteOnError'),
            lengthHeader: any(named: 'lengthHeader'),
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).called(1);
    });

    test('isDownloaded() blijft false bij mislukte download', () async {
      when(() => mockDio.download(
            any(), any(),
            onReceiveProgress: any(named: 'onReceiveProgress'),
            cancelToken: any(named: 'cancelToken'),
            deleteOnError: any(named: 'deleteOnError'),
            lengthHeader: any(named: 'lengthHeader'),
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenThrow(DioException(
              requestOptions: RequestOptions(path: ''),
              message: 'Network error'));
      await service.download(makeSong(1), mockDio);
      expect(service.isDownloaded(1), false);
    });
  });

  group('delete()', () {
    setUp(() async {
      when(() => mockDio.download(
            any(), any(),
            onReceiveProgress: any(named: 'onReceiveProgress'),
            cancelToken: any(named: 'cancelToken'),
            deleteOnError: any(named: 'deleteOnError'),
            lengthHeader: any(named: 'lengthHeader'),
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenAnswer((inv) async {
        final path = inv.positionalArguments[1] as String;
        await File(path).writeAsBytes([1, 2, 3]);
        return Response(
            requestOptions: RequestOptions(path: ''), statusCode: 200);
      });
    });

    test('isDownloaded() is false na verwijderen', () async {
      await service.download(makeSong(1), mockDio);
      await service.delete(1);
      expect(service.isDownloaded(1), false);
    });

    test('getLocalPath() is null na verwijderen', () async {
      await service.download(makeSong(1), mockDio);
      await service.delete(1);
      expect(service.getLocalPath(1), isNull);
    });

    test('bestand is verwijderd na delete()', () async {
      await service.download(makeSong(1), mockDio);
      final path = service.getLocalPath(1)!;
      await service.delete(1);
      expect(File(path).existsSync(), false);
    });

    test('delete() op niet-gedownload nummer doet niets', () async {
      await service.delete(99);
      expect(service.isDownloaded(99), false);
    });
  });

  group('persistentie via SharedPreferences', () {
    test('init() laadt eerder opgeslagen downloads', () async {
      when(() => mockDio.download(
            any(), any(),
            onReceiveProgress: any(named: 'onReceiveProgress'),
            cancelToken: any(named: 'cancelToken'),
            deleteOnError: any(named: 'deleteOnError'),
            lengthHeader: any(named: 'lengthHeader'),
            data: any(named: 'data'),
            options: any(named: 'options'),
          )).thenAnswer((inv) async {
        final path = inv.positionalArguments[1] as String;
        await File(path).writeAsBytes([1, 2, 3]);
        return Response(
            requestOptions: RequestOptions(path: ''), statusCode: 200);
      });

      await service.download(makeSong(1), mockDio);

      // Nieuwe instantie laadt vanuit SharedPreferences
      final service2 = DownloadService(testBaseDir: tempDir.path);
      await service2.init();

      expect(service2.isDownloaded(1), true);
    });
  });
}
