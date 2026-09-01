import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hugeicons/hugeicons.dart';

import '../data/store.dart';
import '../models/models.dart';
import '../utils/format.dart';
import '../widgets/widgets.dart';
import 'bollette_screens.dart';
import 'letture_screens.dart';
import 'riparto_screen.dart';
import 'unita_screens.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final c = store.condominio!;
    final last = store.ultimaBolletta;
    final rip = last == null ? null : store.ripartoDi(last.id);
    final colors = context.theme.colors;
    final typo = context.theme.typography;
    final millOff =
        (store.sommaMillesimi - c.millesimiRiferimento).abs() > 0.05;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: ColoredBox(
            color: colors.primary,
            child: SafeArea(
              bottom: false,
              child: MaxWidth(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        greetingFor(DateTime.now()),
                        style: typo.body.xs.copyWith(
                          color: colors.primaryForeground
                              .withValues(alpha: 0.85),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        c.nome,
                        style: typo.display.sm.copyWith(
                          color: colors.primaryForeground,
                          fontWeight: FontWeight.w700,
                          height: 1.1,
                        ),
                      ),
                      if (c.indirizzoCompleto.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          c.indirizzoCompleto,
                          style: typo.body.xs.copyWith(
                            color: colors.primaryForeground
                                .withValues(alpha: 0.88),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _Quick(
                            icon: HugeIcons.strokeRoundedDashboardSpeed02,
                            label: 'Nuova lettura',
                            onTap: () =>
                                pushApp(context, const LetturaBulkScreen()),
                          ),
                          _Quick(
                            icon: HugeIcons.strokeRoundedReceiptText,
                            label: 'Nuova bolletta',
                            onTap: () =>
                                pushApp(context, const BollettaFormScreen()),
                          ),
                          _Quick(
                            icon: HugeIcons.strokeRoundedAdd01,
                            label: 'Aggiungi unità',
                            onTap: () =>
                                pushApp(context, const UnitaFormScreen()),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          sliver: SliverToBoxAdapter(
            child: MaxWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MetricGrid(
                    children: [
                      MetricTile(
                        label: 'Unità',
                        value: '${store.unita.length}',
                        hint: '${store.occupantiTotali} occupanti',
                        icon: HugeIcons.strokeRoundedBuilding03,
                      ),
                      MetricTile(
                        label: 'Millesimi',
                        value: mill(store.sommaMillesimi),
                        hint: millOff
                            ? 'Attesi ${mill(c.millesimiRiferimento)}'
                            : 'Allineati a ${mill(c.millesimiRiferimento)}',
                        icon: HugeIcons.strokeRoundedPieChart,
                        tone: millOff ? colors.error : colors.primary,
                      ),
                      MetricTile(
                        label: 'Ultima bolletta',
                        value: last == null ? '—' : euro(last.totale),
                        hint: last == null
                            ? 'Nessuna registrata'
                            : periodLabel(last.periodoDal, last.periodoAl),
                        icon: HugeIcons.strokeRoundedMoney01,
                      ),
                      MetricTile(
                        label: 'Metodo',
                        value: c.metodoDefault.label,
                        hint: 'Predefinito del condominio',
                        icon: HugeIcons.strokeRoundedBalanceScale,
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  if (rip != null && last != null) ...[
                    SectionLabel(
                      'Ultimo riparto',
                      trailing: FButton(
                        variant: FButtonVariant.ghost,
                        size: FButtonSizeVariant.sm,
                        onPress: () => pushApp(
                          context,
                          RipartoScreen(bollettaId: last.id),
                        ),
                        child: const Text('Apri prospetto'),
                      ),
                    ),
                    AppCard(
                      onTap: () => pushApp(
                        context,
                        RipartoScreen(bollettaId: last.id),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  periodLabel(last.periodoDal, last.periodoAl),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: typo.body.lg
                                      .copyWith(fontWeight: FontWeight.w700),
                                ),
                              ),
                              const SizedBox(width: 8),
                              StatoChip(last.stato),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${last.metodo.titolo} · ${last.fornitore.isEmpty ? c.fornitore : last.fornitore}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: typo.body.xs
                                .copyWith(color: colors.mutedForeground),
                          ),
                          const SizedBox(height: 16),
                          ShareBar(
                            parts: [
                              for (final r in rip.righe)
                                (
                                  color: UnitColor.forUnit(
                                    context,
                                    r.unitaId,
                                  ),
                                  value: r.totale,
                                ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 18,
                            runSpacing: 8,
                            children: [
                              _kv(context, 'Totale', euro(rip.totaleGenerale)),
                              _kv(context, 'Consumi', mc(rip.sommaConsumi)),
                              _kv(
                                context,
                                'Parti comuni',
                                mc(rip.consumoComune),
                              ),
                              _kv(context, '€ / m³', euro(rip.prezzoMedioMc)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],
                  if (store.bollette.isNotEmpty) ...[
                    const SectionLabel('Andamento delle bollette'),
                    AppCard(
                      child: _BillsBars(
                        bollette: store.bollette
                            .take(6)
                            .toList()
                            .reversed
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],
                  const SectionLabel('Come funziona il riparto a contatori'),
                  const AppCard(
                    child: Column(
                      children: [
                        _How(
                          n: '1',
                          t: 'Consumi individuali',
                          d:
                              'Ciascuna unità paga esattamente i metri cubi segnati '
                              'dal proprio contatore, al prezzo medio al m³.',
                        ),
                        SizedBox(height: 16),
                        _How(
                          n: '2',
                          t: 'Parti comuni e perdite',
                          d:
                              'La differenza tra il contatore generale (fatturato) e '
                              'la somma dei contatori individuali si ripartisce a millesimi.',
                        ),
                        SizedBox(height: 16),
                        _How(
                          n: '3',
                          t: 'Quota fissa',
                          d:
                              'Canone e nolo contatore sono divisi in parti uguali tra '
                              'tutte le unità. IVA e altre voci seguono il subtotale.',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _kv(BuildContext context, String k, String v) {
    final colors = context.theme.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(k, style: typoXs(context, colors.mutedForeground)),
        Text(
          v,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  static TextStyle typoXs(BuildContext context, Color c) =>
      context.theme.typography.body.xs.copyWith(color: c, fontSize: 12);
}

class _Quick extends StatelessWidget {
  const _Quick({required this.icon, required this.label, required this.onTap});
  final Object icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return FButton(
      variant: FButtonVariant.secondary,
      onPress: onTap,
      prefix: HugeIcon(
        icon: icon as List<List<dynamic>>,
        size: 18,
        color: colors.primaryForeground,
      ),
      child: Text(
        label,
        style: TextStyle(color: colors.primaryForeground),
      ),
    );
  }
}

class _How extends StatelessWidget {
  const _How({required this.n, required this.t, required this.d});
  final String n;
  final String t;
  final String d;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Text(
            n,
            style: TextStyle(
              color: colors.primary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(
                d,
                style: context.theme.typography.body.xs
                    .copyWith(color: colors.mutedForeground, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BillsBars extends StatelessWidget {
  const _BillsBars({required this.bollette});
  final List<Bolletta> bollette;

  @override
  Widget build(BuildContext context) {
    final maxV =
        bollette.map((b) => b.totale).fold<double>(0, (a, b) => a > b ? a : b);
    final colors = context.theme.colors;
    return SizedBox(
      height: 188,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < bollette.length; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        euro(bollette[i].totale),
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 10,
                          color: colors.mutedForeground,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Flexible(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(
                          begin: 0.04,
                          end: maxV <= 0
                              ? 0.08
                              : (bollette[i].totale / maxV).clamp(0.08, 1),
                        ),
                        duration: Duration(milliseconds: 460 + i * 60),
                        curve: Curves.easeOutCubic,
                        builder: (context, t, _) => FractionallySizedBox(
                          heightFactor: t,
                          widthFactor: 1,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              color: colors.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      DateFormatMini.fmt(bollette[i].periodoAl),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.theme.typography.body.xs
                          .copyWith(color: colors.mutedForeground),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class DateFormatMini {
  static String fmt(DateTime d) {
    const m = [
      'gen', 'feb', 'mar', 'apr', 'mag', 'giu',
      'lug', 'ago', 'set', 'ott', 'nov', 'dic',
    ];
    return '${m[d.month - 1]} ${d.year % 100}';
  }
}
