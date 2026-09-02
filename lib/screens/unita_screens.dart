import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';
import 'package:hugeicons/hugeicons.dart';

import '../data/store.dart';
import '../models/models.dart';
import '../utils/format.dart';
import '../utils/ids.dart';
import '../widgets/widgets.dart';

class UnitaListScreen extends StatelessWidget {
  const UnitaListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final list = store.unita;
    final rif = store.condominio?.millesimiRiferimento ?? 1000;
    final delta = store.sommaMillesimi - rif;
    final colors = context.theme.colors;
    final typo = context.theme.typography;

    return FScaffold(
      childPad: false,
      child: Stack(
        children: [
          SafeArea(
            child: list.isEmpty
                ? EmptyState(
                    icon: HugeIcons.strokeRoundedBuilding03,
                    title: 'Nessuna unità',
                    subtitle:
                        'Aggiungi gli appartamenti con millesimi, occupanti e, se c’è, il sottocontatore.',
                    actionLabel: 'Aggiungi la prima',
                    onAction: () => pushApp(context, const UnitaFormScreen()),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 108),
                    children: [
                      MaxWidth(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Unità immobiliari',
                              style: typo.display.sm.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${list.length} unità · millesimi ${mill(store.sommaMillesimi)} / ${mill(rif)}',
                              style: typo.body.sm.copyWith(
                                color: colors.mutedForeground,
                              ),
                            ),
                            if (delta.abs() > 0.05) ...[
                              const SizedBox(height: 12),
                              WarningBanner(
                                messages: [
                                  'La somma dei millesimi differisce di ${mill(delta)} rispetto al riferimento (${mill(rif)}).',
                                ],
                              ),
                            ],
                            const SizedBox(height: 16),
                            for (final u in list)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: AppCard(
                                  onTap: () => pushApp(
                                    context,
                                    UnitaDetailScreen(id: u.id),
                                  ),
                                  child: Row(
                                    children: [
                                      InternoAvatar(unita: u),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              u.titolo,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            Text(
                                              u.sottoTitolo,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: typo.body.xs.copyWith(
                                                color: colors.mutedForeground,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            mill(u.millesimi),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          Text(
                                            'mill.',
                                            style: typo.body.xs.copyWith(
                                              color: colors.mutedForeground,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
          Positioned(
            right: 24,
            bottom: 28,
            child: FabAction(
              icon: HugeIcons.strokeRoundedAdd01,
              label: 'Nuova unità',
              onPress: () => pushApp(context, const UnitaFormScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

class UnitaDetailScreen extends StatelessWidget {
  const UnitaDetailScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final u = store.unitaById(id);
    if (u == null) {
      return FScaffold(
        childPad: false,
        header: FHeader.nested(
          prefixes: [backAction(context)],
          title: const Text('Unità'),
        ),
        child: const Center(child: Text('Unità non trovata')),
      );
    }
    final letture = store.lettureDi(u.id).reversed.toList();
    final colors = context.theme.colors;

    return FScaffold(
      childPad: false,
      header: FHeader.nested(
        prefixes: [backAction(context)],
        title: Text(u.titolo),
        suffixes: [
          FHeaderAction(
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedEdit02,
              size: 20,
              color: colors.foreground,
            ),
            semanticsLabel: 'Modifica',
            onPress: () => pushApp(context, UnitaFormScreen(esistente: u)),
          ),
          FHeaderAction(
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedDelete02,
              size: 20,
              color: colors.error,
            ),
            semanticsLabel: 'Elimina',
            onPress: () async {
              final ok = await confirmDialog(
                context,
                title: 'Eliminare l’unità?',
                message: 'Verranno cancellate anche le letture di ${u.titolo}.',
                confirmLabel: 'Elimina',
                destructive: true,
              );
              if (ok && context.mounted) {
                await StoreScope.read(context).deleteUnita(u.id);
                if (context.mounted) Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          MaxWidth(
            width: 720,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppCard(
                  child: Row(
                    children: [
                      InternoAvatar(unita: u, size: 64),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              u.proprietario,
                              style: context.theme.typography.body.lg.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (u.occupante != null &&
                                u.occupante!.isNotEmpty &&
                                u.occupante != u.proprietario)
                              Text('Occupante: ${u.occupante}'),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                StatusPill(label: '${mill(u.millesimi)} mill.'),
                                StatusPill(
                                  label: u.sfitto
                                      ? 'Sfitto'
                                      : '${u.occupanti} occupanti',
                                  color: u.sfitto
                                      ? colors.mutedForeground
                                      : colors.primary,
                                ),
                                if (u.haContatore)
                                  StatusPill(
                                    label: u.matricola ?? 'Contatore',
                                    color: colors.primary,
                                    icon:
                                        HugeIcons.strokeRoundedDashboardSpeed02,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                const SectionLabel('Storico letture'),
                if (letture.isEmpty)
                  Text(
                    'Nessuna lettura registrata per questa unità.',
                    style: TextStyle(color: colors.mutedForeground),
                  )
                else
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (var i = 0; i < letture.length; i++) ...[
                          if (i > 0) const FDivider(),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        mc(letture[i].valore),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        dateIt.format(letture[i].data),
                                        style: context.theme.typography.body.xs
                                            .copyWith(
                                              color: colors.mutedForeground,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (i < letture.length - 1)
                                  Text(
                                    '+ ${mcNum(letture[i].valore - letture[i + 1].valore)} m³',
                                    style: TextStyle(
                                      color: colors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
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
}

class UnitaFormScreen extends StatefulWidget {
  const UnitaFormScreen({super.key, this.esistente});
  final UnitaImmobiliare? esistente;

  @override
  State<UnitaFormScreen> createState() => _UnitaFormScreenState();
}

class _UnitaFormScreenState extends State<UnitaFormScreen> {
  final _internoKey = GlobalKey<FormFieldState<String>>();
  final _proprietarioKey = GlobalKey<FormFieldState<String>>();
  final _millesimiKey = GlobalKey<FormFieldState<String>>();
  late final TextEditingController interno;
  late final TextEditingController scala;
  late final TextEditingController piano;
  late final TextEditingController proprietario;
  late final TextEditingController occupante;
  late final TextEditingController email;
  late final TextEditingController telefono;
  late final TextEditingController millesimi;
  late final TextEditingController occupanti;
  late final TextEditingController matricola;
  late final TextEditingController note;
  late bool sfitto;
  late bool haContatore;

  @override
  void initState() {
    super.initState();
    final u = widget.esistente;
    interno = TextEditingController(text: u?.interno ?? '');
    scala = TextEditingController(text: u?.scala ?? '');
    piano = TextEditingController(text: u?.piano ?? '');
    proprietario = TextEditingController(text: u?.proprietario ?? '');
    occupante = TextEditingController(text: u?.occupante ?? '');
    email = TextEditingController(text: u?.email ?? '');
    telefono = TextEditingController(text: u?.telefono ?? '');
    millesimi = TextEditingController(
      text: u == null ? '' : millFormat.format(u.millesimi),
    );
    occupanti = TextEditingController(text: '${u?.occupanti ?? 1}');
    matricola = TextEditingController(text: u?.matricola ?? '');
    note = TextEditingController(text: u?.note ?? '');
    sfitto = u?.sfitto ?? false;
    haContatore = u?.haContatore ?? true;
  }

  @override
  void dispose() {
    interno.dispose();
    scala.dispose();
    piano.dispose();
    proprietario.dispose();
    occupante.dispose();
    email.dispose();
    telefono.dispose();
    millesimi.dispose();
    occupanti.dispose();
    matricola.dispose();
    note.dispose();
    super.dispose();
  }

  /// Valida singolarmente i campi obbligatori (forui non ha un FForm:
  /// ogni FTextFormField si valida tramite la propria FormFieldState).
  bool _valid() {
    var ok = true;
    for (final key in [_internoKey, _proprietarioKey, _millesimiKey]) {
      ok = (key.currentState?.validate() ?? false) && ok;
    }
    return ok;
  }

  Future<void> _save() async {
    if (!_valid()) return;
    final store = StoreScope.read(context);
    final base = widget.esistente;
    final u = UnitaImmobiliare(
      id: base?.id ?? newId('un'),
      interno: interno.text.trim(),
      scala: scala.text.trim(),
      piano: piano.text.trim(),
      proprietario: proprietario.text.trim(),
      occupante: occupante.text.trim().isEmpty ? null : occupante.text.trim(),
      email: email.text.trim().isEmpty ? null : email.text.trim(),
      telefono: telefono.text.trim().isEmpty ? null : telefono.text.trim(),
      millesimi: parseItNumber(millesimi.text) ?? 0,
      occupanti: int.tryParse(occupanti.text.trim()) ?? 0,
      sfitto: sfitto,
      haContatore: haContatore,
      matricola: matricola.text.trim().isEmpty ? null : matricola.text.trim(),
      note: note.text.trim(),
      ordine: base?.ordine ?? store.unita.length + 1,
    );
    await store.upsertUnita(u);
    if (mounted) {
      showToast(context, 'Unità salvata');
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FScaffold(
      childPad: false,
      header: FHeader.nested(
        prefixes: [backAction(context)],
        title: Text(
          widget.esistente == null ? 'Nuova unità' : 'Modifica unità',
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          MaxWidth(
            width: 640,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ItField(
                        label: 'Interno',
                        controller: interno,
                        formFieldKey: _internoKey,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Obbligatorio'
                            : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ItField(label: 'Scala', controller: scala),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ItField(label: 'Piano', controller: piano),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ItField(
                  label: 'Proprietario',
                  controller: proprietario,
                  formFieldKey: _proprietarioKey,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Obbligatorio' : null,
                ),
                const SizedBox(height: 12),
                ItField(label: 'Occupante / inquilino', controller: occupante),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ItField(
                        label: 'Millesimi',
                        controller: millesimi,
                        formFieldKey: _millesimiKey,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (v) => parseItNumber(v ?? '') == null
                            ? 'Numero non valido'
                            : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ItField(
                        label: 'Occupanti',
                        controller: occupanti,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _switchRow(
                  label: 'Unità sfitta',
                  description:
                      'Gli occupanti non entrano nel riparto per teste.',
                  value: sfitto,
                  onChanged: (v) => setState(() => sfitto = v),
                ),
                _switchRow(
                  label: 'Ha sottocontatore',
                  description:
                      'Se presente, il consumo individuale viene rilevato.',
                  value: haContatore,
                  onChanged: (v) => setState(() => haContatore = v),
                ),
                if (haContatore) ...[
                  const SizedBox(height: 4),
                  ItField(label: 'Matricola contatore', controller: matricola),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ItField(
                        label: 'Email',
                        controller: email,
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ItField(
                        label: 'Telefono',
                        controller: telefono,
                        keyboardType: TextInputType.phone,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ItField(label: 'Note', controller: note, maxLines: 3),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FButton(
                    onPress: _save,
                    child: const Text('Salva unità'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _switchRow({
    required String label,
    required String description,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: FSwitch(
        value: value,
        onChange: onChanged,
        label: Text(label),
        description: Text(description),
      ),
    );
  }
}
