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

  // forui 0.26: `copyWith` non accetta più colors/typography/style/icons.
  // Si costruisce quindi un nuovo FThemeData propagando gli stili del preset.
  return FThemeData(
    debugLabel: base.debugLabel,
    breakpoints: base.breakpoints,
    colors: colors,
    touch: touch,
    typography: typography,
    icons: appIcons(),
    style: style,
    hapticFeedback: base.hapticFeedback,
    accordionStyle: base.accordionStyle,
    autocompleteStyle: base.autocompleteStyle,
    alertStyles: base.alertStyles,
    avatarStyle: base.avatarStyle,
    badgeStyles: base.badgeStyles,
    bottomNavigationBarStyle: base.bottomNavigationBarStyle,
    breadcrumbStyle: base.breadcrumbStyle,
    buttonStyles: base.buttonStyles,
    calendarStyle: base.calendarStyle,
    cardStyle: base.cardStyle,
    checkboxStyle: base.checkboxStyle,
    circularProgressStyles: base.circularProgressStyles,
    dateFieldStyle: base.dateFieldStyle,
    dateTimePickerStyle: base.dateTimePickerStyle,
    determinateProgressStyle: base.determinateProgressStyle,
    dialogRouteStyle: base.dialogRouteStyle,
    dialogStyle: base.dialogStyle,
    dividerStyles: base.dividerStyles,
    headerStyles: base.headerStyles,
    itemStyles: base.itemStyles,
    itemGroupStyle: base.itemGroupStyle,
    labelStyles: base.labelStyles,
    lineCalendarStyle: base.lineCalendarStyle,
    multiSelectStyle: base.multiSelectStyle,
    modalSheetStyle: base.modalSheetStyle,
    otpFieldStyle: base.otpFieldStyle,
    paginationStyle: base.paginationStyle,
    persistentSheetStyle: base.persistentSheetStyle,
    pickerStyle: base.pickerStyle,
    popoverStyle: base.popoverStyle,
    popoverMenuStyle: base.popoverMenuStyle,
    progressStyle: base.progressStyle,
    radioStyle: base.radioStyle,
    resizableStyles: base.resizableStyles,
    scaffoldStyle: base.scaffoldStyle,
    selectStyle: base.selectStyle,
    selectGroupStyle: base.selectGroupStyle,
    selectMenuTileStyle: base.selectMenuTileStyle,
    sidebarStyle: base.sidebarStyle,
    sliderStyles: base.sliderStyles,
    toasterStyle: base.toasterStyle,
    switchStyle: base.switchStyle,
    tabsStyle: base.tabsStyle,
    tappableStyle: base.tappableStyle,
    textFieldStyles: base.textFieldStyles,
    tileStyles: base.tileStyles,
    tileGroupStyle: base.tileGroupStyle,
    timeFieldStyle: base.timeFieldStyle,
    timePickerStyle: base.timePickerStyle,
    tooltipStyle: base.tooltipStyle,
  );
}

/// Tema Material (Flutter) ricavato dai colori Forui, per la `MaterialApp`
/// che ospita l'FTheme (pattern documentato da forui: MaterialApp + FTheme).
///
/// forui 0.26 dipende da `material_ui`, il cui `ThemeData` NON è il `ThemeData`
/// di Flutter: `toApproximateMaterialTheme()` non è quindi più assegnabile a
/// `MaterialApp.theme`. Qui costruiamo un ThemeData Flutter compatibile.
ThemeData materialThemeOf(FThemeData f) {
  final c = f.colors;
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme(
      brightness: c.brightness,
      primary: c.primary,
      onPrimary: c.primaryForeground,
      secondary: c.secondary,
      onSecondary: c.secondaryForeground,
      error: c.error,
      onError: c.errorForeground,
      surface: c.background,
      onSurface: c.foreground,
    ),
    scaffoldBackgroundColor: c.background,
    fontFamily: f.typography.body.fontFamily,
    splashFactory: NoSplash.splashFactory,
  );
}

/// Tema chiaro: base neutra (zinco) con primario blu logo.
FThemeData get lightTheme =>
    _build(FTheme.neutral.light.touch, primary: kBrandBlue);

/// Tema scuro: base zinco scura con primario blu schiarito.
FThemeData get darkTheme =>
    _build(FTheme.neutral.dark.touch, primary: kBrandBlueDark);
