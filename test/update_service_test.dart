import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:idroriparto/services/update_service.dart';

void main() {
  group('AppVersion', () {
    test('normalizza la v iniziale e confronta SemVer', () {
      final current = AppVersion.tryParse('1.0.4');
      final newer = AppVersion.tryParse('v1.0.5');
      final prerelease = AppVersion.tryParse('1.1.0-beta.2');
      final stable = AppVersion.tryParse('1.1.0');

      expect(current, isNotNull);
      expect(newer, isNotNull);
      expect(newer!.compareTo(current!), greaterThan(0));
      expect(AppVersion.tryParse('v1.0.4+4')!.compareTo(current), 0);
      expect(stable!.compareTo(prerelease!), greaterThan(0));
      expect(AppVersion.tryParse('1.0'), isNull);
      expect(AppVersion.tryParse('1.0.0-01'), isNull);
      expect(AppVersion.tryParse('release-1.0.4'), isNull);
    });
  });

  group('UpdateService', () {
    test(
      'riconosce una release GitHub più recente e il suo APK Android',
      () async {
        http.Request? request;
        final service = UpdateService(
          client: MockClient((incoming) async {
            request = incoming;
            return http.Response(
              jsonEncode(_releaseJson(tag: 'v1.0.5')),
              200,
              headers: const {'content-type': 'application/json'},
            );
          }),
          currentVersionReader: () async => '1.0.4',
          platform: UpdatePlatform.android,
        );

        final result = await service.check();

        expect(result.status, UpdateCheckStatus.updateAvailable);
        expect(result.release?.tagName, 'v1.0.5');
        expect(
          result.release?.actionUriFor(UpdatePlatform.android).toString(),
          'https://github.com/idroriparto/idroriparto/releases/download/v1.0.5/app-release.apk',
        );
        expect(request?.url.toString(), contains('/releases/latest'));
        expect(request?.headers['accept'], 'application/vnd.github+json');
      },
    );

    test(
      'non propone un aggiornamento con stessa versione o release precedente',
      () async {
        final service = UpdateService(
          client: MockClient(
            (_) async =>
                http.Response(jsonEncode(_releaseJson(tag: 'v1.0.4')), 200),
          ),
          currentVersionReader: () async => '1.0.4',
        );

        final result = await service.check();

        expect(result.status, UpdateCheckStatus.upToDate);
        expect(result.hasUpdate, isFalse);
      },
    );

    test(
      'rifiuta tag non SemVer invece di confrontare stringhe grezze',
      () async {
        final service = UpdateService(
          client: MockClient(
            (_) async =>
                http.Response(jsonEncode(_releaseJson(tag: 'latest')), 200),
          ),
          currentVersionReader: () async => '1.0.4',
        );

        final result = await service.check();

        expect(result.status, UpdateCheckStatus.failed);
      },
    );

    test('usa la pagina ufficiale della release fuori da Android', () {
      final release = GitHubRelease.fromJson(_releaseJson(tag: 'v1.0.5'));

      expect(
        release.actionUriFor(UpdatePlatform.linux).toString(),
        'https://github.com/idroriparto/idroriparto/releases/tag/v1.0.5',
      );
      expect(release.actionLabelFor(UpdatePlatform.linux), 'Apri la release');
    });

    test('un errore HTTP diventa un errore utente sicuro', () async {
      final service = UpdateService(
        client: MockClient((_) async => http.Response('rate limited', 403)),
        currentVersionReader: () async => '1.0.4',
      );

      final result = await service.check();

      expect(result.status, UpdateCheckStatus.failed);
      expect(result.message, isNotEmpty);
    });
  });
}

Map<String, dynamic> _releaseJson({required String tag}) => {
  'tag_name': tag,
  'name': 'IdroRiparto $tag',
  'body': 'Miglioramenti e correzioni.',
  'published_at': '2026-09-03T10:00:00Z',
  'html_url': 'https://github.com/idroriparto/idroriparto/releases/tag/$tag',
  'assets': [
    {
      'name': 'app-release.apk',
      'browser_download_url':
          'https://github.com/idroriparto/idroriparto/releases/download/$tag/app-release.apk',
    },
  ],
};
