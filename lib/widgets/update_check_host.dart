import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hugeicons/hugeicons.dart';

import '../data/store.dart';
import '../services/update_service.dart';
import 'widgets.dart';

/// Esegue il controllo settimanale dopo il bootstrap senza rendere l'avvio
/// dipendente dalla rete. I fallimenti automatici restano silenziosi; sono
/// comunque visibili nella sezione Aggiornamenti delle impostazioni.
class UpdateCheckHost extends StatefulWidget {
  const UpdateCheckHost({super.key, required this.child});

  final Widget child;

  @override
  State<UpdateCheckHost> createState() => _UpdateCheckHostState();
}

class _UpdateCheckHostState extends State<UpdateCheckHost> {
  bool _scheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final store = StoreScope.of(context);
    _scheduleWhenEligible(store);
  }

  void _scheduleWhenEligible(AppStore store) {
    if (_scheduled ||
        !store.ready ||
        !store.hasCompletedOnboarding ||
        !store.automaticUpdateChecksEnabled) {
      return;
    }
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  Future<void> _check() async {
    if (!mounted) return;
    final store = StoreScope.read(context);
    final result = await store.checkForUpdates();
    if (!mounted) return;
    if (result.status == UpdateCheckStatus.skippedDisabled) {
      // Se l'utente riattiva l'opzione nella stessa sessione,
      // didChangeDependencies pianificherà una verifica se necessaria.
      _scheduled = false;
      _scheduleWhenEligible(store);
      return;
    }
    if (!store.automaticUpdateChecksEnabled || !result.hasUpdate) return;

    final release = result.release;
    if (release == null || !store.shouldNotifyFor(release)) return;

    // Registriamo la notifica prima di mostrare il dialogo: una ricostruzione
    // dell'app o un ritorno dal browser non genera pop-up duplicati.
    await store.markUpdateNotified(release);
    if (!mounted) return;
    await showUpdateAvailableDialog(context, release: release);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Dialogo informativo: non installa mai in background. L'utente sceglie
/// esplicitamente se aprire la release ufficiale GitHub o rimandare.
Future<void> showUpdateAvailableDialog(
  BuildContext context, {
  required GitHubRelease release,
}) {
  final store = StoreScope.read(context);
  final platform = currentUpdatePlatform;
  final notes = release.notes.trim();

  return showFDialog<void>(
    context: context,
    builder: (dialogContext, style, animation) => FDialog(
      style: style,
      animation: animation,
      builder: (dialogContext, style) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: dialogContext.theme.colors.primary.withValues(
                      alpha: 0.12,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(9),
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedSystemUpdate01,
                      size: 22,
                      color: dialogContext.theme.colors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Aggiornamento disponibile',
                    style: style.titleTextStyle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Text(
              'È disponibile ${release.tagName}. Aprendo la release ufficiale potrai scegliere come aggiornare IdroRiparto.',
              style: style.bodyTextStyle,
            ),
            const SizedBox(height: 10),
            Text(
              release.installationHintFor(platform),
              style: style.bodyTextStyle.copyWith(
                color: dialogContext.theme.colors.mutedForeground,
              ),
            ),
            if (notes.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Novità',
                style: dialogContext.theme.typography.body.sm.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                notes,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: style.bodyTextStyle.copyWith(
                  color: dialogContext.theme.colors.mutedForeground,
                ),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: FButton(
                    variant: FButtonVariant.outline,
                    onPress: () => Navigator.of(dialogContext).pop(),
                    child: const Text('Più tardi'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FButton(
                    onPress: () async {
                      final opened = await store.openUpdate(release);
                      if (!dialogContext.mounted) return;
                      if (opened) {
                        Navigator.of(dialogContext).pop();
                      } else {
                        showToast(
                          dialogContext,
                          'Non è stato possibile aprire la release.',
                        );
                      }
                    },
                    prefix: HugeIcon(
                      icon:
                          platform == UpdatePlatform.android &&
                              release.apkAsset() != null
                          ? HugeIcons.strokeRoundedDownload01
                          : HugeIcons.strokeRoundedArrowUpRight01,
                      size: 17,
                    ),
                    child: Text(release.actionLabelFor(platform)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
