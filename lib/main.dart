import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:forui/forui.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'data/store.dart';
import 'screens/shell.dart';
import 'screens/welcome_screen.dart';
import 'theme/theme.dart';
import 'widgets/widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('it_IT');
  final store = AppStore();
  await store.load();
  runApp(IdroRipartoApp(store: store));
}

class IdroRipartoApp extends StatelessWidget {
  const IdroRipartoApp({super.key, required this.store});
  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return StoreScope(
      store: store,
      child: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final isDark = switch (store.themeMode) {
            ThemeMode.dark => true,
            ThemeMode.light => false,
            ThemeMode.system =>
              WidgetsBinding.instance.platformDispatcher.platformBrightness ==
                  Brightness.dark,
          };
          final fLight = lightTheme;
          final fDark = darkTheme;
          final fTheme = isDark ? fDark : fLight;

          return MaterialApp(
            title: 'IdroRiparto',
            debugShowCheckedModeBanner: false,
            theme: fLight.toApproximateMaterialTheme(),
            darkTheme: fDark.toApproximateMaterialTheme(),
            themeMode: store.themeMode,
            locale: const Locale('it', 'IT'),
            supportedLocales: const [
              Locale('it', 'IT'),
              Locale('en'),
              ...FLocalizations.supportedLocales,
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              ...FLocalizations.localizationsDelegates,
            ],
            builder: (context, child) => FTheme(
              data: fTheme,
              child: FToaster(child: FTooltipGroup(child: child!)),
            ),
            home: !store.ready
                ? const _Boot(key: ValueKey('boot'))
                : store.condominio == null
                ? const WelcomeScreen(key: ValueKey('welcome'))
                : const AppShell(key: ValueKey('shell')),
          );
        },
      ),
    );
  }
}

class _Boot extends StatelessWidget {
  const _Boot({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return ColoredBox(
      color: colors.background,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const LogoMark(size: 88),
            const SizedBox(height: 18),
            Text(
              'IdroRiparto',
              style: context.theme.typography.display.md.copyWith(
                color: colors.foreground,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
