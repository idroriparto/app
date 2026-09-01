import '../models/models.dart';
import '../services/riparto_engine.dart';
import '../utils/ids.dart';
import 'store.dart';

/// Condominio di esempio a Milano, con letture e due bollette MM già ripartite.
AppSnapshot buildDemoSnapshot() {
  final condo = Condominio(
    id: newId('cnd'),
    nome: 'Palazzo Solferino',
    indirizzo: 'Via Solferino 14',
    cap: '20121',
    citta: 'Milano',
    provincia: 'MI',
    codiceFiscale: '97880020152',
    amministratore: 'Studio Ferrario Amministrazioni',
    fornitore: 'MM S.p.A.',
    codiceUtenza: '1-2345678-90',
    millesimiRiferimento: 1000,
    metodoDefault: MetodoRiparto.contatori,
    criterioFissa: CriterioQuota.partiUguali,
    criterioComune: CriterioQuota.millesimi,
    note:
        'Stabile di otto unità con sottocontatori di sottrazione e contatore generale MM. '
        'Il giardino condominiale e il lavaggio androne confluiscono nelle parti comuni.',
  );

  UnitaImmobiliare u({
    required String interno,
    required String piano,
    required String proprietario,
    String? occupante,
    required double millesimi,
    required int occupanti,
    bool sfitto = false,
    required String matricola,
    required int ordine,
  }) {
    return UnitaImmobiliare(
      id: newId('un'),
      interno: interno,
      scala: 'A',
      piano: piano,
      proprietario: proprietario,
      occupante: occupante,
      millesimi: millesimi,
      occupanti: occupanti,
      sfitto: sfitto,
      haContatore: true,
      matricola: matricola,
      ordine: ordine,
    );
  }

  final unita = <UnitaImmobiliare>[
    u(
      interno: '1',
      piano: 'T',
      proprietario: 'Bianchi Maria',
      occupante: 'Bianchi Maria',
      millesimi: 138,
      occupanti: 3,
      matricola: 'A-10021',
      ordine: 1,
    ),
    u(
      interno: '2',
      piano: 'T',
      proprietario: 'Rossi Luca',
      occupante: 'Rossi Luca',
      millesimi: 112.50,
      occupanti: 2,
      matricola: 'A-10022',
      ordine: 2,
    ),
    u(
      interno: '3',
      piano: '1',
      proprietario: 'Colombo e Neri S.s.',
      occupante: 'Famiglia Colombo',
      millesimi: 125,
      occupanti: 4,
      matricola: 'A-10023',
      ordine: 3,
    ),
    u(
      interno: '4',
      piano: '1',
      proprietario: 'Ferrari Giulia',
      occupante: 'Ferrari Giulia',
      millesimi: 97.50,
      occupanti: 1,
      matricola: 'A-10024',
      ordine: 4,
    ),
    u(
      interno: '5',
      piano: '2',
      proprietario: 'Esposito Marco',
      occupante: 'Esposito / Ricci',
      millesimi: 152,
      occupanti: 2,
      matricola: 'A-10025',
      ordine: 5,
    ),
    u(
      interno: '6',
      piano: '2',
      proprietario: 'Conti Elena',
      millesimi: 86,
      occupanti: 0,
      sfitto: true,
      matricola: 'A-10026',
      ordine: 6,
    ),
    u(
      interno: '7',
      piano: '3',
      proprietario: 'Greco Andrea',
      occupante: 'Greco Andrea',
      millesimi: 141,
      occupanti: 3,
      matricola: 'A-10027',
      ordine: 7,
    ),
    u(
      interno: '8',
      piano: '3',
      proprietario: 'Moretti Silvia',
      occupante: 'Moretti Silvia',
      millesimi: 148,
      occupanti: 2,
      matricola: 'A-10028',
      ordine: 8,
    ),
  ];

  // Letture assolute (m³) a fine periodo.
  const serie = <String, List<double>>{
    '1': [842.000, 861.200, 879.600],
    '2': [520.000, 532.400, 543.600],
    '3': [1104.000, 1130.800, 1155.400],
    '4': [210.000, 218.500, 226.300],
    '5': [667.000, 683.200, 698.500],
    '6': [445.000, 445.300, 445.700],
    '7': [901.000, 921.400, 940.500],
    '8': [788.000, 805.600, 822.300],
  };
  const generale = [12540.000, 12678.000, 12806.200];
  final date = [
    DateTime(2025, 12, 31),
    DateTime(2026, 3, 31),
    DateTime(2026, 6, 30),
  ];
  final campagne = ['cmp_2025q4', 'cmp_2026q1', 'cmp_2026q2'];

  final letture = <Lettura>[];
  for (var i = 0; i < date.length; i++) {
    letture.add(
      Lettura(
        id: newId('lg'),
        data: date[i],
        valore: generale[i],
        campagnaId: campagne[i],
        note: 'Contatore generale MM',
      ),
    );
    for (final u in unita) {
      letture.add(
        Lettura(
          id: newId('lt'),
          unitaId: u.id,
          data: date[i],
          valore: serie[u.interno]![i],
          campagnaId: campagne[i],
        ),
      );
    }
  }

  Map<String, double> consumo(int from, int to) {
    final m = <String, double>{};
    for (final u in unita) {
      m[u.id] = serie[u.interno]![to] - serie[u.interno]![from];
    }
    return m;
  }

  Map<String, double> vals(int i) {
    final m = <String, double>{};
    for (final u in unita) {
      m[u.id] = serie[u.interno]![i];
    }
    return m;
  }

  Bolletta bill({
    required String numero,
    required DateTime dal,
    required DateTime al,
    required DateTime doc,
    required double fissa,
    required double acq,
    required double fog,
    required double dep,
    required double iva,
    required double mc,
    required int from,
    required int to,
    required StatoBolletta stato,
  }) {
    return Bolletta(
      id: newId('bol'),
      numero: numero,
      dataDocumento: doc,
      periodoDal: dal,
      periodoAl: al,
      fornitore: 'MM S.p.A.',
      quotaFissa: fissa,
      acquedotto: acq,
      fognatura: fog,
      depurazione: dep,
      iva: iva,
      altro: 0,
      mcFatturati: mc,
      letturaGeneralePrec: generale[from],
      letturaGeneraleAtt: generale[to],
      metodo: MetodoRiparto.contatori,
      criterioFissa: CriterioQuota.partiUguali,
      criterioComune: CriterioQuota.millesimi,
      consumi: consumo(from, to),
      letturePrec: vals(from),
      lettureAtt: vals(to),
      stato: stato,
      createdAt: doc,
      note: 'Utenza condominiale · codice 1-2345678-90',
    );
  }

  final b1 = bill(
    numero: 'MM-2026-031188',
    dal: DateTime(2026, 1, 1),
    al: DateTime(2026, 3, 31),
    doc: DateTime(2026, 4, 12),
    fissa: 198.00,
    acq: 286.40,
    fog: 112.80,
    dep: 126.20,
    iva: 72.34,
    mc: 138.0,
    from: 0,
    to: 1,
    stato: StatoBolletta.chiusa,
  );
  final b2 = bill(
    numero: 'MM-2026-074902',
    dal: DateTime(2026, 4, 1),
    al: DateTime(2026, 6, 30),
    doc: DateTime(2026, 7, 15),
    fissa: 192.00,
    acq: 268.40,
    fog: 104.80,
    dep: 118.20,
    iva: 68.34,
    mc: 128.2,
    from: 1,
    to: 2,
    stato: StatoBolletta.calcolata,
  );

  final r1 = RipartoEngine.calcola(
    bolletta: b1,
    unita: unita,
    id: newId('rip'),
    ora: DateTime(2026, 4, 14, 10, 30),
  );
  final r2 = RipartoEngine.calcola(
    bolletta: b2,
    unita: unita,
    id: newId('rip'),
    ora: DateTime(2026, 7, 18, 16, 5),
  );

  return AppSnapshot(
    condominio: condo,
    unita: unita,
    letture: letture,
    bollette: [b1, b2],
    riparti: [r1, r2],
    theme: ThemeChoice.system,
  );
}
