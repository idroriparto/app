import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';
import '../services/riparto_engine.dart';
import '../utils/ids.dart';
import 'demo_data.dart';

const _storageKey = 'idroriparto.snapshot.v1';

class AppSnapshot {
  const AppSnapshot({
    this.condominio,
    this.unita = const [],
    this.letture = const [],
    this.bollette = const [],
    this.riparti = const [],
    this.theme = ThemeChoice.system,
  });

  final Condominio? condominio;
  final List<UnitaImmobiliare> unita;
  final List<Lettura> letture;
  final List<Bolletta> bollette;
  final List<RisultatoRiparto> riparti;
  final ThemeChoice theme;

  Map<String, dynamic> toJson() => {
    'condominio': condominio?.toJson(),
    'unita': unita.map((e) => e.toJson()).toList(),
    'letture': letture.map((e) => e.toJson()).toList(),
    'bollette': bollette.map((e) => e.toJson()).toList(),
    'riparti': riparti.map((e) => e.toJson()).toList(),
    'theme': theme.name,
  };

  factory AppSnapshot.fromJson(Map<String, dynamic> j) => AppSnapshot(
    condominio: j['condominio'] == null
        ? null
        : Condominio.fromJson(
            Map<String, dynamic>.from(j['condominio'] as Map),
          ),
    unita: (j['unita'] as List? ?? [])
        .map(
          (e) => UnitaImmobiliare.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList(),
    letture: (j['letture'] as List? ?? [])
        .map((e) => Lettura.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
    bollette: (j['bollette'] as List? ?? [])
        .map((e) => Bolletta.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
    riparti: (j['riparti'] as List? ?? [])
        .map(
          (e) => RisultatoRiparto.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList(),
    theme: ThemeChoice.values.firstWhere(
      (e) => e.name == j['theme'],
      orElse: () => ThemeChoice.system,
    ),
  );

  String toPrettyJson() => const JsonEncoder.withIndent('  ').convert(toJson());
}

class AppStore extends ChangeNotifier {
  AppSnapshot _data = const AppSnapshot();
  bool ready = false;

  Condominio? get condominio => _data.condominio;
  List<UnitaImmobiliare> get unita {
    final list = [..._data.unita];
    list.sort((a, b) {
      final o = a.ordine.compareTo(b.ordine);
      if (o != 0) return o;
      return a.interno.compareTo(b.interno);
    });
    return list;
  }

  List<Lettura> get letture {
    final list = [..._data.letture];
    list.sort((a, b) => b.data.compareTo(a.data));
    return list;
  }

  List<Bolletta> get bollette {
    final list = [..._data.bollette];
    list.sort((a, b) => b.periodoAl.compareTo(a.periodoAl));
    return list;
  }

  List<RisultatoRiparto> get riparti => List.unmodifiable(_data.riparti);
  ThemeChoice get themeChoice => _data.theme;

  ThemeMode get themeMode => switch (_data.theme) {
    ThemeChoice.system => ThemeMode.system,
    ThemeChoice.light => ThemeMode.light,
    ThemeChoice.dark => ThemeMode.dark,
  };

  double get sommaMillesimi =>
      _data.unita.fold<double>(0, (a, u) => a + u.millesimi);

  int get occupantiTotali =>
      _data.unita.fold<int>(0, (a, u) => a + (u.sfitto ? 0 : u.occupanti));

  Bolletta? get ultimaBolletta => bollette.isEmpty ? null : bollette.first;

  RisultatoRiparto? ripartoDi(String bollettaId) {
    final matches = _data.riparti.where((r) => r.bollettaId == bollettaId);
    if (matches.isEmpty) return null;
    return matches.reduce(
      (a, b) => a.calcolatoIl.isAfter(b.calcolatoIl) ? a : b,
    );
  }

  UnitaImmobiliare? unitaById(String? id) {
    if (id == null || id.isEmpty) return null;
    for (final u in _data.unita) {
      if (u.id == id) return u;
    }
    return null;
  }

  List<Lettura> lettureDi(String unitaId) {
    final list = _data.letture.where((l) => l.unitaId == unitaId).toList()
      ..sort((a, b) => a.data.compareTo(b.data));
    return list;
  }

  Lettura? ultimaLetturaDi(String? unitaId, {DateTime? entro}) {
    final list = _data.letture.where((l) {
      final same = unitaId == null || unitaId.isEmpty
          ? l.isGenerale
          : l.unitaId == unitaId;
      if (!same) return false;
      if (entro != null && l.data.isAfter(entro)) return false;
      return true;
    }).toList()..sort((a, b) => a.data.compareTo(b.data));
    return list.isEmpty ? null : list.last;
  }

  ConsumoUnita consumoNelPeriodo(String unitaId, DateTime dal, DateTime al) {
    final serie = lettureDi(unitaId);
    Lettura? att;
    for (final l in serie) {
      if (!l.data.isAfter(al)) att = l;
    }
    Lettura? prec;
    if (att != null) {
      for (final l in serie) {
        if (l.id == att.id) break;
        if (!l.data.isAfter(dal)) prec = l;
      }
      prec ??= () {
        Lettura? p;
        for (final l in serie) {
          if (l.id == att!.id) break;
          p = l;
        }
        return p;
      }();
    }
    final consumo = (att != null && prec != null)
        ? (att.valore - prec.valore)
        : 0.0;
    return ConsumoUnita(
      unitaId: unitaId,
      letturaPrec: prec?.valore,
      letturaAtt: att?.valore,
      consumo: consumo < 0 ? 0 : consumo,
      dataPrec: prec?.data,
      dataAtt: att?.data,
    );
  }

  Map<String, ConsumoUnita> consumiPeriodo(DateTime dal, DateTime al) {
    final m = <String, ConsumoUnita>{};
    for (final u in unita) {
      m[u.id] = consumoNelPeriodo(u.id, dal, al);
    }
    return m;
  }

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        _data = AppSnapshot.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('IdroRiparto load error: $e');
    }
    ready = true;
    notifyListeners();
  }

  Future<void> _commit() async {
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(_data.toJson()));
    } catch (e) {
      debugPrint('IdroRiparto save error: $e');
    }
  }

