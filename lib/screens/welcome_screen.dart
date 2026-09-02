import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hugeicons/hugeicons.dart';

import '../data/store.dart';
import '../models/models.dart';
import '../utils/ids.dart';
import '../widgets/widgets.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _nomeKey = GlobalKey<FormFieldState<String>>();
  final _nome = TextEditingController();
  final _indirizzo = TextEditingController();
  final _citta = TextEditingController();
  final _cap = TextEditingController();
  final _ammin = TextEditingController();
  MetodoRiparto _metodo = MetodoRiparto.contatori;
  bool _busy = false;

  @override
  void dispose() {
    _nome.dispose();
    _indirizzo.dispose();
    _citta.dispose();
    _cap.dispose();
    _ammin.dispose();
    super.dispose();
  }

  Future<void> _demo() async {
    setState(() => _busy = true);
    await StoreScope.read(context).loadDemo();
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _create() async {
    if (!(_nomeKey.currentState?.validate() ?? false)) return;
    setState(() => _busy = true);
    final c = Condominio(
      id: newId('cnd'),
      nome: _nome.text.trim(),
      indirizzo: _indirizzo.text.trim(),
      citta: _citta.text.trim(),
      cap: _cap.text.trim(),
      amministratore: _ammin.text.trim(),
      metodoDefault: _metodo,
    );
    await StoreScope.read(context).saveCondominio(c);
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final hero = _HeroPanel(onDemo: _busy ? null : _demo, fill: wide);
    final form = _FormPanel(
      nomeKey: _nomeKey,
      nome: _nome,
      indirizzo: _indirizzo,
      citta: _citta,
      cap: _cap,
      ammin: _ammin,
      metodo: _metodo,
      busy: _busy,
      onMetodo: (m) => setState(() => _metodo = m),
      onCreate: _create,
      onDemo: _demo,
    );

    if (wide) {
      return FScaffold(
        childPad: false,
        child: Row(
          children: [
            Expanded(child: hero),
            Expanded(child: form),
          ],
        ),
      );
    }
    return FScaffold(childPad: false, child: ListView(children: [hero, form]));
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({this.onDemo, this.fill = false});
  final VoidCallback? onDemo;
  final bool fill;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final content = SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: fill ? MainAxisSize.max : MainAxisSize.min,
          children: [
            const LogoMark(size: 72),
            if (fill) const Spacer() else const SizedBox(height: 28),
            Text(
              'L’acqua del condominio,\nripagata con chiarezza.',
              style: context.theme.typography.display.sm.copyWith(
                color: colors.primaryForeground,
                fontWeight: FontWeight.w700,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Contatori individuali, parti comuni a millesimi, quota fissa in '
              'parti uguali. Un prospetto pronto per l’assemblea, in un’app che '
              'resta sul dispositivo.',
              style: context.theme.typography.body.sm.copyWith(
                color: colors.primaryForeground.withValues(alpha: 0.9),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 22),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: const [
                _Tag('Contatori individuali'),
                _Tag('Art. 1123 c.c.'),
                _Tag('Prospetto PDF'),
                _Tag('Confronto metodi'),
              ],
            ),
            const SizedBox(height: 18),
            FButton(
              onPress: onDemo,
              variant: FButtonVariant.secondary,
              child: const Text('Apri l’esempio di Milano'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    return ColoredBox(
      color: colors.primary,
      child: fill ? SizedBox.expand(child: content) : content,
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.primaryForeground.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Text(
          text,
          style: TextStyle(
            color: colors.primaryForeground,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _FormPanel extends StatelessWidget {
  const _FormPanel({
    required this.nomeKey,
    required this.nome,
    required this.indirizzo,
    required this.citta,
    required this.cap,
    required this.ammin,
    required this.metodo,
    required this.busy,
    required this.onMetodo,
    required this.onCreate,
    required this.onDemo,
  });

  final GlobalKey<FormFieldState<String>> nomeKey;
  final TextEditingController nome;
  final TextEditingController indirizzo;
  final TextEditingController citta;
  final TextEditingController cap;
  final TextEditingController ammin;
  final MetodoRiparto metodo;
  final bool busy;
  final ValueChanged<MetodoRiparto> onMetodo;
  final VoidCallback onCreate;
  final VoidCallback onDemo;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Crea il tuo condominio',
                  style: context.theme.typography.display.sm.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Potrai aggiungere le unità e le letture subito dopo. '
                  'I dati restano solo su questo dispositivo.',
                  style: context.theme.typography.body.sm.copyWith(
                    color: colors.mutedForeground,
                  ),
                ),
                const SizedBox(height: 24),
                ItField(
                  label: 'Nome del condominio',
                  controller: nome,
                  formFieldKey: nomeKey,
                  hint: 'es. Palazzo Solferino',
                  autofocus: true,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Obbligatorio' : null,
                ),
                const SizedBox(height: 12),
                ItField(label: 'Indirizzo', controller: indirizzo),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ItField(label: 'CAP', controller: cap),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ItField(label: 'Città', controller: citta),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ItField(
                  label: 'Amministratore (facoltativo)',
                  controller: ammin,
                ),
                const SizedBox(height: 20),
                const SectionLabel('Criterio di default'),
                for (final m in MetodoRiparto.values)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _MethodTile(
                      method: m,
                      selected: metodo == m,
                      onTap: () {
                        AppMotion.tap();
                        onMetodo(m);
                      },
                    ),
                  ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FButton(
                    onPress: busy ? null : onCreate,
                    child: Text(busy ? 'Un attimo…' : 'Inizia'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FButton(
                    variant: FButtonVariant.outline,
                    onPress: busy ? null : onDemo,
                    child: const Text('Meglio vedere un esempio'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MethodTile extends StatelessWidget {
  const _MethodTile({
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
    final radius = context.theme.style.borderRadius.lg;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: HugeIcon(
              icon: selected
                  ? HugeIcons.strokeRoundedCheckmarkCircle01
                  : HugeIcons.strokeRoundedCircle,
              size: 20,
              color: selected ? colors.primary : colors.mutedForeground,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  method.titolo,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: selected ? colors.primary : colors.foreground,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  method.descrizione,
                  style: context.theme.typography.body.xs.copyWith(
                    color: colors.mutedForeground,
                    height: 1.4,
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
