import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import 'icons.dart';

/// Famiglia tipografica unica per tutta l'app.
const kFontFamily = 'NimbusSansL';

/// Blu del marchio IdroRiparto (campionato dal logo).
const kBrandBlue = Color(0xFF2264E2);
const kBrandBlueDark = Color(0xFF6E9BFF);

/// Raggi “small” (scala compatta, stile shadcn “small radius”).
const _smallRadius = FBorderRadius(
  xs2: BorderRadius.all(Radius.circular(2)),
  xs: BorderRadius.all(Radius.circular(3)),
  sm: BorderRadius.all(Radius.circular(4)),
  md: BorderRadius.all(Radius.circular(6)),
  lg: BorderRadius.all(Radius.circular(8)),
  xl: BorderRadius.all(Radius.circular(10)),
  xl2: BorderRadius.all(Radius.circular(12)),
  xl3: BorderRadius.all(Radius.circular(14)),
);

FThemeData _build(FThemeData base, {required Color primary}) {
  // I preset "touch" usano sempre l'interfaccia tattile (mobile/web/desktop
  // in modalità touch), quindi costruiamo i typeface con touch: true.
  const touch = true;
  final colors = base.colors.copyWith(primary: primary);

  final typography = base.typography.copyWith(
    display: FTypeface.inherit(
      colors: colors,
      touch: touch,
      fontFamily: kFontFamily,
    ),
    body: FTypeface.inherit(
      colors: colors,
      touch: touch,
      fontFamily: kFontFamily,
    ),
  );

  final style = base.style.copyWith(borderRadius: _smallRadius);

  return base.copyWith(
    colors: colors,
    typography: typography,
    style: style,
    icons: appIcons(),
  );
}

/// Tema chiaro: base neutra (zinco) con primario blu logo.
FThemeData get lightTheme => _build(
  FTheme.neutral.light.touch,
  primary: kBrandBlue,
);

/// Tema scuro: base zinco scura con primario blu schiarito.
FThemeData get darkTheme => _build(
  FTheme.neutral.dark.touch,
  primary: kBrandBlueDark,
);
