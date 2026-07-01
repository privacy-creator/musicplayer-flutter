import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:music_player_flutter/services/update_service.dart';

void main() {
  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'Music Player',
      packageName: 'com.example.music_player_flutter',
      version: '1.9.0',
      buildNumber: '9',
      buildSignature: '',
    );
  });

  group('UpdateService', () {
    test('currentVersion is empty before init', () {
      final svc = UpdateService(fetchLatestTag: () async => null);
      expect(svc.currentVersion, '');
    });

    test('init reads version from PackageInfo', () async {
      final svc = UpdateService(fetchLatestTag: () async => null);
      await svc.init();
      expect(svc.currentVersion, '1.9.0');
    });

    test('hasUpdate is false when latestVersion matches currentVersion',
        () async {
      final svc = UpdateService(fetchLatestTag: () async => 'v1.9.0');
      await svc.init();
      expect(svc.hasUpdate, isFalse);
    });

    test('hasUpdate is true when latestVersion is newer', () async {
      final svc = UpdateService(fetchLatestTag: () async => 'v2.0.0');
      await svc.init();
      expect(svc.hasUpdate, isTrue);
      expect(svc.latestVersion, '2.0.0');
    });

    test('strips leading v from tag name', () async {
      final svc = UpdateService(fetchLatestTag: () async => 'v1.10.0');
      await svc.init();
      expect(svc.latestVersion, '1.10.0');
    });

    test('tag without v prefix is handled correctly', () async {
      final svc = UpdateService(fetchLatestTag: () async => '1.9.0');
      await svc.init();
      expect(svc.latestVersion, '1.9.0');
      expect(svc.hasUpdate, isFalse);
    });

    test('hasUpdate is false when latestVersion is null (fetch failed)',
        () async {
      final svc = UpdateService(fetchLatestTag: () async => null);
      await svc.init();
      expect(svc.hasUpdate, isFalse);
    });

    test('latestVersion is null when fetch throws', () async {
      final svc = UpdateService(
          fetchLatestTag: () async => throw Exception('network error'));
      await svc.init();
      expect(svc.latestVersion, isNull);
      expect(svc.hasUpdate, isFalse);
    });

    test('isChecking is false after init completes', () async {
      final svc = UpdateService(fetchLatestTag: () async => 'v1.9.0');
      await svc.init();
      expect(svc.isChecking, isFalse);
    });

    test('checkForUpdates updates latestVersion', () async {
      final svc = UpdateService(fetchLatestTag: () async => 'v1.9.0');
      await svc.init();
      expect(svc.latestVersion, '1.9.0');
    });

    test('notifies listeners when init completes', () async {
      final svc = UpdateService(fetchLatestTag: () async => 'v2.0.0');
      var notified = false;
      svc.addListener(() => notified = true);
      await svc.init();
      expect(notified, isTrue);
    });
  });
}
