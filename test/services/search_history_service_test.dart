import 'package:flutter_test/flutter_test.dart';
import 'package:music_player_flutter/services/search_history_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SearchHistoryService service;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    service = SearchHistoryService();
  });

  group('Beginwaarden', () {
    test('history is leeg bij aanmaak', () {
      expect(service.history, isEmpty);
    });
  });

  group('add()', () {
    test('voegt een zoekterm toe', () async {
      await service.add('abba');
      expect(service.history, ['abba']);
    });

    test('nieuwste zoekterm staat vooraan', () async {
      await service.add('abba');
      await service.add('queen');
      expect(service.history, ['queen', 'abba']);
    });

    test('lege zoekterm wordt genegeerd', () async {
      await service.add('   ');
      expect(service.history, isEmpty);
    });

    test('zoekterm wordt getrimd', () async {
      await service.add('  abba  ');
      expect(service.history, ['abba']);
    });

    test('dubbele zoekterm (ongeacht hoofdletters) verplaatst naar voren i.p.v. te dupliceren', () async {
      await service.add('abba');
      await service.add('queen');
      await service.add('ABBA');
      expect(service.history, ['ABBA', 'queen']);
    });

    test('houdt maximaal 10 termen bij', () async {
      for (var i = 1; i <= 12; i++) {
        await service.add('term$i');
      }
      expect(service.history.length, 10);
      expect(service.history.first, 'term12');
    });
  });

  group('remove()', () {
    test('verwijdert een zoekterm', () async {
      await service.add('abba');
      await service.add('queen');
      await service.remove('abba');
      expect(service.history, ['queen']);
    });

    test('verwijderen van onbekende term doet niets', () async {
      await service.add('abba');
      await service.remove('queen');
      expect(service.history, ['abba']);
    });
  });

  group('clear()', () {
    test('maakt de geschiedenis leeg', () async {
      await service.add('abba');
      await service.add('queen');
      await service.clear();
      expect(service.history, isEmpty);
    });
  });

  group('persistentie via SharedPreferences', () {
    test('init() laadt eerdere zoekgeschiedenis', () async {
      await service.add('abba');
      await service.add('queen');

      final service2 = SearchHistoryService();
      await service2.init();

      expect(service2.history, ['queen', 'abba']);
    });
  });
}