  Future<void> loadDemo() async {
    _data = buildDemoSnapshot();
    await _commit();
  }

  Future<void> resetAll() async {
    _data = AppSnapshot(theme: _data.theme);
    await _commit();
  }

  Future<void> importSnapshot(AppSnapshot snap) async {
    _data = snap;
    await _commit();
  }

  Future<void> setTheme(ThemeChoice c) async {
    _data = AppSnapshot(
      condominio: _data.condominio,
      unita: _data.unita,
      letture: _data.letture,
      bollette: _data.bollette,
      riparti: _data.riparti,
      theme: c,
    );
    await _commit();
  }

  Future<void> saveCondominio(Condominio c) async {
    _data = AppSnapshot(
      condominio: c,
      unita: _data.unita,
      letture: _data.letture,
      bollette: _data.bollette,
      riparti: _data.riparti,
      theme: _data.theme,
    );
    await _commit();
  }

  Future<void> upsertUnita(UnitaImmobiliare u) async {
    final list = [..._data.unita];
    final i = list.indexWhere((e) => e.id == u.id);
    if (i >= 0) {
      list[i] = u;
    } else {
      list.add(u);
    }
    _data = AppSnapshot(
      condominio: _data.condominio,
      unita: list,
      letture: _data.letture,
      bollette: _data.bollette,
      riparti: _data.riparti,
      theme: _data.theme,
    );
    await _commit();
  }

  Future<void> deleteUnita(String id) async {
    _data = AppSnapshot(
      condominio: _data.condominio,
      unita: _data.unita.where((e) => e.id != id).toList(),
      letture: _data.letture.where((e) => e.unitaId != id).toList(),
      bollette: _data.bollette,
      riparti: _data.riparti,
      theme: _data.theme,
    );
    await _commit();
  }

  Future<void> upsertLettura(Lettura l) async {
    final list = [..._data.letture];
    final i = list.indexWhere((e) => e.id == l.id);
    if (i >= 0) {
      list[i] = l;
    } else {
      list.add(l);
    }
    _data = AppSnapshot(
      condominio: _data.condominio,
      unita: _data.unita,
      letture: list,
      bollette: _data.bollette,
      riparti: _data.riparti,
      theme: _data.theme,
    );
    await _commit();
  }

