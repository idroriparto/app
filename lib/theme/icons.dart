import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:hugeicons/hugeicons.dart';

/// Adapter that exposes a HugeIcons glyph (SVG based) as an [FIcon].
///
/// HugeIcons draw themselves from a JSON/SVG path structure and do not read
/// the ambient [IconTheme] on their own. As prescribed by Forui's custom-icon
/// contract, we wrap [HugeIcon] in a [Builder] so that the size and color
/// provided by Forui widgets are picked up and applied.
class Hi implements FIcon {
  final List<List<dynamic>> glyph;

  const Hi(this.glyph);

  @override
  Widget call(BuildContext context, {String? semanticsLabel}) => Builder(
    builder: (context) {
      final data = IconTheme.of(context);
      return HugeIcon(
        icon: glyph,
        size: data.size ?? 22,
        color: data.color,
      );
    },
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Hi && glyph == other.glyph;

  @override
  int get hashCode => glyph.hashCode;
}

/// Forui internal icon set (selects, dialogs, sheets, toasts, …) backed by
/// HugeIcons. App-level screens use [Hi] / [HugeIcons] constants directly.
FIcons appIcons() => const FIcons(
  arrowLeft: Hi(HugeIcons.strokeRoundedArrowLeft01),
  calendar: Hi(HugeIcons.strokeRoundedCalendar01),
  check: Hi(HugeIcons.strokeRoundedCheckmarkCircle01),
  chevronDown: Hi(HugeIcons.strokeRoundedArrowDown01),
  chevronLeft: Hi(HugeIcons.strokeRoundedArrowLeft01),
  chevronRight: Hi(HugeIcons.strokeRoundedArrowRight01),
  chevronUp: Hi(HugeIcons.strokeRoundedArrowUp01),
  chevronsUpDown: Hi(HugeIcons.strokeRoundedChevronsDownUp),
  circleAlert: Hi(HugeIcons.strokeRoundedAlertCircle),
  clock4: Hi(HugeIcons.strokeRoundedClock03),
  ellipsis: Hi(HugeIcons.strokeRoundedMoreHorizontal),
  error: Hi(HugeIcons.strokeRoundedAlertCircle),
  eye: Hi(HugeIcons.strokeRoundedView),
  eyeClosed: Hi(HugeIcons.strokeRoundedViewOff),
  gripHorizontal: Hi(HugeIcons.strokeRoundedMenu01),
  gripVertical: Hi(HugeIcons.strokeRoundedMenu01),
  loader: Hi(HugeIcons.strokeRoundedLoading03),
  loaderCircle: Hi(HugeIcons.strokeRoundedLoading02),
  loaderPinwheel: Hi(HugeIcons.strokeRoundedLoading01),
  search: Hi(HugeIcons.strokeRoundedSearch01),
  userRound: Hi(HugeIcons.strokeRoundedUser),
  x: Hi(HugeIcons.strokeRoundedCancel01),
);
