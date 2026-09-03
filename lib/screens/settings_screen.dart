import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../data/store.dart';
import '../models/models.dart';
import '../services/update_service.dart';
import '../utils/format.dart';
import '../widgets/update_check_host.dart';
import '../widgets/widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _checkingUpdate = false;
  String? _installedVersion;

  @override
  void initState() {
    super.initState();
    _loadInstalledVersion();
  }

  Future<void> _loadInstalledVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (!mounted) return;
      final build = info.buildNumber.isEmpty
          ? ''
          : ' (build ${info.buildNumber})';
      setState(() => _installedVersion = '${info.version}$build');
    } catch (_) {
      // La schermata resta utilizzabile anche su una piattaforma che non
      // espone i metadati dell'app, per esempio durante un test widget.
      if (mounted) setState(() => _installedVersion = 'non disponibile');
    }
  }

  Future<void> _checkForUpdates() async {
    if (_checkingUpdate) return;
    AppMotion.tap();
    setState(() => _checkingUpdate = true);
    final result = await StoreScope.read(context).checkForUpdates(force: true);
    if (!mounted) return;
    setState(() => _checkingUpdate = false);

    switch (result.status) {
      case UpdateCheckStatus.updateAvailable:
        final release = result.release;
        if (release != null) {
          // Evita che l'host automatico mostri lo stesso avviso in parallelo
          // al dialogo richiesto manualmente dall'utente.
          await StoreScope.read(context).markUpdateNotified(release);
          if (mounted) {
            await showUpdateAvailableDialog(context, release: release);
          }
        }
        return;
      case UpdateCheckStatus.upToDate:
        showToast(context, 'Hai già la versione più recente.');
        return;
      case UpdateCheckStatus.noRelease:
        showToast(context, 'Non è stata ancora pubblicata una release.');
        return;
      case UpdateCheckStatus.failed:
        showToast(
          context,
          result.message ?? 'Impossibile verificare gli aggiornamenti.',
        );
        return;
      case UpdateCheckStatus.skippedDisabled:
      case UpdateCheckStatus.skippedNotDue:
        // Un controllo manuale usa force: true; questi esiti restano qui per
        // completezza se in futuro il flusso viene riusato.
        showToast(context, 'Controllo aggiornamenti rimandato.');
        return;
    }
  }

  String _updateStatus(AppStore store) {
    if (!store.automaticUpdateChecksEnabled) {
      return 'Controlli automatici disattivati';
    }
    final last = store.lastUpdateCheckAt;
    final error = store.lastUpdateCheckError;
    if (error != null) {
      final when = last == null ? '' : ' (${dateShort.format(last)})';
      return 'Ultimo tentativo$when: $error';
    }
    final available = store.availableUpdate;
    if (available != null) return '${available.tagName} disponibile';
    if (last == null) return 'Mai verificato';
    return 'Ultima verifica: ${dateShort.format(last)}';
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final c = store.condominio!;
    final colors = context.theme.colors;
    final typo = context.theme.typography;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: [
          MaxWidth(
            width: 720,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Impostazioni',
                  style: typo.display.md.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 18),
                const SectionLabel('Condominio'),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.nome,
                        style: typo.body.lg.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (c.indirizzoCompleto.isNotEmpty)
                        Text(c.indirizzoCompleto),
                      if (c.amministratore.isNotEmpty)
                        Text('Amm.: ${c.amministratore}'),
                      if (c.fornitore.isNotEmpty)
                        Text('Gestore: ${c.fornitore}'),
                      const SizedBox(height: 12),
                      FButton(
                        variant: FButtonVariant.outline,
                        onPress: () =>
                            pushApp(context, const CondoFormScreen()),
                        child: const Text('Modifica anagrafica e criteri'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const SectionLabel('Aspetto'),
                AppCard(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      _ThemeTile(
                        choice: ThemeChoice.system,
                        label: 'Sistema',
                        groupValue: store.themeChoice,
                        onChanged: store.setTheme,
                      ),
                      _ThemeTile(
                        choice: ThemeChoice.light,
                        label: 'Chiaro',
                        groupValue: store.themeChoice,
                        onChanged: store.setTheme,
                      ),
                      _ThemeTile(
                        choice: ThemeChoice.dark,
                        label: 'Scuro',
                        groupValue: store.themeChoice,
                        onChanged: store.setTheme,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const SectionLabel('Aggiornamenti'),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FSwitch(
                        leadingLabel: true,
                        value: store.automaticUpdateChecksEnabled,
                        onChange: (enabled) async {
                          AppMotion.tap();
                          await StoreScope.read(
                            context,
                          ).setAutomaticUpdateChecksEnabled(enabled);
                        },
                        label: const Text('Controlli automatici'),
                        description: const Text(
                          'Verifica le release ufficiali GitHub al massimo una volta alla settimana.',
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        _updateStatus(store),
                        style: typo.body.xs.copyWith(
                          color: colors.mutedForeground,
                        ),
                      ),
                      const SizedBox(height: 14),
                      FButton(
                        variant: FButtonVariant.outline,
                        onPress: _checkingUpdate ? null : _checkForUpdates,
                        prefix: HugeIcon(
                          icon: HugeIcons.strokeRoundedRefresh,
                          size: 17,
                        ),
                        child: Text(
                          _checkingUpdate
                              ? 'Verifica in corso…'
                              : 'Verifica ora',
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Il download o la pagina della release si aprono solo dopo la tua conferma.',
                        style: typo.body.xs.copyWith(
                          color: colors.mutedForeground,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const SectionLabel('Archivio'),
                // FTileGroup: gruppo di tile ufficiale forui, con sfondo
                // card, bordo e divisori inset allineati automaticamente
                // (le tile custom + FDivider apparivano "storti").
                FTileGroup(
                  children: [
                    FTile(
                      prefix: const HugeIcon(
                        icon: HugeIcons.strokeRoundedFileExport,
                      ),
                      title: const Text('Esporta JSON'),
                      subtitle: const Text(
                        'Copia l’intero archivio negli appunti',
                      ),
                      onPress: () async {
                        await Clipboard.setData(
                          ClipboardData(
                            text: AppSnapshot(
                              condominio: store.condominio,
                              unita: store.unita,
                              letture: store.letture,
                              bollette: store.bollette,
                              riparti: store.riparti,
                              theme: store.themeChoice,
                            ).toPrettyJson(),
                          ),
                        );
                        if (context.mounted) {
                          showToast(context, 'Archivio copiato');
                        }
                      },
                    ),
                    FTile(
                      prefix: const HugeIcon(
                        icon: HugeIcons.strokeRoundedFileDownload,
                      ),
                      title: const Text('Importa JSON'),
                      onPress: () => _import(context),
                    ),
                    FTile(
                      prefix: const HugeIcon(
                        icon: HugeIcons.strokeRoundedSparkles,
                      ),
                      title: const Text('Carica condominio di esempio'),
                      subtitle: const Text(
                        'Palazzo Solferino, Milano — sostituisce i dati attuali',
                      ),
                      onPress: () async {
                        final ok = await confirmDialog(
                          context,
                          title: 'Caricare l’esempio?',
                          message:
                              'I dati attuali saranno sostituiti con l’esempio di Milano.',
                          confirmLabel: 'Carica esempio',
                        );
                        if (ok && context.mounted) {
                          await StoreScope.read(context).loadDemo();
                        }
                      },
                    ),
                    FTile(
                      variant: FItemVariant.destructive,
                      prefix: const HugeIcon(
                        icon: HugeIcons.strokeRoundedDelete02,
                      ),
                      title: const Text('Azzera tutto'),
                      onPress: () async {
                        final ok = await confirmDialog(
                          context,
                          title: 'Azzera tutto?',
                          message:
                              'Verranno cancellati condominio, unità, letture e bollette.',
                          confirmLabel: 'Azzera',
                          destructive: true,
                        );
                        if (ok && context.mounted) {
                          await StoreScope.read(context).resetAll();
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const SectionLabel('Guida'),
                FTileGroup(
                  children: [
                    FTile(
                      prefix: const HugeIcon(
                        icon: HugeIcons.strokeRoundedPresentation02,
                      ),
                      title: const Text('Rivedi la presentazione'),
                      subtitle: const Text(
                        'Una panoramica delle funzioni principali',
                      ),
                      onPress: () async {
                        await StoreScope.read(context).replayOnboarding();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const SectionLabel('Informazioni'),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'IdroRiparto',
                        style: typo.body.md.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'App per la ripartizione delle spese idriche condominiali. '
                        'Il metodo consigliato con i contatori individuali addebita il '
                        'consumo effettivo a ciascuna unità, ripartisce la differenza '
                        '(parti comuni e perdite) a millesimi e divide la quota fissa in '
                        'parti uguali. In mancanza di contatori si applica l’art. 1123 c.c., '
                        'salvo regolamento o delibera.\n\n'
                        'I dati restano sul dispositivo. Non è un parere legale: verifica '
                        'sempre il regolamento del condominio.',
                        style: typo.body.xs.copyWith(
                          color: colors.mutedForeground,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _installedVersion == null
                            ? 'Versione in lettura…'
                            : 'Versione $_installedVersion',
                        style: typo.body.xs.copyWith(
                          color: colors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _import(BuildContext context) async {
    final raw = await promptDialog(
      context,
      title: 'Incolla l’archivio JSON',
      hint: '{ … }',
      confirmLabel: 'Importa',
    );
    if (raw == null || raw.trim().isEmpty) return;
    if (!context.mounted) return;
    try {
      final snap = AppSnapshot.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
      await StoreScope.read(context).importSnapshot(snap);
      if (context.mounted) showToast(context, 'Archivio importato');
    } catch (e) {
      if (context.mounted) showToast(context, 'JSON non valido');
    }
  }
}

class _ThemeTile extends StatelessWidget {
  const _ThemeTile({
    required this.choice,
    required this.label,
    required this.groupValue,
    required this.onChanged,
  });

  final ThemeChoice choice;
  final String label;
  final ThemeChoice groupValue;
  final ValueChanged<ThemeChoice> onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = choice == groupValue;
    final colors = context.theme.colors;
    return FTappable(
      onPress: () => onChanged(choice),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Row(
          children: [
            HugeIcon(
              icon: selected
                  ? HugeIcons.strokeRoundedCheckmarkCircle01
                  : HugeIcons.strokeRoundedCircle,
              size: 20,
              color: selected ? colors.primary : colors.mutedForeground,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? colors.primary : colors.foreground,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CondoFormScreen extends StatefulWidget {
  const CondoFormScreen({super.key});

  @override
  State<CondoFormScreen> createState() => _CondoFormScreenState();
}

class _CondoFormScreenState extends State<CondoFormScreen> {
  late final TextEditingController nome;
  late final TextEditingController indirizzo;
  late final TextEditingController cap;
  late final TextEditingController citta;
  late final TextEditingController provincia;
  late final TextEditingController cf;
  late final TextEditingController ammin;
  late final TextEditingController fornitore;
  late final TextEditingController utenza;
  late final TextEditingController note;
  late MetodoRiparto metodo;
  late CriterioQuota fissa;
  late CriterioQuota comune;

  @override
  void initState() {
    super.initState();
    final c = StoreScope.read(context).condominio!;
    nome = TextEditingController(text: c.nome);
    indirizzo = TextEditingController(text: c.indirizzo);
    cap = TextEditingController(text: c.cap);
    citta = TextEditingController(text: c.citta);
    provincia = TextEditingController(text: c.provincia);
    cf = TextEditingController(text: c.codiceFiscale ?? '');
    ammin = TextEditingController(text: c.amministratore);
    fornitore = TextEditingController(text: c.fornitore);
    utenza = TextEditingController(text: c.codiceUtenza ?? '');
    note = TextEditingController(text: c.note);
    metodo = c.metodoDefault;
    fissa = c.criterioFissa;
    comune = c.criterioComune;
  }

  @override
  void dispose() {
    nome.dispose();
    indirizzo.dispose();
    cap.dispose();
    citta.dispose();
    provincia.dispose();
    cf.dispose();
    ammin.dispose();
    fornitore.dispose();
    utenza.dispose();
    note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FScaffold(
      childPad: false,
      header: FHeader.nested(
        prefixes: [backAction(context)],
        title: const Text('Anagrafica condominio'),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          MaxWidth(
            width: 640,
            child: Column(
              children: [
                ItField(label: 'Nome', controller: nome),
                const SizedBox(height: 10),
                ItField(label: 'Indirizzo', controller: indirizzo),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ItField(label: 'CAP', controller: cap),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: ItField(label: 'Città', controller: citta),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ItField(label: 'Prov.', controller: provincia),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ItField(label: 'Codice fiscale / P. IVA', controller: cf),
                const SizedBox(height: 10),
                ItField(label: 'Amministratore', controller: ammin),
                const SizedBox(height: 10),
                ItField(label: 'Gestore idrico', controller: fornitore),
                const SizedBox(height: 10),
                ItField(label: 'Codice utenza', controller: utenza),
                const SizedBox(height: 10),
                ItField(label: 'Note', controller: note, maxLines: 3),
                const SizedBox(height: 16),
                FSelect<MetodoRiparto>(
                  label: const Text('Metodo predefinito'),
                  control: FSelectControl.lifted(
                    value: metodo,
                    onChange: (v) => setState(() => metodo = v ?? metodo),
                  ),
                  items: {for (final m in MetodoRiparto.values) m.titolo: m},
                ),
                const SizedBox(height: 10),
                FSelect<CriterioQuota>(
                  label: const Text('Criterio quota fissa'),
                  control: FSelectControl.lifted(
                    value: fissa,
                    onChange: (v) => setState(() => fissa = v ?? fissa),
                  ),
                  items: {for (final m in CriterioQuota.values) m.label: m},
                ),
                const SizedBox(height: 10),
                FSelect<CriterioQuota>(
                  label: const Text('Criterio parti comuni'),
                  control: FSelectControl.lifted(
                    value: comune,
                    onChange: (v) => setState(() => comune = v ?? comune),
                  ),
                  items: {for (final m in CriterioQuota.values) m.label: m},
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: FButton(
                    onPress: () async {
                      final cur = StoreScope.read(context).condominio!;
                      await StoreScope.read(context).saveCondominio(
                        cur.copyWith(
                          nome: nome.text.trim(),
                          indirizzo: indirizzo.text.trim(),
                          cap: cap.text.trim(),
                          citta: citta.text.trim(),
                          provincia: provincia.text.trim(),
                          codiceFiscale: cf.text.trim().isEmpty
                              ? null
                              : cf.text.trim(),
                          amministratore: ammin.text.trim(),
                          fornitore: fornitore.text.trim(),
                          codiceUtenza: utenza.text.trim().isEmpty
                              ? null
                              : utenza.text.trim(),
                          note: note.text.trim(),
                          metodoDefault: metodo,
                          criterioFissa: fissa,
                          criterioComune: comune,
                        ),
                      );
                      if (context.mounted) {
                        showToast(context, 'Condominio aggiornato');
                        Navigator.pop(context);
                      }
                    },
                    child: const Text('Salva'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