  Future<void> deleteLettura(String id) async {
    _data = AppSnapshot(
      condominio: _data.condominio,
      unita: _data.unita,
      letture: _data.letture.where((e) => e.id != id).toList(),
      bollette: _data.bollette,
      riparti: _data.riparti,
      theme: _data.theme,
    );
    await _commit();
  }

  Future<void> salvaCampagnaLetture({
    required DateTime data,
    required Map<String, double> valori,
    double? generale,
    String? note,
  }) async {
    final campagna = newId('cmp');
    final list = [..._data.letture];
    void put(String? unitaId, double valore, String? n) {
      final existing = list.indexWhere(
        (e) =>
            e.campagnaId != null &&
            _sameDay(e.data, data) &&
            ((unitaId == null && e.isGenerale) || e.unitaId == unitaId),
      );
      final item = Lettura(
        id: existing >= 0 ? list[existing].id : newId('lt'),
        unitaId: unitaId,
        data: data,
        valore: valore,
        note: n,
        campagnaId: campagna,
      );
      if (existing >= 0) {
        list[existing] = item;
      } else {
        list.add(item);
      }
    }

    for (final e in valori.entries) {
      put(e.key, e.value, note);
    }
    if (generale != null) {
      put(null, generale, note ?? 'Contatore generale');
    }
    _data = AppSnapshot(
      condominio: _data.condominio,
      unita: _data.unita,
      letture: list,
      bollette: _data.bollette,
      riparti: _data.riparti,
      theme: _data.theme,
    );
    await _commit();
  }

  Future<void> upsertBolletta(Bolletta b) async {
    final list = [..._data.bollette];
    final i = list.indexWhere((e) => e.id == b.id);
    if (i >= 0) {
      list[i] = b;
    } else {
      list.add(b);
    }
    _data = AppSnapshot(
      condominio: _data.condominio,
      unita: _data.unita,
      letture: _data.letture,
      bollette: list,
      riparti: _data.riparti,
      theme: _data.theme,
    );
    await _commit();
  }

  Future<void> deleteBolletta(String id) async {
    _data = AppSnapshot(
      condominio: _data.condominio,
      unita: _data.unita,
      letture: _data.letture,
      bollette: _data.bollette.where((e) => e.id != id).toList(),
      riparti: _data.riparti.where((e) => e.bollettaId != id).toList(),
      theme: _data.theme,
    );
    await _commit();
  }

  Future<RisultatoRiparto> calcolaESalva(
    Bolletta bolletta, {
    Map<String, double>? consumi,
  }) async {
    final r = RipartoEngine.calcola(
      bolletta: bolletta,
      unita: unita,
      consumiOverride: consumi,
    );
    final b = bolletta.copyWith(
      consumi: consumi ?? bolletta.consumi,
      stato: bolletta.stato == StatoBolletta.chiusa
          ? StatoBolletta.chiusa
          : StatoBolletta.calcolata,
    );
    final bills = [..._data.bollette];
    final i = bills.indexWhere((e) => e.id == b.id);
    if (i >= 0) {
      bills[i] = b;
    } else {
      bills.add(b);
    }
    final rs = _data.riparti.where((e) => e.bollettaId != b.id).toList()
      ..add(r);
    _data = AppSnapshot(
      condominio: _data.condominio,
      unita: _data.unita,
      letture: _data.letture,
      bollette: bills,
      riparti: rs,
      theme: _data.theme,
    );
    await _commit();
    return r;
  }

  Future<void> chiudiBolletta(String id) async {
    final list = _data.bollette.map((b) {
      if (b.id == id) return b.copyWith(stato: StatoBolletta.chiusa);
      return b;
    }).toList();
    _data = AppSnapshot(
      condominio: _data.condominio,
      unita: _data.unita,
      letture: _data.letture,
      bollette: list,
      riparti: _data.riparti,
      theme: _data.theme,
    );
    await _commit();
  }
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

class StoreScope extends InheritedNotifier<AppStore> {
  const StoreScope({super.key, required AppStore store, required super.child})
    : super(notifier: store);

  static AppStore of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<StoreScope>();
    assert(scope != null, 'StoreScope non trovato');
    return scope!.notifier!;
  }

  static AppStore read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<StoreScope>();
    assert(scope != null, 'StoreScope non trovato');
    return scope!.notifier!;
  }
}
