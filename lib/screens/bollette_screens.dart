import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';
import 'package:hugeicons/hugeicons.dart';

import '../data/store.dart';
import '../models/models.dart';
import '../services/riparto_engine.dart';
import '../utils/format.dart';
import '../utils/ids.dart';
import '../widgets/widgets.dart';
import 'riparto_screen.dart';

class BolletteListScreen extends StatelessWidget {
  const BolletteListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final list = store.bollette;
    final colors = context.theme.colors;
    final typo = context.theme.typography;
    return Scaffold(
      backgroundColor: colors.background,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: colors.primary,
        foregroundColor: colors.primaryForeground,
        elevation: 0,
        onPressed: () => pushApp(context, const BollettaFormScreen()),
        icon: HugeIcon(
          icon: HugeIcons.strokeRoundedAdd01,
          size: 20,
          color: colors.primaryForeground,
        ),
        label: Text(
          'Nuova bolletta',
          style: TextStyle(color: colors.primaryForeground),
        ),
      ),
      body: SafeArea(
        child: list.isEmpty
            ? EmptyState(
                icon: HugeIcons.strokeRoundedReceiptText,
                title: 'Nessuna bolletta',
                subtitle:
                    'Inserisci gli importi del gestore (quota fissa, acquedotto, fognatura, depurazione, IVA) e calcola il riparto.',
                actionLabel: 'Registra una bolletta',
                onAction: () =>
                    pushApp(context, const BollettaFormScreen()),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                children: [
                  MaxWidth(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bollette e periodi',
                          style: typo.display.sm
                              .copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Ogni periodo ha i suoi importi, i consumi e un prospetto di riparto.',
                          style: typo.body.sm
                              .copyWith(color: colors.mutedForeground),
                        ),
                        const SizedBox(height: 16),
                        for (final b in list)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: AppCard(
                              onTap: () {
                                final rip = store.ripartoDi(b.id);
                                if (rip == null) {
                                  pushApp(
                                    context,
                                    BollettaFormScreen(esistente: b),
                                  );
                                } else {
                                  pushApp(
                                    context,
                                    RipartoScreen(bollettaId: b.id),
                                  );
                                }
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          periodLabel(b.periodoDal, b.periodoAl),
                                          style: typo.body.lg
                                              .copyWith(fontWeight: FontWeight.w700),
                                        ),
                                      ),
                                      StatoChip(b.stato),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    [
                                      if (b.numero.isNotEmpty) b.numero,
                                      if (b.fornitore.isNotEmpty) b.fornitore,
                                      b.metodo.label,
                                    ].join(' · '),
                                    style: typo.body.xs
                                        .copyWith(color: colors.mutedForeground),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      MoneyText(b.totale),
                                      const Spacer(),
                                      Text(
                                        mc(b.mcFatturati),
                                        style: typo.body.xs
                                            .copyWith(color: colors.mutedForeground),
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
    );
  }
}

class BollettaFormScreen extends StatefulWidget {
  const BollettaFormScreen({super.key, this.esistente});
  final Bolletta? esistente;

  @override
  State<BollettaFormScreen> createState() => _BollettaFormScreenState();
}

class _BollettaFormScreenState extends State<BollettaFormScreen> {
  late DateTime dal;
  late DateTime al;
  late DateTime doc;
  final numero = TextEditingController();
  final fornitore = TextEditingController();
  final fissa = TextEditingController();
  final acq = TextEditingController();
  final fog = TextEditingController();
  final dep = TextEditingController();
  final iva = TextEditingController();
  final altro = TextEditingController();
  final mcFatt = TextEditingController();
  final note = TextEditingController();
  late MetodoRiparto metodo;
  late CriterioQuota criterioFissa;
  late CriterioQuota criterioComune;
  final consumi = <String, TextEditingController>{};
  bool _seeded = false;

  @override
  void initState() {
    super.initState();
    final b = widget.esistente;
    final now = DateTime.now();
    dal = b?.periodoDal ?? DateTime(now.year, now.month - 2, 1);
    al = b?.periodoAl ?? DateTime(now.year, now.month, 0);
    doc = b?.dataDocumento ?? now;
    numero.text = b?.numero ?? '';
    note.text = b?.note ?? '';
    if (b != null) {
      fissa.text = _fmt(b.quotaFissa);
      acq.text = _fmt(b.acquedotto);
      fog.text = _fmt(b.fognatura);
      dep.text = _fmt(b.depurazione);
      iva.text = _fmt(b.iva);
      altro.text = _fmt(b.altro);
      mcFatt.text = _fmt(b.mcFatturati);
      metodo = b.metodo;
      criterioFissa = b.criterioFissa;
      criterioComune = b.criterioComune;
    } else {
      metodo = MetodoRiparto.contatori;
      criterioFissa = CriterioQuota.partiUguali;
      criterioComune = CriterioQuota.millesimi;
    }
  }

  String _fmt(double v) => v == 0 ? '' : v.toString().replaceAll('.', ',');

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final store = StoreScope.of(context);
    for (final u in store.unita) {
      consumi.putIfAbsent(u.id, TextEditingController.new);
    }
    if (_seeded) return;
    _seeded = true;
    if (fornitore.text.isEmpty) {
      fornitore.text = widget.esistente?.fornitore.isNotEmpty == true
          ? widget.esistente!.fornitore
          : (store.condominio?.fornitore ?? '');
    }
    if (widget.esistente == null) {
      metodo = store.condominio?.metodoDefault ?? metodo;
      criterioFissa = store.condominio?.criterioFissa ?? criterioFissa;
      criterioComune = store.condominio?.criterioComune ?? criterioComune;
    }
    for (final u in store.unita) {
      if (consumi[u.id]!.text.isNotEmpty) continue;
      final existing = widget.esistente?.consumi[u.id];
      if (existing != null) {
        consumi[u.id]!.text = _fmt(existing);
      } else {
        final c = store.consumoNelPeriodo(u.id, dal, al);
        if (c.consumo > 0) consumi[u.id]!.text = _fmt(c.consumo);
      }
    }
  }

  @override
  void dispose() {
    numero.dispose();
    fornitore.dispose();
    fissa.dispose();
    acq.dispose();
    fog.dispose();
    dep.dispose();
    iva.dispose();
    altro.dispose();
    mcFatt.dispose();
    note.dispose();
    for (final c in consumi.values) {
      c.dispose();
    }
    super.dispose();
  }

  Bolletta _build(AppStore store) {
    final cons = <String, double>{};
    for (final u in store.unita) {
      cons[u.id] = parseItNumber(consumi[u.id]?.text ?? '') ?? 0;
    }
    final genPrec = store.ultimaLetturaDi(null, entro: dal);
    final genAtt = store.ultimaLetturaDi(null, entro: al);
    return Bolletta(
      id: widget.esistente?.id ?? newId('bol'),
      numero: numero.text.trim(),
      dataDocumento: doc,
      periodoDal: dal,
      periodoAl: al,
      fornitore: fornitore.text.trim(),
      quotaFissa: parseItNumber(fissa.text) ?? 0,
      acquedotto: parseItNumber(acq.text) ?? 0,
      fognatura: parseItNumber(fog.text) ?? 0,
      depurazione: parseItNumber(dep.text) ?? 0,
      iva: parseItNumber(iva.text) ?? 0,
      altro: parseItNumber(altro.text) ?? 0,
      mcFatturati: parseItNumber(mcFatt.text) ?? 0,
      letturaGeneralePrec: genPrec?.valore,
      letturaGeneraleAtt: genAtt?.valore,
      metodo: metodo,
      criterioFissa: criterioFissa,
      criterioComune: criterioComune,
      consumi: cons,
      stato: widget.esistente?.stato ?? StatoBolletta.bozza,
      createdAt: widget.esistente?.createdAt ?? DateTime.now(),
      note: note.text.trim(),
    );
  }

  Future<void> _save({required bool calcola}) async {
    final store = StoreScope.read(context);
    final b = _build(store);
    if (calcola) {
      await store.calcolaESalva(b);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        AppPageRoute(builder: (_) => RipartoScreen(bollettaId: b.id)),
      );
    } else {
      await store.upsertBolletta(b);
      if (!mounted) return;
      showToast(context, 'Bozza salvata');
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final colors = context.theme.colors;
    final typo = context.theme.typography;
    final preview = RipartoEngine.calcola(
      bolletta: _build(store),
      unita: store.unita,
    );
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        title: Text(widget.esistente == null
            ? 'Nuova bolletta'
            : 'Modifica bolletta'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          MaxWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionLabel('Periodo'),
                Row(
                  children: [
                    Expanded(
                      child: _DateTile(
                        label: 'Dal',
                        value: dal,
                        onPick: (d) => setState(() => dal = d),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _DateTile(
                        label: 'Al',
                        value: al,
                        onPick: (d) => setState(() => al = d),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ItField(label: 'Numero documento', controller: numero),
                const SizedBox(height: 10),
                ItField(label: 'Gestore idrico', controller: fornitore),
                const SizedBox(height: 18),
                const SectionLabel('Importi della bolletta'),
                _money('Quota fissa / canone', fissa),
                _money('Acquedotto', acq),
                _money('Fognatura', fog),
                _money('Depurazione', dep),
                _money('IVA', iva),
                _money('Altro (mora, arrotondamenti…)', altro),
                _money('Metri cubi fatturati', mcFatt, suffix: 'm³'),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: MoneyText(
                    (parseItNumber(fissa.text) ?? 0) +
                        (parseItNumber(acq.text) ?? 0) +
                        (parseItNumber(fog.text) ?? 0) +
                        (parseItNumber(dep.text) ?? 0) +
                        (parseItNumber(iva.text) ?? 0) +
                        (parseItNumber(altro.text) ?? 0),
                    big: true,
                  ),
                ),
                const SizedBox(height: 18),
                const SectionLabel('Metodo di riparto'),
                for (final m in MetodoRiparto.values)
                  _MethodOption(
                    method: m,
                    selected: metodo == m,
                    onTap: () => setState(() => metodo = m),
                  ),
                const SizedBox(height: 6),
                Text(
                  metodo.descrizione,
                  style: typo.body.xs
                      .copyWith(color: colors.mutedForeground, height: 1.4),
                ),
                if (metodo == MetodoRiparto.misto) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _CritSelect(
                          label: 'Quota fissa',
                          value: criterioFissa,
                          onChanged: (v) =>
                              setState(() => criterioFissa = v),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _CritSelect(
                          label: 'Parti comuni',
                          value: criterioComune,
                          onChanged: (v) =>
                              setState(() => criterioComune = v),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 18),
                SectionLabel(
                  'Consumi del periodo (m³)',
                  trailing: FButton(
                    variant: FButtonVariant.ghost,
                    size: FButtonSizeVariant.sm,
                    onPress: () {
                      setState(() {
                        for (final u in store.unita) {
                          final c =
                              store.consumoNelPeriodo(u.id, dal, al);
                          consumi[u.id]!.text =
                              c.consumo == 0 ? '' : _fmt(c.consumo);
                        }
                      });
                    },
                    child: const Text('Dalle letture'),
                  ),
                ),
                for (final u in store.unita)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 70,
                          child: Text(
                            'int. ${u.interno}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            u.proprietario,
                            overflow: TextOverflow.ellipsis,
                            style: typo.body.xs
                                .copyWith(color: colors.mutedForeground),
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 120,
                          child: FTextField(
                            control: FTextFieldControl.managed(
                              controller: consumi[u.id],
                              onChange: (_) => setState(() {}),
                            ),
                            textAlign: TextAlign.right,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                            hint: '0,000',
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 18),
                const SectionLabel('Anteprima riparto'),
                WarningBanner(messages: preview.avvisi),
                const SizedBox(height: 10),
                AppCard(child: UnitShareChart(righe: preview.righe)),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: FButton(
                        variant: FButtonVariant.outline,
                        onPress: () => _save(calcola: false),
                        child: const Text('Salva bozza'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: FButton(
                        onPress: () => _save(calcola: true),
                        child: const Text('Calcola e apri prospetto'),
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
  }

  Widget _money(String label, TextEditingController c,
      {String suffix = '€'}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ItField(
        label: label,
        controller: c,
        suffix: Text(suffix),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: (_) => setState(() {}),
      ),
    );
  }
}

class _MethodOption extends StatelessWidget {
  const _MethodOption({
    required this.method,
    required this.selected,
    required this.onTap,
  });
  final MetodoRiparto method;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            HugeIcon(
              icon: selected
                  ? HugeIcons.strokeRoundedCheckmarkCircle01
                  : HugeIcons.strokeRoundedCircle,
              size: 20,
              color: selected ? colors.primary : colors.mutedForeground,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                method.titolo,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
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

class _DateTile extends StatelessWidget {
  const _DateTile({
    required this.label,
    required this.value,
    required this.onPick,
  });
  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onPick;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return AppCard(
      onTap: () async {
        final d = await pickDate(context, initial: value);
        if (d != null) onPick(d);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: context.theme.typography.body.xs
                .copyWith(color: colors.mutedForeground),
          ),
          Text(
            dateShort.format(value),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _CritSelect extends StatelessWidget {
  const _CritSelect({
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final CriterioQuota value;
  final ValueChanged<CriterioQuota> onChanged;

  @override
  Widget build(BuildContext context) {
    return FSelect<CriterioQuota>(
      label: Text(label),
      control: FSelectControl.lifted(
        value: value,
        onChange: (v) {
          if (v != null) onChanged(v);
        },
      ),
      items: {
        for (final c in CriterioQuota.values) c.label: c,
      },
    );
  }
}
