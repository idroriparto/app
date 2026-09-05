import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hugeicons/hugeicons.dart';

import '../data/store.dart';
import '../theme/theme.dart';
import '../widgets/widgets.dart';

/// Breve presentazione mostrata solo su una nuova installazione.
///
/// La configurazione del condominio resta nel [WelcomeScreen]: qui l'utente
/// capisce prima cosa può fare e può saltare in ogni momento al flusso noto.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _steps = <_TourStep>[
    _TourStep(
      icon: HugeIcons.strokeRoundedBuilding03,
      eyebrow: 'PRIMO PASSO',
      title: 'Tutto il condominio,\nin ordine.',
      description:
          'Crea l’anagrafica e raccogli le informazioni che servono per una ripartizione chiara.',
      details: [
        'Unità immobiliari e interni',
        'Millesimi, occupanti e sfitto',
        'Dati sempre salvati sul dispositivo',
      ],
    ),
    _TourStep(
      icon: HugeIcons.strokeRoundedDashboardSpeed02,
      eyebrow: 'DURANTE L’ANNO',
      title: 'Letture e bollette,\nsenza fogli sparsi.',
      description:
          'Registra i contatori, aggiungi la bolletta e conserva un periodo di riferimento preciso.',
      details: [
        'Letture per ogni unità',
        'Contatore generale facoltativo',
        'Quota consumo, fissa e comune',
      ],
    ),
    _TourStep(
      icon: HugeIcons.strokeRoundedReceiptText,
      eyebrow: 'AL MOMENTO DEL CONTO',
      title: 'Un riparto pronto\nda spiegare.',
      description:
          'Calcola le quote, confronta i metodi e prepara un prospetto leggibile per l’assemblea.',
      details: [
        'Consumi individuali e millesimi',
        'Confronto tra criteri di riparto',
        'Esportazione del prospetto in PDF',
      ],
    ),
  ];

  int _step = 0;
  bool _finishing = false;

  void _next() {
    if (_step == _steps.length - 1) {
      _finish();
      return;
    }
    AppMotion.tap();
    setState(() => _step++);
  }

  void _previous() {
    if (_step == 0) return;
    AppMotion.tap();
    setState(() => _step--);
  }

  Future<void> _finish() async {
    if (_finishing) return;
    AppMotion.tap();
    setState(() => _finishing = true);
    await StoreScope.read(context).completeOnboarding();
    if (mounted) setState(() => _finishing = false);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final type = context.theme.typography;
    final step = _steps[_step];
    final last = _step == _steps.length - 1;
    final transitionDuration = AppMotion.of(context, AppMotion.dSpatial);

    return FScaffold(
      childPad: false,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 660),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const LogoMark(size: 44),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'IdroRiparto',
                              style: type.body.lg.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Benvenuto',
                              style: type.body.xs.copyWith(
                                color: colors.mutedForeground,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${_step + 1} di ${_steps.length}',
                        style: type.body.xs.copyWith(
                          color: colors.mutedForeground,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 36),
                  Row(
                    children: List.generate(
                      _steps.length,
                      (index) => Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: index == _steps.length - 1 ? 0 : 7,
                          ),
                          child: AnimatedContainer(
                            duration: AppMotion.of(context, AppMotion.dEffects),
                            height: 4,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(99),
                              color: index <= _step
                                  ? colors.primary
                                  : colors.muted,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  AnimatedSwitcher(
                    duration: transitionDuration,
                    reverseDuration: transitionDuration,
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeOutCubic,
                    transitionBuilder: (child, animation) {
                      if (AppMotion.reduce(context)) return child;
                      final offset = Tween<Offset>(
                        begin: const Offset(0.035, 0),
                        end: Offset.zero,
                      ).animate(animation);
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(position: offset, child: child),
                      );
                    },
                    child: _TourContent(key: ValueKey(_step), step: step),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: FButton(
                      onPress: _finishing ? null : _next,
                      size: FButtonSizeVariant.lg,
                      suffix: last
                          ? HugeIcon(
                              icon: HugeIcons.strokeRoundedArrowRight01,
                              size: 19,
                            )
                          : null,
                      child: Text(last ? 'Inizia ora' : 'Continua'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: FButton(
                          onPress: _finishing
                              ? null
                              : (last ? _previous : _finish),
                          variant: FButtonVariant.ghost,
                          child: Text(
                            last ? 'Indietro' : 'Salta presentazione',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Potrai rivedere questa presentazione dalle impostazioni.',
                    textAlign: TextAlign.center,
                    style: type.body.xs.copyWith(color: colors.mutedForeground),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TourContent extends StatelessWidget {
  const _TourContent({super.key, required this.step});

  final _TourStep step;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final type = context.theme.typography;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.11),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
          ),
          child: SizedBox(
            height: 172,
            width: double.infinity,
            child: Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  // Il segno grafico del marchio resta sempre #2264E2 su una
                  // superficie chiara: contrasto 5.26:1 anche in tema scuro.
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: colors.primary.withValues(alpha: 0.22),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: HugeIcon(
                    icon: step.icon as List<List<dynamic>>,
                    size: 48,
                    color: kBrandBlue,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 30),
        Text(
          step.eyebrow,
          style: type.body.xs.copyWith(
            color: colors.primary,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.15,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          step.title,
          style: type.display.xl2.copyWith(
            fontWeight: FontWeight.w700,
            height: 1.12,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          step.description,
          style: type.body.md.copyWith(
            color: colors.mutedForeground,
            height: 1.48,
          ),
        ),
        const SizedBox(height: 22),
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              for (var index = 0; index < step.details.length; index++) ...[
                _DetailRow(text: step.details[index]),
                if (index != step.details.length - 1)
                  const SizedBox(height: 13),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Row(
      children: [
        HugeIcon(
          icon: HugeIcons.strokeRoundedCheckmarkCircle02,
          size: 18,
          color: colors.primary,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: context.theme.typography.body.sm.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _TourStep {
  const _TourStep({
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.details,
  });

  final Object icon;
  final String eyebrow;
  final String title;
  final String description;
  final List<String> details;
}
