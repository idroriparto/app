import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hugeicons/hugeicons.dart';

import '../data/store.dart';
import '../widgets/widgets.dart';
import 'bollette_screens.dart';
import 'dashboard_screen.dart';
import 'letture_screens.dart';
import 'settings_screen.dart';
import 'unita_screens.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int index = 0;

  static const _dest = [
    (HugeIcons.strokeRoundedHome01, 'Home'),
    (HugeIcons.strokeRoundedBuilding03, 'Unità'),
    (HugeIcons.strokeRoundedDashboardSpeed02, 'Letture'),
    (HugeIcons.strokeRoundedReceiptText, 'Bollette'),
    (HugeIcons.strokeRoundedSettings01, 'Altro'),
  ];

  void _go(int i) {
    if (i == index) return;
    AppMotion.tap();
    setState(() => index = i);
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 980;
    final colors = context.theme.colors;
    const pages = [
      DashboardScreen(),
      UnitaListScreen(),
      LettureScreen(),
      BolletteListScreen(),
      SettingsScreen(),
    ];

    final body = AnimatedSwitcher(
      duration: AppMotion.dEffects,
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeOut,
      transitionBuilder: (child, anim) =>
          FadeTransition(opacity: anim, child: child),
      child: KeyedSubtree(key: ValueKey(index), child: pages[index]),
    );

    if (wide) {
      return Scaffold(
        backgroundColor: colors.background,
        body: Row(
          children: [
            ColoredBox(
              color: colors.card,
              child: SizedBox(
                width: 244,
                child: SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 20, 14, 18),
                        child: Row(
                          children: [
                            const LogoMark(size: 40),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'IdroRiparto',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: context.theme.typography.body.sm
                                        .copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  Text(
                                    StoreScope.of(context).condominio?.nome ??
                                        '',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: context.theme.typography.body.xs
                                        .copyWith(color: colors.mutedForeground),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      for (var i = 0; i < _dest.length; i++)
                        _RailItem(
                          icon: _dest[i].$1,
                          label: _dest[i].$2,
                          selected: index == i,
                          onTap: () => _go(i),
                        ),
                      const Spacer(),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Dati solo su questo dispositivo',
                          style: context.theme.typography.body.xs
                              .copyWith(color: colors.mutedForeground),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(child: body),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: colors.background,
      body: body,
      bottomNavigationBar: ColoredBox(
        color: colors.card,
        child: SafeArea(
          top: false,
          child: FBottomNavigationBar(
            index: index,
            onChange: _go,
            children: [
              for (final d in _dest)
                FBottomNavigationBarItem(
                  icon: HugeIcon(icon: d.$1, size: 22),
                  label: Text(d.$2),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  const _RailItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final Object icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Material(
        color: selected ? colors.muted : Colors.transparent,
        borderRadius: context.theme.style.borderRadius.md,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                HugeIcon(
                  icon: icon as List<List<dynamic>>,
                  size: 22,
                  color: selected ? colors.foreground : colors.mutedForeground,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected
                          ? colors.foreground
                          : colors.mutedForeground,
                    ),
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
