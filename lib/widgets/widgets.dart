import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';
import 'package:hugeicons/hugeicons.dart';

import '../models/models.dart';
import '../utils/format.dart';

/// ---------------------------------------------------------------------------
/// Logo
/// ---------------------------------------------------------------------------
class LogoMark extends StatelessWidget {
  const LogoMark({super.key, this.size = 56, this.rounded = true});
  final double size;
  final bool rounded;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(size * 0.24);
    return ClipRRect(
      borderRadius: rounded ? radius : BorderRadius.zero,
      child: Image.asset(
        'assets/brand/logo_source.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// Layout helpers
/// ---------------------------------------------------------------------------
class MaxWidth extends StatelessWidget {
  const MaxWidth({super.key, required this.child, this.width = 1120});
  final Widget child;
  final double width;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: width),
      child: child,
    ),
  );
}

/// Etichetta di sezione (maiolico, distanziata).
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typo = context.theme.typography;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: typo.body.xs.copyWith(
                color: colors.mutedForeground,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.05,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// Card (wrap Forui FCard; tappabile tramite FTappable)
/// ---------------------------------------------------------------------------
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Padding(padding: padding, child: child);
    return FCard(
      clipBehavior: Clip.antiAlias,
      child: onTap == null
          ? content
          : FTappable(onPress: onTap, child: content),
    );
  }
}

/// ---------------------------------------------------------------------------
/// Metric tile
/// ---------------------------------------------------------------------------
class MetricTile extends StatelessWidget {
  const MetricTile({
    super.key,
    required this.label,
    required this.value,
    this.hint,
    this.icon,
    this.tone,
  });

  final String label;
  final String value;
  final String? hint;
  final List<List<dynamic>>? icon;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typo = context.theme.typography;
    final c = tone ?? colors.primary;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                HugeIcon(icon: icon!, size: 18, color: colors.primary),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: typo.body.xs.copyWith(color: colors.mutedForeground),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: typo.display.lg.copyWith(
                color: c,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          if (hint != null) ...[
            const SizedBox(height: 4),
            Text(
              hint!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: typo.body.xs.copyWith(color: colors.mutedForeground),
            ),
          ],
        ],
      ),
    );
  }
}

class MetricGrid extends StatelessWidget {
  const MetricGrid({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final cols = box.maxWidth > 720 ? 4 : 2;
      const gap = 12.0;
      // Righe esplicite + IntrinsicHeight + stretch: ogni card della riga ha
      // la stessa larghezza (Expanded) e la stessa altezza della card più
      // alta della riga, così i box della griglia risultano allineati.
      final rows = <Widget>[];
      for (var start = 0; start < children.length; start += cols) {
        final rowChildren = <Widget>[];
        for (var j = 0; j < cols; j++) {
          final i = start + j;
          if (j > 0) rowChildren.add(const SizedBox(width: gap));
          rowChildren.add(
            Expanded(
              child: i < children.length
                  ? Appear(index: i, child: children[i])
                  : const SizedBox.shrink(),
            ),
          );
        }
        rows.add(
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: rowChildren,
            ),
          ),
        );
        if (start + cols < children.length) {
          rows.add(const SizedBox(height: gap));
        }
      }
      return Column(children: rows);
    },
  );
}

/// ---------------------------------------------------------------------------
/// Money / pills / status
/// ---------------------------------------------------------------------------
class MoneyText extends StatelessWidget {
  const MoneyText(
    this.amount, {
    super.key,
    this.style,
    this.color,
    this.big = false,
  });
  final num amount;
  final TextStyle? style;
  final Color? color;
  final bool big;

