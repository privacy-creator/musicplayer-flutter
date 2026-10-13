import 'package:flutter_test/flutter_test.dart';
import 'package:music_player_flutter/utils/lrc_parser.dart';
import 'package:music_player_flutter/utils/lrc_sync.dart';

Duration _s(num seconds) =>
    Duration(milliseconds: (seconds * 1000).round());

void main() {
  group('LrcSyncSession.fromText', () {
    test('platte tekst geeft regels zonder tijd', () {
      final s = LrcSyncSession.fromText('Een\nTwee\nDrie');
      expect(s.length, 3);
      expect(s.textAt(1), 'Twee');
      expect(s.timeAt(0), isNull);
      expect(s.stampedCount, 0);
      expect(s.current, 0);
    });

    test('lege regels en witruimte worden genegeerd', () {
      final s = LrcSyncSession.fromText('  Een  \n\n   \nTwee\r\n');
      expect(s.length, 2);
      expect(s.textAt(0), 'Een');
      expect(s.textAt(1), 'Twee');
    });

    test('metadata-tags worden overgeslagen', () {
      final s = LrcSyncSession.fromText(
          '[ar:Artiest]\n[ti:Titel]\n[length:03:20]\n[00:01.00] Een');
      expect(s.length, 1);
      expect(s.textAt(0), 'Een');
    });

    test('bestaande LRC behoudt tijden', () {
      final s = LrcSyncSession.fromText('[00:01.50] Een\n[00:04.00] Twee');
      expect(s.timeAt(0), _s(1.5));
      expect(s.timeAt(1), _s(4));
      expect(s.stampedCount, 2);
    });

    test('gemengde invoer: cursor start op eerste regel zonder tijd', () {
      final s =
          LrcSyncSession.fromText('[00:01.00] Een\n[00:02.00] Twee\nDrie\nVier');
      expect(s.current, 2);
    });

    test('volledig gesynchroniseerd: cursor start bovenaan', () {
      final s = LrcSyncSession.fromText('[00:01.00] Een\n[00:02.00] Twee');
      expect(s.current, 0);
      expect(s.isFinished, isFalse);
    });

    test('lege invoer geeft een lege sessie', () {
      final s = LrcSyncSession.fromText('  \n\n');
      expect(s.isEmpty, isTrue);
      expect(s.isFinished, isTrue);
      expect(s.toLrc(), '');
    });

    test('getimede regel zonder tekst blijft behouden', () {
      final s = LrcSyncSession.fromText('[00:01.00] Een\n[00:30.00]');
      expect(s.length, 2);
      expect(s.textAt(1), '');
    });
  });

  group('stamp', () {
    test('legt tijd vast en gaat naar de volgende regel', () {
      final s = LrcSyncSession.fromText('Een\nTwee');
      expect(s.stamp(_s(3.2)), isTrue);
      expect(s.timeAt(0), _s(3.2));
      expect(s.current, 1);
      expect(s.stampedCount, 1);
    });

    test('na de laatste regel is de sessie klaar', () {
      final s = LrcSyncSession.fromText('Een\nTwee');
      s.stamp(_s(1));
      s.stamp(_s(2));
      expect(s.isFinished, isTrue);
      expect(s.current, 2);
    });

    test('stamp na afloop doet niets', () {
      final s = LrcSyncSession.fromText('Een');
      s.stamp(_s(1));
      expect(s.stamp(_s(9)), isFalse);
      expect(s.timeAt(0), _s(1));
      expect(s.canUndo, isTrue);
    });

    test('negatieve positie wordt nul', () {
      final s = LrcSyncSession.fromText('Een');
      s.stamp(const Duration(milliseconds: -200));
      expect(s.timeAt(0), Duration.zero);
    });

    test('overschrijft een bestaande tijd na select', () {
      final s = LrcSyncSession.fromText('[00:05.00] Een\nTwee');
      s.select(0);
      s.stamp(_s(4));
      expect(s.timeAt(0), _s(4));
      expect(s.current, 1);
    });
  });

  group('select', () {
    test('zet de cursor op de gekozen regel', () {
      final s = LrcSyncSession.fromText('Een\nTwee\nDrie');
      s.select(2);
      expect(s.current, 2);
    });

    test('negeert indices buiten bereik', () {
      final s = LrcSyncSession.fromText('Een\nTwee');
      s.select(5);
      s.select(-1);
      expect(s.current, 0);
    });
  });

  group('undo', () {
    test('zonder wijzigingen kan er niets ongedaan worden', () {
      final s = LrcSyncSession.fromText('Een');
      expect(s.canUndo, isFalse);
      s.undo();
      expect(s.current, 0);
    });

    test('draait de laatste stamp terug inclusief cursor', () {
      final s = LrcSyncSession.fromText('Een\nTwee');
      s.stamp(_s(1));
      s.stamp(_s(2));
      s.undo();
      expect(s.timeAt(1), isNull);
      expect(s.current, 1);
      s.undo();
      expect(s.timeAt(0), isNull);
      expect(s.current, 0);
      expect(s.canUndo, isFalse);
    });

    test('herstelt de vorige tijd bij overschrijven', () {
      final s = LrcSyncSession.fromText('[00:05.00] Een');
      s.select(0);
      s.stamp(_s(7));
      s.undo();
      expect(s.timeAt(0), _s(5));
    });

    test('draait nudge en clear terug', () {
      final s = LrcSyncSession.fromText('[00:05.00] Een');
      s.nudge(0, LrcSyncSession.nudgeStep);
      s.clear(0);
      s.undo();
      expect(s.timeAt(0), _s(5.1));
      s.undo();
      expect(s.timeAt(0), _s(5));
    });
  });

  group('nudge', () {
    test('verschuift de tijd vooruit en achteruit', () {
      final s = LrcSyncSession.fromText('[00:05.00] Een');
      s.nudge(0, LrcSyncSession.nudgeStep);
      expect(s.timeAt(0), _s(5.1));
      s.nudge(0, -LrcSyncSession.nudgeStep * 3);
      expect(s.timeAt(0), _s(4.8));
    });

    test('klemt op nul', () {
      final s = LrcSyncSession.fromText('[00:00.05] Een');
      s.nudge(0, -LrcSyncSession.nudgeStep);
      expect(s.timeAt(0), Duration.zero);
    });

    test('doet niets op een regel zonder tijd', () {
      final s = LrcSyncSession.fromText('Een');
      s.nudge(0, LrcSyncSession.nudgeStep);
      expect(s.timeAt(0), isNull);
      expect(s.canUndo, isFalse);
    });
  });

  group('clear', () {
    test('wist de tijd van een regel', () {
      final s = LrcSyncSession.fromText('[00:05.00] Een');
      s.clear(0);
      expect(s.timeAt(0), isNull);
      expect(s.stampedCount, 0);
    });

    test('op een lege regel komt er geen undo-stap bij', () {
      final s = LrcSyncSession.fromText('Een');
      s.clear(0);
      expect(s.canUndo, isFalse);
    });
  });

  group('isOutOfOrder', () {
    test('regel eerder dan de vorige getimede regel is fout', () {
      final s = LrcSyncSession.fromText('[00:05.00] Een\nTwee\n[00:03.00] Drie');
      expect(s.isOutOfOrder(2), isTrue);
      expect(s.isOutOfOrder(0), isFalse);
    });

    test('regels zonder tijd zijn nooit fout', () {
      final s = LrcSyncSession.fromText('[00:05.00] Een\nTwee');
      expect(s.isOutOfOrder(1), isFalse);
    });

    test('oplopende of gelijke tijden zijn in orde', () {
      final s = LrcSyncSession.fromText(
          '[00:01.00] Een\n[00:01.00] Twee\n[00:02.00] Drie');
      expect([0, 1, 2].map(s.isOutOfOrder), everyElement(isFalse));
    });
  });

  group('toLrc', () {
    test('schrijft getimede regels in LRC-formaat', () {
      final s = LrcSyncSession.fromText('Een\nTwee');
      s.stamp(_s(1.25));
      s.stamp(_s(62.5));
      expect(s.toLrc(), '[00:01.25] Een\n[01:02.50] Twee');
    });

    test('regels zonder tijd blijven als platte tekst behouden', () {
      final s = LrcSyncSession.fromText('Een\nTwee');
      s.stamp(_s(1));
      expect(s.toLrc(), '[00:01.00] Een\nTwee');
    });

    test('lege getimede regel krijgt geen spatie erachter', () {
      final s = LrcSyncSession.fromText('[00:30.00]');
      expect(s.toLrc(), '[00:30.00]');
    });

    test('behoudt de regelvolgorde, ook als tijden niet oplopen', () {
      final s = LrcSyncSession.fromText('Een\nTwee');
      s.stamp(_s(5));
      s.stamp(_s(2));
      expect(s.toLrc(), '[00:05.00] Een\n[00:02.00] Twee');
    });

    test('resultaat is weer te parsen door parseLrc', () {
      final s = LrcSyncSession.fromText('Een\nTwee\nDrie');
      s.stamp(_s(1));
      s.stamp(_s(2.5));
      s.stamp(_s(4.75));
      final lines = parseLrc(s.toLrc());
      expect(lines.map((l) => l.text), ['Een', 'Twee', 'Drie']);
      expect(lines.map((l) => l.timestamp), [_s(1), _s(2.5), _s(4.75)]);
    });

    test('opnieuw inlezen van toLrc geeft dezelfde sessie', () {
      final s = LrcSyncSession.fromText('Een\nTwee\nDrie');
      s.stamp(_s(1));
      s.stamp(_s(2));
      final again = LrcSyncSession.fromText(s.toLrc());
      expect(again.toLrc(), s.toLrc());
      expect(again.current, 2);
    });
  });
}
