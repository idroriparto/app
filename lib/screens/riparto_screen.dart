import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';
import 'package:hugeicons/hugeicons.dart';

import '../data/store.dart';
import '../models/models.dart';
import '../services/pdf_service.dart';
import '../services/riparto_engine.dart';
import '../utils/format.dart';
import '../widgets/widgets.dart';
import 'bollette_screens.dart';

class RipartoScreen extends StatelessWidget {
  const RipartoScreen({super.key, required this.bollettaId});
  final String bollettaId;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final colors = context.theme.colors;
    Bolletta? b;
    for (final e in store.bollette) {
      if (e.id == bollettaId) b = e;
    }
    if (b == null) {
      return const Scaffold(body: Center(child: Text('Bolletta non trovata')));
    }
    final bolletta = b;
    final rip = store.ripartoDi(bolletta.id) ??
        RipartoEngine.calcola(bolletta: bolletta, unita: store.unita);
    final condo = store.condominio!;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        title: const Text('Prospetto di riparto'),
        actions: [
          IconButton(
            tooltip: 'Modifica bolletta',
            color: colors.foreground,
            onPressed: () => pushApp(
              context,
              BollettaFormScreen(esistente: bolletta),
            ),
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedEdit02,
              size: 22,
              color: null,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          MaxWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  periodLabel(bolletta.periodoDal, bolletta.periodoAl),
                  style: context.theme.typography.display.xl2
                      .copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    StatoChip(bolletta.stato),
                    StatusPill(label: bolletta.metodo.titolo),
                    if (bolletta.numero.isNotEmpty)
                      StatusPill(label: bolletta.numero),
                  ],
                ),
                const SizedBox(height: 18),
                MetricGrid(
                  children: [
                    MetricTile(
                      label: 'Totale ripartito',
                      value: euro(rip.totaleGenerale),
                      icon: HugeIcons.strokeRoundedMoney01,
                    ),
                    MetricTile(
                      label: 'Consumi utenze',
                      value: mcShort.format(rip.sommaConsumi),
                      hint: 'm³ individuali',
                      icon: HugeIcons.strokeRoundedDroplet,
                    ),
                    MetricTile(
                      label: 'Parti comuni',
                      value: mcShort.format(rip.consumoComune),
                      hint: 'm³ perdite / giardino',
                      icon: HugeIcons.strokeRoundedPlant02,
                    ),
                    MetricTile(
                      label: 'Prezzo medio',
                      value: euro(rip.prezzoMedioMc),
                      hint: 'per m³ di riferimento',
                      icon: HugeIcons.strokeRoundedTag01,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                WarningBanner(messages: rip.avvisi),
                const SizedBox(height: 16),
                Text(
                  rip.noteCalcolo,
                  style: context.theme.typography.body.xs
                      .copyWith(color: colors.mutedForeground, height: 1.4),
                ),
                const SizedBox(height: 18),
                AppCard(child: UnitShareChart(righe: rip.righe)),
                const SizedBox(height: 22),
                const SectionLabel('Dettaglio per unità'),
                for (final r in rip.righe)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _RigaCard(riga: r),
                  ),
                const SizedBox(height: 8),
                AppCard(
                  child: Column(
                    children: [
                      _tot(context, 'Quote fisse', rip.totaleFisso),
                      _tot(context, 'Consumi individuali', rip.totaleConsumo),
                      _tot(context, 'Parti comuni e perdite', rip.totaleComune),
                      _tot(context, 'IVA e altro', rip.totaleExtra),
                      Divider(color: colors.border),
                      _tot(context, 'Totale', rip.totaleGenerale, bold: true),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    FButton(
                      prefix: const HugeIcon(
                        icon: HugeIcons.strokeRoundedPdf01,
                        size: 18,
                        color: null,
                      ),
                      onPress: () => PdfService.shareRiparto(
                        condominio: condo,
                        bolletta: bolletta,
                        riparto: rip,
                      ),
                      child: const Text('Esporta PDF'),
                    ),
                    FButton(
                      variant: FButtonVariant.outline,
                      prefix: const HugeIcon(
                        icon: HugeIcons.strokeRoundedPrinter,
                        size: 18,
                        color: null,
                      ),
                      onPress: () => PdfService.printRiparto(
                        condominio: condo,
                        bolletta: bolletta,
                        riparto: rip,
                      ),
                      child: const Text('Stampa'),
                    ),
                    FButton(
                      variant: FButtonVariant.outline,
                      prefix: const HugeIcon(
                        icon: HugeIcons.strokeRoundedCsv01,
                        size: 18,
                        color: null,
                      ),
                      onPress: () async {
                        await Clipboard.setData(
                          ClipboardData(text: CsvService.ripartoCsv(rip)),
                        );
                        if (context.mounted) {
                          showToast(context, 'CSV copiato negli appunti');
                        }
                      },
                      child: const Text('Copia CSV'),
                    ),
                    FButton(
                      variant: FButtonVariant.outline,
                      prefix: const HugeIcon(
                        icon: HugeIcons.strokeRoundedGitCompare,
                        size: 18,
                        color: null,
                      ),
                      onPress: () => showFSheet<void>(
                        context: context,
                        side: FLayout.btt,
                        builder: (_) =>
                            _ConfrontoSheet(bolletta: bolletta),
                      ),
                      child: const Text('Confronta metodi'),
                    ),
                    if (bolletta.stato != StatoBolletta.chiusa)
                      FButton(
                        variant: FButtonVariant.outline,
                        prefix: const HugeIcon(
                          icon: HugeIcons.strokeRoundedLock,
                          size: 18,
                          color: null,
                        ),
                        onPress: () async {
                          await StoreScope.read(context)
                              .chiudiBolletta(bolletta.id);
                          if (context.mounted) {
                            showToast(context, 'Periodo chiuso');
                          }
                        },
                        child: const Text('Chiudi periodo'),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'In presenza di sottocontatori si privilegia il consumo effettivo. '
                  'In mancanza, art. 1123 c.c. (millesimi), salvo regolamento o delibera. '
                  'IdroRiparto è uno strumento di calcolo, non sostituisce la consulenza dell’amministratore.',
                  style: context.theme.typography.body.xs
                      .copyWith(color: colors.mutedForeground, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tot(BuildContext context, String l, double v, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              l,
              style: TextStyle(
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          Text(
            euro(v),
            style: TextStyle(
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _RigaCard extends StatelessWidget {
  const _RigaCard({required this.riga});
  final RigaRiparto riga;

  @override
  Widget build(BuildContext context) {
    final u = StoreScope.of(context).unitaById(riga.unitaId);
    final colors = context.theme.colors;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (u != null) InternoAvatar(unita: u, size: 40),
              if (u != null) const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Interno ${riga.interno}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      riga.proprietario,
                      style: context.theme.typography.body.xs
                          .copyWith(color: colors.mutedForeground),
                    ),
                  ],
                ),
              ),
              MoneyText(riga.totale),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              _mini(context, 'Mill.', mill(riga.millesimi)),
              _mini(context, 'Consumo', mc(riga.consumoMc)),
              _mini(context, 'Fissa', euro(riga.quotaFissa)),
              _mini(context, 'Consumo €', euro(riga.quotaConsumo)),
              _mini(context, 'Comuni', euro(riga.quotaComune)),
              _mini(context, 'IVA/altro', euro(riga.quotaExtra)),
              _mini(context, 'Quota', pct(riga.percentuale)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _mini(BuildContext context, String k, String v) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          k,
          style: TextStyle(
            fontSize: 11,
            color: context.theme.colors.mutedForeground,
          ),
        ),
        Text(v, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      ],
    );
  }
}

class _ConfrontoSheet extends StatelessWidget {
  const _ConfrontoSheet({required this.bolletta});
  final Bolletta bolletta;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final colors = context.theme.colors;
    final map = RipartoEngine.confronta(
      bolletta: bolletta,
      unita: store.unita,
    );
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      builder: (context, ctrl) {
        return ColoredBox(
          color: colors.background,
          child: ListView(
            controller: ctrl,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.border,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Stesso importo, cinque criteri',
                style: context.theme.typography.display.sm
                    .copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                'Utile in assemblea per mostrare l’effetto del passaggio ai contatori, ai millesimi o alle teste.',
                style: context.theme.typography.body.xs
                    .copyWith(color: colors.mutedForeground),
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingTextStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                  dataTextStyle: const TextStyle(fontSize: 12),
                  columns: [
                    const DataColumn(label: Text('Int.')),
                    for (final m in MetodoRiparto.values)
                      DataColumn(
                        label: Text(m.label),
                        numeric: true,
                      ),
                  ],
                  rows: [
                    for (final u in store.unita)
                      DataRow(
                        cells: [
                          DataCell(Text(u.interno)),
                          for (final m in MetodoRiparto.values)
                            DataCell(
                              Text(
                                euro(
                                  map[m]!.righe
                                      .firstWhere((r) => r.unitaId == u.id)
                                      .totale,
                                ),
                              ),
                            ),
                        ],
                      ),
                    DataRow(
                      cells: [
                        const DataCell(
                          Text(
                            'TOT',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        for (final m in MetodoRiparto.values)
                          DataCell(
                            Text(
                              euro(map[m]!.totaleGenerale),
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