  @override
  Widget build(BuildContext context) {
    final typo = context.theme.typography;
    final base = big ? typo.display.lg : typo.body.sm;
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerRight,
      child: Text(
        euro(amount),
        maxLines: 1,
        style: (style ?? base).copyWith(
          color: color ?? context.theme.colors.foreground,
          fontWeight: big ? FontWeight.w700 : FontWeight.w600,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class InternoAvatar extends StatelessWidget {
  const InternoAvatar({super.key, required this.unita, this.size = 44});
  final UnitaImmobiliare unita;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = UnitColor.forUnit(context, unita.id);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Text(
        unita.interno,
        maxLines: 1,
        style: TextStyle(
          color: c,
          fontSize: size * 0.32,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Colori coerenti per unità (derivati dai token forui).
class UnitColor {
  static Color forUnit(BuildContext context, String id) {
    final colors = context.theme.colors;
    final palette = <Color>[
      colors.primary,
      colors.destructive,
      colors.foreground,
      colors.mutedForeground,
    ];
    return palette[id.hashCode.abs() % palette.length];
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label, this.color, this.icon});
  final String label;
  final Color? color;
  final List<List<dynamic>>? icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final c = color ?? colors.primary;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              HugeIcon(icon: icon!, size: 13, color: c),
              const SizedBox(width: 4),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: c,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StatoChip extends StatelessWidget {
  const StatoChip(this.stato, {super.key});
  final StatoBolletta stato;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final color = switch (stato) {
      StatoBolletta.bozza => colors.mutedForeground,
      StatoBolletta.calcolata => colors.primary,
      StatoBolletta.chiusa => colors.foreground,
    };
    return StatusPill(label: stato.label, color: color);
  }
}

/// Banner avvisi (usa FAlert di forui).
class WarningBanner extends StatelessWidget {
  const WarningBanner({super.key, required this.messages});
  final List<String> messages;

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final m in messages)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: FAlert(
              icon: const HugeIcon(
                icon: HugeIcons.strokeRoundedAlertCircle,
                size: 18,
              ),
              title: const Text('Da verificare'),
              subtitle: Text(m),
            ),
          ),
      ],
    );
  }
}

/// ---------------------------------------------------------------------------
/// Empty state
/// ---------------------------------------------------------------------------
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final List<List<dynamic>> icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typo = context.theme.typography;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              HugeIcon(icon: icon, size: 40, color: colors.mutedForeground),
              const SizedBox(height: 18),
              Text(
                title,
                textAlign: TextAlign.center,
                style: typo.display.sm.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: typo.body.sm.copyWith(color: colors.mutedForeground),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 20),
                FButton(onPress: onAction, child: Text(actionLabel!)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// Form
/// ---------------------------------------------------------------------------
class ItField extends StatelessWidget {
  const ItField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.keyboardType,
    this.validator,
    this.maxLines = 1,
    this.onChanged,
    this.enabled = true,
    this.autofocus = false,
    this.inputFormatters,
    this.textAlign = TextAlign.start,
    this.suffix,
    this.prefixIcon,
    this.formFieldKey,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final int maxLines;
  final ValueChanged<String>? onChanged;
  final bool enabled;
  final bool autofocus;
  final List<TextInputFormatter>? inputFormatters;
  final TextAlign textAlign;
  final Widget? suffix;
  final List<List<dynamic>>? prefixIcon;

  /// Chiave dello stato FormField, per validare il campo senza un `Form`
  /// (i campi forui si validano singolarmente, non esiste un FForm).
  final Key? formFieldKey;

  @override
  Widget build(BuildContext context) {
    return FTextFormField(
      control: FTextFieldControl.managed(
        controller: controller,
        onChange: onChanged == null ? null : (value) => onChanged!(value.text),
      ),
      enabled: enabled,
      keyboardType: keyboardType,
      autofocus: autofocus,
      maxLines: maxLines,
      textAlign: textAlign,
      inputFormatters: inputFormatters,
      validator: validator,
      formFieldKey: formFieldKey,
      label: Text(label),
      hint: hint,
      prefixBuilder: prefixIcon == null
          ? null
          : (context, style, variants) => HugeIcon(
              icon: prefixIcon!,
              size: 18,
              color: context.theme.colors.mutedForeground,
            ),
      suffixBuilder: suffix == null
          ? null
          : (context, style, variants) => Padding(
              padding: const EdgeInsets.only(right: 10),
              child: DefaultTextStyle(
                style: context.theme.typography.body.xs.copyWith(
                  color: context.theme.colors.mutedForeground,
                ),
                child: suffix!,
              ),
            ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// Charts / bars
/// ---------------------------------------------------------------------------
class ShareBar extends StatelessWidget {
  const ShareBar({super.key, required this.parts});
  final List<({Color color, double value})> parts;

  @override
  Widget build(BuildContext context) {
    final tot = parts.fold<double>(0, (a, b) => a + b.value);
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: SizedBox(
        height: 12,
        child: Row(
          children: [
            for (final p in parts)
              if (p.value > 0)
                Expanded(
                  flex: (p.value / (tot <= 0 ? 1 : tot) * 1000).round().clamp(
                    1,
                    1000,
                  ),
                  child: ColoredBox(color: p.color),
                ),
          ],
        ),
      ),
    );
  }
}

class UnitShareChart extends StatelessWidget {
  const UnitShareChart({super.key, required this.righe});
  final List<RigaRiparto> righe;

  @override
  Widget build(BuildContext context) {
    if (righe.isEmpty) return const SizedBox.shrink();
    final colors = context.theme.colors;
    final maxV = righe
        .map((e) => e.totale)
        .fold<double>(0, (a, b) => a > b ? a : b);
    return Column(
      children: [
        for (var i = 0; i < righe.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  child: Text(
                    righe[i].interno,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Expanded(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(
                      begin: 0,
                      end: maxV <= 0 ? 0 : (righe[i].totale / maxV).clamp(0, 1),
                    ),
                    duration: const Duration(milliseconds: 420),
                    curve: Curves.easeOutCubic,
                    builder: (context, t, _) => Stack(
                      children: [
                        Container(
                          height: 22,
                          decoration: BoxDecoration(
                            color: colors.muted,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: t,
                          child: Container(
                            height: 22,
                            decoration: BoxDecoration(
                              color: UnitColor.forUnit(
                                context,
                                righe[i].unitaId,
                              ),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 84,
                  child: Text(
                    euro(righe[i].totale),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontFeatures: const [FontFeature.tabularFigures()],
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: colors.foreground,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// ---------------------------------------------------------------------------
/// Motion / navigation / feedback helpers
/// ---------------------------------------------------------------------------
class AppMotion {
  static const dFast = Duration(milliseconds: 150);
  static const dEffects = Duration(milliseconds: 200);
  static const dSpatial = Duration(milliseconds: 380);

  static bool reduce(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context);

  static Duration of(BuildContext context, Duration raw) =>
      reduce(context) ? Duration.zero : raw;

  static void tap() => HapticFeedback.selectionClick();
}

class AppPageRoute<T> extends PageRouteBuilder<T> {
  AppPageRoute({required WidgetBuilder builder, super.settings})
    : super(
        pageBuilder: (context, animation, secondary) => builder(context),
        transitionDuration: AppMotion.dEffects,
        reverseTransitionDuration: AppMotion.dFast,
        transitionsBuilder: (context, animation, secondary, child) {
          if (AppMotion.reduce(context)) return child;
          return FadeTransition(opacity: animation, child: child);
        },
      );
}

Future<T?> pushApp<T>(BuildContext context, Widget page) {
  AppMotion.tap();
  return Navigator.of(context).push<T>(AppPageRoute(builder: (_) => page));
}

/// Azione "indietro" per gli header delle schermate aperte con [pushApp]:
/// equivale al tasto back automatico dell'AppBar Material.
FHeaderAction backAction(BuildContext context) =>
    FHeaderAction.back(onPress: () => Navigator.of(context).maybePop());

/// Pulsante flottante Forui-style: sostituisce la FloatingActionButton
/// Material (forui non ha un widget FAB dedicato). Da posizionare con uno
/// [Positioned] in fondo alle schermate a elenco.
class FabAction extends StatelessWidget {
  const FabAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onPress,
  });

  final Object icon;
  final String label;
  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) {
    // Il variant primario di forui usa già colors.primary / primaryForeground,
    // come la FloatingActionButton.extended che questo widget sostituisce.
    return FButton(
      onPress: onPress,
      prefix: HugeIcon(icon: icon as List<List<dynamic>>, size: 18),
      child: Text(label),
    );
  }
}

class Appear extends StatelessWidget {
  const Appear({
    super.key,
    required this.child,
    this.index = 0,
    this.slide = 0,
  });

  final Widget child;
  final int index;
  final double slide;

  @override
  Widget build(BuildContext context) {
    if (AppMotion.reduce(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 220 + index * 26),
      curve: Curves.easeOut,
      builder: (context, t, child) {
        Widget out = Opacity(opacity: t.clamp(0.0, 1.0), child: child);
        if (slide != 0) {
          out = Transform.translate(
            offset: Offset(0, (1 - t) * slide),
            child: out,
          );
        }
        return out;
      },
      child: child,
    );
  }
}

/// Selettore data Forui (FCalendar in un FDialog). Ritorna la data scelta,
/// oppure null se annullata. FCalendar lavora con DateTime UTC a mezzanotte:
/// la scelta viene riconvertita in DateTime locale.
Future<DateTime?> pickDate(
  BuildContext context, {
  DateTime? initial,
  DateTime? first,
  DateTime? last,
}) {
  final now = DateTime.now();
  final lo = first ?? DateTime(now.year - 12);
  final hi = last ?? DateTime(now.year + 2);
  // Mezzanotte UTC del giorno indicato (NON toUtc(): cambierebbe il giorno
  // nei fusi orari positivi).
  DateTime utcDay(DateTime d) => DateTime.utc(d.year, d.month, d.day);
  final initialUtc = utcDay(initial ?? now);
  final loUtc = utcDay(lo);
  final hiUtc = utcDay(hi);
  final todayUtc = utcDay(now);

  DateTime? toLocal(DateTime utc) => DateTime(utc.year, utc.month, utc.day);

  return showFDialog<DateTime>(
    context: context,
    builder: (context, style, animation) => FDialog(
      style: style,
      animation: animation,
      constraints: const BoxConstraints(minWidth: 320, maxWidth: 420),
      builder: (context, style) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Scegli la data', style: style.titleTextStyle),
            const SizedBox(height: 12),
            FCalendar.grid(
              control: FGridCalendarControl(
                start: loUtc,
                today: todayUtc,
                initial: initialUtc,
                end: hiUtc,
              ),
              selectionControl: FDateSelectionControl.liftedSingle(
                value: initialUtc,
                onChange: (_) {},
              ),
              onDayPress: (d) => Navigator.of(context).pop(toLocal(d)),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(
                  width: 130,
                  child: FButton(
                    size: FButtonSizeVariant.sm,
                    variant: FButtonVariant.ghost,
                    onPress: () => Navigator.of(context).pop(),
                    child: const Text('Annulla'),
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

/// Toast tramite il toaster di forui.
void showToast(BuildContext context, String msg) {
  showFToast(
    context: context,
    title: Text(msg),
    alignment: FToastAlignment.bottomCenter,
    duration: const Duration(seconds: 3),
  );
}

/// Dialogo di conferma (showFDialog di forui). Ritorna true se l'utente conferma.
Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Conferma',
  String cancelLabel = 'Annulla',
  bool destructive = false,
}) async {
  final result = await showFDialog<bool>(
    context: context,
    builder: (context, style, animation) => FDialog(
      style: style,
      animation: animation,
      builder: (context, style) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: style.titleTextStyle),
            const SizedBox(height: 10),
            Text(message, style: style.bodyTextStyle),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: FButton(
                    variant: FButtonVariant.outline,
                    onPress: () => Navigator.of(context).pop(false),
                    child: Text(cancelLabel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FButton(
                    variant: destructive
                        ? FButtonVariant.destructive
                        : FButtonVariant.primary,
                    onPress: () => Navigator.of(context).pop(true),
                    child: Text(confirmLabel),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  return result ?? false;
}

/// Dialogo con un campo di testo (per importazioni ecc.).
Future<String?> promptDialog(
  BuildContext context, {
  required String title,
  String? hint,
  String confirmLabel = 'Conferma',
}) {
  final controller = TextEditingController();
  return showFDialog<String>(
    context: context,
    builder: (context, style, animation) => FDialog(
      style: style,
      animation: animation,
      builder: (context, style) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: style.titleTextStyle),
            const SizedBox(height: 12),
            FTextField(
              control: FTextFieldControl.managed(controller: controller),
              maxLines: 8,
              hint: hint,
              autofocus: true,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: FButton(
                    variant: FButtonVariant.outline,
                    onPress: () => Navigator.of(context).pop(),
                    child: const Text('Annulla'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FButton(
                    onPress: () => Navigator.of(context).pop(controller.text),
                    child: Text(confirmLabel),
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
