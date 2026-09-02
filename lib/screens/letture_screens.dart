import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';
import 'package:hugeicons/hugeicons.dart';

import '../data/store.dart';
import '../models/models.dart';
import '../utils/format.dart';
import '../widgets/widgets.dart';

class LettureScreen extends StatelessWidget {
  const LettureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final colors = context.theme.colors;
    final typo = context.theme.typography;
    final groups = <String, List<Lettura>>{};
    for (final l in store.letture) {
      final key = dateShort.format(l.data);
      groups.putIfAbsent(key, () => []).add(l);
    }
    final keys = groups.keys.toList();

    return FScaffold(
      childPad: false,
      child: Stack(
        children: [
          SafeArea(
            child: store.letture.isEmpty
                ? EmptyState(
                    icon: HugeIcons.strokeRoundedDashboardSpeed02,
                    title: 'Nessuna lettura',
                    subtitle:
                        'Registra i contatori di tutte le unità in una volta sola. Il consumo si calcola sulla differenza rispetto alla lettura precedente.',
                    actionLabel: 'Registra i contatori',
                    onAction: () => pushApp(context, const LetturaBulkScreen()),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 108),
                    children: [
                      MaxWidth(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Letture contatori',
                              style: typo.display.md.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Ogni campagna raccoglie il generale e i sottocontatori nella stessa data.',
                              style: typo.body.sm.copyWith(
                                color: colors.mutedForeground,
                              ),
                            ),
                            const SizedBox(height: 18),
                            for (final k in keys)
                              _DayGroup(label: k, letture: groups[k]!),
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
              icon: HugeIcons.strokeRoundedClipboard,
              label: 'Campagna letture',
              onPress: () => pushApp(context, const LetturaBulkScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

class _DayGroup extends StatelessWidget {
  const _DayGroup({required this.label, required this.letture});
  final String label;
  final List<Lettura> letture;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final colors = context.theme.colors;
    final gen = letture.where((l) => l.isGenerale).toList();
    final altri = letture.where((l) => !l.isGenerale).toList();
    double somma = 0;
    for (final l in altri) {
      somma += l.valore;
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: context.theme.typography.body.lg.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (gen.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedDroplet,
                    size: 16,
                    color: colors.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Generale ${mc(gen.first.valore)}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            for (final l in altri)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 52,
                      child: Text(
                        'int. ${store.unitaById(l.unitaId)?.interno ?? '—'}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        store.unitaById(l.unitaId)?.proprietario ?? '',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: colors.mutedForeground),
                      ),
                    ),
                    Text(
                      mcNum(l.valore),
                      style: const TextStyle(
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            const FDivider(),
            Text(
              'Somma sottocontatori: ${mc(somma)}',
              style: context.theme.typography.body.xs.copyWith(
                color: colors.mutedForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LetturaBulkScreen extends StatefulWidget {
  const LetturaBulkScreen({super.key});

  @override
  State<LetturaBulkScreen> createState() => _LetturaBulkScreenState();
}

class _LetturaBulkScreenState extends State<LetturaBulkScreen> {
  late DateTime data;
  final generale = TextEditingController();
  final note = TextEditingController();
  final controllers = <String, TextEditingController>{};

  @override
  void initState() {
    super.initState();
    data = DateTime.now();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final store = StoreScope.of(context);
    for (final u in store.unita) {
      controllers.putIfAbsent(u.id, TextEditingController.new);
    }
  }

  @override
  void dispose() {
    generale.dispose();
    note.dispose();
    for (final c in controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final store = StoreScope.read(context);
    final valori = <String, double>{};
    for (final u in store.unita) {
      final v = parseItNumber(controllers[u.id]?.text ?? '');
      if (v != null) valori[u.id] = v;
    }
    if (valori.isEmpty) {
      showToast(context, 'Inserisci almeno una lettura');
      return;
    }
    await store.salvaCampagnaLetture(
      data: data,
      valori: valori,
      generale: parseItNumber(generale.text),
      note: note.text.trim().isEmpty ? null : note.text.trim(),
    );
    if (mounted) {
      showToast(context, 'Letture salvate');
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final colors = context.theme.colors;
    final typo = context.theme.typography;
    return FScaffold(
      childPad: false,
      header: FHeader.nested(
        prefixes: [backAction(context)],
        title: const Text('Campagna letture'),
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
                  onTap: () async {
                    final d = await pickDate(context, initial: data);
                    if (d != null) setState(() => data = d);
                  },
                  child: Row(
                    children: [
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedCalendar01,
                        size: 20,
                        color: colors.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Data della campagna',
                              style: typo.body.xs.copyWith(
                                color: colors.mutedForeground,
                              ),
                            ),
                            Text(
                              dateIt.format(data),
                              style: typo.body.md.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedArrowRight01,
                        size: 18,
                        color: colors.mutedForeground,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ItField(
                  label: 'Contatore generale (m³)',
                  controller: generale,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  hint: 'Lettura del contatore MM / gestore',
                ),
                const SizedBox(height: 18),
                const SectionLabel('Sottocontatori'),
                for (final u in store.unita)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        InternoAvatar(unita: u, size: 40),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                u.titolo,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                () {
                                  final prev = store.ultimaLetturaDi(u.id);
                                  return prev == null
                                      ? 'Nessuna lettura precedente'
                                      : 'Prec. ${mcNum(prev.valore)} · ${dateShort.format(prev.data)}';
                                }(),
                                style: typo.body.xs.copyWith(
                                  color: colors.mutedForeground,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 130,
                          child: FTextField(
                            control: FTextFieldControl.managed(
                              controller: controllers[u.id],
                              onChange: (_) => setState(() {}),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            textAlign: TextAlign.right,
                            hint: 'm³',
                          ),
                        ),
                      ],
                    ),
                  ),
                Builder(
                  builder: (context) {
                    var sum = 0.0;
                    var n = 0;
                    for (final u in store.unita) {
                      final v = parseItNumber(controllers[u.id]?.text ?? '');
                      if (v != null) {
                        sum += v;
                        n++;
                      }
                    }
                    final g = parseItNumber(generale.text);
                    return Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 12),
                      child: Text(
                        n == 0
                            ? 'Inserisci le letture assolute, non i consumi.'
                            : 'Somma letture $n unità: ${mc(sum)}'
                                  '${g == null ? '' : ' · generale ${mc(g)}'}',
                        style: typo.body.xs.copyWith(
                          color: colors.mutedForeground,
                        ),
                      ),
                    );
                  },
                ),
                ItField(label: 'Note', controller: note),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: FButton(
                    onPress: _save,
                    child: const Text('Salva campagna'),
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
