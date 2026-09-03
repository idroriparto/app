import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:idroriparto/data/store.dart';
import 'package:idroriparto/services/update_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('AppStore preferenze indipendenti', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test(
      'una nuova installazione vede il tour e lo completa separatamente',
      () async {
        final store = AppStore(updateService: _StubUpdateService());
        await store.load();

        expect(store.hasCompletedOnboarding, isFalse);
        expect(store.automaticUpdateChecksEnabled, isTrue);

        await store.completeOnboarding();
        final restored = AppStore(updateService: _StubUpdateService());
        await restored.load();

        expect(restored.hasCompletedOnboarding, isTrue);
        expect(restored.automaticUpdateChecksEnabled, isTrue);

        await restored.setAutomaticUpdateChecksEnabled(false);
        final disabledAfterRestart = AppStore(
          updateService: _StubUpdateService(),
        );
        await disabledAfterRestart.load();
        expect(disabledAfterRestart.automaticUpdateChecksEnabled, isFalse);
      },
    );

    test(
      'una snapshot precedente migra come installazione già avviata',
      () async {
        SharedPreferences.setMockInitialValues({
          'idroriparto.snapshot.v1': jsonEncode(const AppSnapshot().toJson()),
        });
        final store = AppStore(updateService: _StubUpdateService());

        await store.load();

        expect(store.hasCompletedOnboarding, isTrue);
      },
    );

    test(
      'rispetta sette giorni, registra i tentativi e consente il controllo manuale',
      () async {
        var now = DateTime.utc(2026, 9, 3, 9);
        final updater = _StubUpdateService(
          responses: const [
            UpdateCheckResult.noRelease(),
            UpdateCheckResult.noRelease(),
            UpdateCheckResult.noRelease(),
          ],
        );
        final store = AppStore(updateService: updater, clock: () => now);
        await store.load();

        expect(store.updateCheckDue, isTrue);
        expect(
          (await store.checkForUpdates()).status,
          UpdateCheckStatus.noRelease,
        );
        expect(updater.calls, 1);
        expect(store.updateCheckDue, isFalse);
        expect(store.lastUpdateCheckAt, now);

        now = now.add(const Duration(days: 6, hours: 23));
        expect(
          (await store.checkForUpdates()).status,
          UpdateCheckStatus.skippedNotDue,
        );
        expect(updater.calls, 1);

        now = now.add(const Duration(hours: 1));
        expect(
          (await store.checkForUpdates()).status,
          UpdateCheckStatus.noRelease,
        );
        expect(updater.calls, 2);

        await store.setAutomaticUpdateChecksEnabled(false);
        expect(
          (await store.checkForUpdates()).status,
          UpdateCheckStatus.skippedDisabled,
        );
        expect(updater.calls, 2);
        expect(
          (await store.checkForUpdates(force: true)).status,
          UpdateCheckStatus.noRelease,
        );
        expect(updater.calls, 3);
      },
    );

    test(
      'persiste anche un errore per non ritentare a ogni apertura',
      () async {
        var now = DateTime.utc(2026, 9, 3, 9);
        final store = AppStore(
          updateService: _StubUpdateService(
            responses: const [UpdateCheckResult.failed('Rete non disponibile')],
          ),
          clock: () => now,
        );
        await store.load();

        final result = await store.checkForUpdates();
        expect(result.status, UpdateCheckStatus.failed);
        expect(store.lastUpdateCheckError, 'Rete non disponibile');
        expect(store.updateCheckDue, isFalse);

        now = now.add(const Duration(days: 1));
        final restored = AppStore(
          updateService: _StubUpdateService(),
          clock: () => now,
        );
        await restored.load();

        expect(restored.lastUpdateCheckError, 'Rete non disponibile');
        expect(restored.lastUpdateCheckAt, isNotNull);
        expect(restored.updateCheckDue, isFalse);
      },
    );
  });
}

class _StubUpdateService extends UpdateService {
  _StubUpdateService({List<UpdateCheckResult>? responses})
    : _responses = responses ?? const [UpdateCheckResult.noRelease()],
      super(currentVersionReader: () async => '1.0.4');

  final List<UpdateCheckResult> _responses;
  int calls = 0;

  @override
  Future<UpdateCheckResult> check() async {
    final index = calls < _responses.length ? calls : _responses.length - 1;
    calls++;
    return _responses[index];
  }
}
