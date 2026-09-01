enum MetodoRiparto { contatori, millesimi, consumo, teste, misto }

enum CriterioQuota { millesimi, partiUguali, teste }

enum StatoBolletta { bozza, calcolata, chiusa }

enum ThemeChoice { system, light, dark }

extension MetodoRipartoX on MetodoRiparto {
  String get label => switch (this) {
    MetodoRiparto.contatori => 'Contatori',
    MetodoRiparto.millesimi => 'Millesimi',
    MetodoRiparto.consumo => 'Consumo',
    MetodoRiparto.teste => 'Occupanti',
    MetodoRiparto.misto => 'Misto',
  };

  String get titolo => switch (this) {
    MetodoRiparto.contatori => 'Contatori individuali',
    MetodoRiparto.millesimi => 'Solo millesimi',
    MetodoRiparto.consumo => 'Solo consumo (m³)',
    MetodoRiparto.teste => 'Per numero di occupanti',
    MetodoRiparto.misto => 'Misto: quota fissa + consumo',
  };

  String get descrizione => switch (this) {
    MetodoRiparto.contatori =>
      'Criterio consigliato quando ogni unità ha il contatore: il consumo effettivo '
          'si addebita a ciascuna unità in base al proprio contatore; la differenza tra '
          'il contatore generale (consumo fatturato) e la somma dei contatori individuali '
          '— parti comuni e perdite — si ripartisce a millesimi. La quota fissa si divide '
          'in parti uguali.',
    MetodoRiparto.millesimi =>
      'Tutta la bolletta si divide in base ai millesimi di proprietà. È il criterio residuale dell’art. 1123 c.c. quando non ci sono contatori individuali.',
    MetodoRiparto.consumo =>
      'Tutta la spesa segue i metri cubi rilevati dai sottocontatori. Chi non consuma non paga (utile solo se tutte le unità hanno contatore).',
    MetodoRiparto.teste =>
      'Si divide in proporzione alle persone che abitano ciascuna unità. Va deliberato in assemblea e aggiornato quando cambia il nucleo.',
    MetodoRiparto.misto =>
      'Le quote fisse (canone, nolo contatore) si ripartiscono per millesimi, parti uguali o occupanti. I consumi vanno a m³. Le perdite e le parti comuni si spalmano a parte.',
  };
}

extension CriterioQuotaX on CriterioQuota {
  String get label => switch (this) {
    CriterioQuota.millesimi => 'Millesimi',
    CriterioQuota.partiUguali => 'Parti uguali',
    CriterioQuota.teste => 'Occupanti',
  };
}

extension StatoBollettaX on StatoBolletta {
  String get label => switch (this) {
    StatoBolletta.bozza => 'Bozza',
    StatoBolletta.calcolata => 'Calcolata',
    StatoBolletta.chiusa => 'Chiusa',
  };
}

double asDouble(dynamic v, [double fallback = 0]) {
  if (v == null) return fallback;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString().replaceAll(',', '.')) ?? fallback;
}

int asInt(dynamic v, [int fallback = 0]) {
  if (v == null) return fallback;
  if (v is int) return v;
  if (v is num) return v.round();
  return int.tryParse(v.toString()) ?? fallback;
}

DateTime asDate(dynamic v) {
  if (v is DateTime) return v;
  if (v is String && v.isNotEmpty) {
    return DateTime.tryParse(v) ?? DateTime.now();
  }
  return DateTime.now();
}

class Condominio {
  const Condominio({
    required this.id,
    required this.nome,
    this.indirizzo = '',
    this.cap = '',
    this.citta = '',
    this.provincia = '',
    this.codiceFiscale,
    this.amministratore = '',
    this.fornitore = '',
    this.codiceUtenza,
    this.millesimiRiferimento = 1000,
    this.metodoDefault = MetodoRiparto.contatori,
    this.criterioFissa = CriterioQuota.partiUguali,
    this.criterioComune = CriterioQuota.millesimi,
    this.note = '',
  });

  final String id;
  final String nome;
  final String indirizzo;
  final String cap;
  final String citta;
  final String provincia;
  final String? codiceFiscale;
  final String amministratore;
  final String fornitore;
  final String? codiceUtenza;
  final double millesimiRiferimento;
  final MetodoRiparto metodoDefault;
  final CriterioQuota criterioFissa;
  final CriterioQuota criterioComune;
  final String note;

  String get cittaRiga {
    final bits = [
      if (cap.isNotEmpty) cap,
      if (citta.isNotEmpty) citta,
      if (provincia.isNotEmpty) '($provincia)',
    ];
    return bits.join(' ');
  }

  String get indirizzoCompleto {
    final a = [
      if (indirizzo.isNotEmpty) indirizzo,
      if (cittaRiga.isNotEmpty) cittaRiga,
    ];
    return a.join(', ');
  }

  Condominio copyWith({
    String? nome,
    String? indirizzo,
    String? cap,
    String? citta,
    String? provincia,
    String? codiceFiscale,
    String? amministratore,
    String? fornitore,
    String? codiceUtenza,
    double? millesimiRiferimento,
    MetodoRiparto? metodoDefault,
    CriterioQuota? criterioFissa,
    CriterioQuota? criterioComune,
    String? note,
  }) {
    return Condominio(
      id: id,
      nome: nome ?? this.nome,
      indirizzo: indirizzo ?? this.indirizzo,
      cap: cap ?? this.cap,
      citta: citta ?? this.citta,
      provincia: provincia ?? this.provincia,
      codiceFiscale: codiceFiscale ?? this.codiceFiscale,
      amministratore: amministratore ?? this.amministratore,
      fornitore: fornitore ?? this.fornitore,
      codiceUtenza: codiceUtenza ?? this.codiceUtenza,
      millesimiRiferimento:
          millesimiRiferimento ?? this.millesimiRiferimento,
      metodoDefault: metodoDefault ?? this.metodoDefault,
      criterioFissa: criterioFissa ?? this.criterioFissa,
      criterioComune: criterioComune ?? this.criterioComune,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nome': nome,
    'indirizzo': indirizzo,
    'cap': cap,
    'citta': citta,
    'provincia': provincia,
    'codiceFiscale': codiceFiscale,
    'amministratore': amministratore,
    'fornitore': fornitore,
    'codiceUtenza': codiceUtenza,
    'millesimiRiferimento': millesimiRiferimento,
    'metodoDefault': metodoDefault.name,
    'criterioFissa': criterioFissa.name,
    'criterioComune': criterioComune.name,
    'note': note,
  };

  factory Condominio.fromJson(Map<String, dynamic> j) => Condominio(
    id: j['id'] as String,
    nome: j['nome'] as String? ?? '',
    indirizzo: j['indirizzo'] as String? ?? '',
    cap: j['cap'] as String? ?? '',
    citta: j['citta'] as String? ?? '',
    provincia: j['provincia'] as String? ?? '',
    codiceFiscale: j['codiceFiscale'] as String?,
    amministratore: j['amministratore'] as String? ?? '',
    fornitore: j['fornitore'] as String? ?? '',
    codiceUtenza: j['codiceUtenza'] as String?,
    millesimiRiferimento: asDouble(j['millesimiRiferimento'], 1000),
    metodoDefault: MetodoRiparto.values.firstWhere(
      (e) => e.name == j['metodoDefault'],
      orElse: () => MetodoRiparto.contatori,
    ),
    criterioFissa: CriterioQuota.values.firstWhere(
      (e) => e.name == j['criterioFissa'],
      orElse: () => CriterioQuota.partiUguali,
    ),
    criterioComune: CriterioQuota.values.firstWhere(
      (e) => e.name == j['criterioComune'],
      orElse: () => CriterioQuota.millesimi,
    ),
    note: j['note'] as String? ?? '',
  );
}

class UnitaImmobiliare {
  const UnitaImmobiliare({
    required this.id,
    required this.interno,
    this.scala = '',
    this.piano = '',
    required this.proprietario,
    this.occupante,
    this.email,
    this.telefono,
    required this.millesimi,
    this.occupanti = 1,
    this.sfitto = false,
    this.haContatore = true,
    this.matricola,
    this.note = '',
    this.ordine = 0,
  });

  final String id;
  final String interno;
  final String scala;
  final String piano;
  final String proprietario;
  final String? occupante;
  final String? email;
  final String? telefono;
  final double millesimi;
  final int occupanti;
  final bool sfitto;
  final bool haContatore;
  final String? matricola;
  final String note;
  final int ordine;

  String get titolo =>
      scala.isEmpty ? 'Interno $interno' : 'Scala $scala · int. $interno';

  String get intestatario =>
      (occupante != null && occupante!.trim().isNotEmpty)
      ? occupante!.trim()
      : proprietario;

  String get sottoTitolo {
    final bits = <String>[
      proprietario,
      if (piano.isNotEmpty) 'piano $piano',
      if (sfitto) 'sfitto',
    ];
    return bits.join(' · ');
  }

  UnitaImmobiliare copyWith({
    String? interno,
    String? scala,
    String? piano,
    String? proprietario,
    String? occupante,
    String? email,
    String? telefono,
    double? millesimi,
    int? occupanti,
    bool? sfitto,
    bool? haContatore,
    String? matricola,
    String? note,
    int? ordine,
  }) {
    return UnitaImmobiliare(
      id: id,
      interno: interno ?? this.interno,
      scala: scala ?? this.scala,
      piano: piano ?? this.piano,
      proprietario: proprietario ?? this.proprietario,
      occupante: occupante ?? this.occupante,
      email: email ?? this.email,
      telefono: telefono ?? this.telefono,
      millesimi: millesimi ?? this.millesimi,
      occupanti: occupanti ?? this.occupanti,
      sfitto: sfitto ?? this.sfitto,
      haContatore: haContatore ?? this.haContatore,
      matricola: matricola ?? this.matricola,
      note: note ?? this.note,
      ordine: ordine ?? this.ordine,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'interno': interno,
    'scala': scala,
    'piano': piano,
    'proprietario': proprietario,
    'occupante': occupante,
    'email': email,
    'telefono': telefono,
    'millesimi': millesimi,
    'occupanti': occupanti,
    'sfitto': sfitto,
    'haContatore': haContatore,
    'matricola': matricola,
    'note': note,
    'ordine': ordine,
  };

  factory UnitaImmobiliare.fromJson(Map<String, dynamic> j) =>
      UnitaImmobiliare(
        id: j['id'] as String,
        interno: j['interno'] as String? ?? '',
        scala: j['scala'] as String? ?? '',
        piano: j['piano'] as String? ?? '',
        proprietario: j['proprietario'] as String? ?? '',
        occupante: j['occupante'] as String?,
        email: j['email'] as String?,
        telefono: j['telefono'] as String?,
        millesimi: asDouble(j['millesimi']),
        occupanti: asInt(j['occupanti'], 1),
        sfitto: j['sfitto'] == true,
        haContatore: j['haContatore'] != false,
        matricola: j['matricola'] as String?,
        note: j['note'] as String? ?? '',
        ordine: asInt(j['ordine']),
      );
}

class Lettura {
  const Lettura({
    required this.id,
    this.unitaId,
    required this.data,
    required this.valore,
    this.note,
    this.campagnaId,
  });

  final String id;
  final String? unitaId;
  final DateTime data;
  final double valore;
  final String? note;
  final String? campagnaId;

  bool get isGenerale => unitaId == null || unitaId!.isEmpty;

  Lettura copyWith({
    DateTime? data,
    double? valore,
    String? note,
    String? campagnaId,
    String? unitaId,
  }) {
    return Lettura(
      id: id,
      unitaId: unitaId ?? this.unitaId,
      data: data ?? this.data,
      valore: valore ?? this.valore,
      note: note ?? this.note,
      campagnaId: campagnaId ?? this.campagnaId,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'unitaId': unitaId,
    'data': data.toIso8601String(),
    'valore': valore,
    'note': note,
    'campagnaId': campagnaId,
  };

  factory Lettura.fromJson(Map<String, dynamic> j) => Lettura(
    id: j['id'] as String,
    unitaId: j['unitaId'] as String?,
    data: asDate(j['data']),
    valore: asDouble(j['valore']),
    note: j['note'] as String?,
    campagnaId: j['campagnaId'] as String?,
  );
}

class Bolletta {
  const Bolletta({
    required this.id,
    this.numero = '',
    required this.dataDocumento,
    required this.periodoDal,
    required this.periodoAl,
    this.fornitore = '',
    this.quotaFissa = 0,
    this.acquedotto = 0,
    this.fognatura = 0,
    this.depurazione = 0,
    this.iva = 0,
    this.altro = 0,
    this.mcFatturati = 0,
    this.letturaGeneralePrec,
    this.letturaGeneraleAtt,
    this.metodo = MetodoRiparto.contatori,
    this.criterioFissa = CriterioQuota.partiUguali,
    this.criterioComune = CriterioQuota.millesimi,
    this.consumi = const {},
    this.letturePrec = const {},
    this.lettureAtt = const {},
    this.stato = StatoBolletta.bozza,
    required this.createdAt,
    this.note = '',
  });

  final String id;
  final String numero;
  final DateTime dataDocumento;
  final DateTime periodoDal;
  final DateTime periodoAl;
  final String fornitore;
  final double quotaFissa;
  final double acquedotto;
  final double fognatura;
  final double depurazione;
  final double iva;
  final double altro;
  final double mcFatturati;
  final double? letturaGeneralePrec;
  final double? letturaGeneraleAtt;
  final MetodoRiparto metodo;
  final CriterioQuota criterioFissa;
  final CriterioQuota criterioComune;
  final Map<String, double> consumi;
  final Map<String, double> letturePrec;
  final Map<String, double> lettureAtt;
  final StatoBolletta stato;
  final DateTime createdAt;
  final String note;

  double get variabile => acquedotto + fognatura + depurazione;
  double get extra => iva + altro;
  double get totale => quotaFissa + variabile + extra;

  double get mcGenerale {
    if (letturaGeneraleAtt != null && letturaGeneralePrec != null) {
      return (letturaGeneraleAtt! - letturaGeneralePrec!).clamp(0, 1e12);
    }
    return mcFatturati;
  }

  Bolletta copyWith({
    String? numero,
    DateTime? dataDocumento,
    DateTime? periodoDal,
    DateTime? periodoAl,
    String? fornitore,
    double? quotaFissa,
    double? acquedotto,
    double? fognatura,
    double? depurazione,
    double? iva,
    double? altro,
    double? mcFatturati,
    double? letturaGeneralePrec,
    double? letturaGeneraleAtt,
    bool clearGeneralePrec = false,
    bool clearGeneraleAtt = false,
    MetodoRiparto? metodo,
    CriterioQuota? criterioFissa,
    CriterioQuota? criterioComune,
    Map<String, double>? consumi,
    Map<String, double>? letturePrec,
    Map<String, double>? lettureAtt,
    StatoBolletta? stato,
    String? note,
  }) {
    return Bolletta(
      id: id,
      numero: numero ?? this.numero,
      dataDocumento: dataDocumento ?? this.dataDocumento,
      periodoDal: periodoDal ?? this.periodoDal,
      periodoAl: periodoAl ?? this.periodoAl,
      fornitore: fornitore ?? this.fornitore,
      quotaFissa: quotaFissa ?? this.quotaFissa,
      acquedotto: acquedotto ?? this.acquedotto,
      fognatura: fognatura ?? this.fognatura,
      depurazione: depurazione ?? this.depurazione,
      iva: iva ?? this.iva,
      altro: altro ?? this.altro,
      mcFatturati: mcFatturati ?? this.mcFatturati,
      letturaGeneralePrec: clearGeneralePrec
          ? null
          : (letturaGeneralePrec ?? this.letturaGeneralePrec),
      letturaGeneraleAtt: clearGeneraleAtt
          ? null
          : (letturaGeneraleAtt ?? this.letturaGeneraleAtt),
      metodo: metodo ?? this.metodo,
      criterioFissa: criterioFissa ?? this.criterioFissa,
      criterioComune: criterioComune ?? this.criterioComune,
      consumi: consumi ?? this.consumi,
      letturePrec: letturePrec ?? this.letturePrec,
      lettureAtt: lettureAtt ?? this.lettureAtt,
      stato: stato ?? this.stato,
      createdAt: createdAt,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'numero': numero,
    'dataDocumento': dataDocumento.toIso8601String(),
    'periodoDal': periodoDal.toIso8601String(),
    'periodoAl': periodoAl.toIso8601String(),
    'fornitore': fornitore,
    'quotaFissa': quotaFissa,
    'acquedotto': acquedotto,
    'fognatura': fognatura,
    'depurazione': depurazione,
    'iva': iva,
    'altro': altro,
    'mcFatturati': mcFatturati,
    'letturaGeneralePrec': letturaGeneralePrec,
    'letturaGeneraleAtt': letturaGeneraleAtt,
    'metodo': metodo.name,
    'criterioFissa': criterioFissa.name,
    'criterioComune': criterioComune.name,
    'consumi': consumi,
    'letturePrec': letturePrec,
    'lettureAtt': lettureAtt,
    'stato': stato.name,
    'createdAt': createdAt.toIso8601String(),
    'note': note,
  };

  factory Bolletta.fromJson(Map<String, dynamic> j) => Bolletta(
    id: j['id'] as String,
    numero: j['numero'] as String? ?? '',
    dataDocumento: asDate(j['dataDocumento']),
    periodoDal: asDate(j['periodoDal']),
    periodoAl: asDate(j['periodoAl']),
    fornitore: j['fornitore'] as String? ?? '',
    quotaFissa: asDouble(j['quotaFissa']),
    acquedotto: asDouble(j['acquedotto']),
    fognatura: asDouble(j['fognatura']),
    depurazione: asDouble(j['depurazione']),
    iva: asDouble(j['iva']),
    altro: asDouble(j['altro']),
    mcFatturati: asDouble(j['mcFatturati']),
    letturaGeneralePrec: j['letturaGeneralePrec'] == null
        ? null
        : asDouble(j['letturaGeneralePrec']),
    letturaGeneraleAtt: j['letturaGeneraleAtt'] == null
        ? null
        : asDouble(j['letturaGeneraleAtt']),
    metodo: MetodoRiparto.values.firstWhere(
      (e) => e.name == j['metodo'],
      orElse: () => MetodoRiparto.contatori,
    ),
    criterioFissa: CriterioQuota.values.firstWhere(
      (e) => e.name == j['criterioFissa'],
      orElse: () => CriterioQuota.partiUguali,
    ),
    criterioComune: CriterioQuota.values.firstWhere(
      (e) => e.name == j['criterioComune'],
      orElse: () => CriterioQuota.millesimi,
    ),
    consumi: _mapDouble(j['consumi']),
    letturePrec: _mapDouble(j['letturePrec']),
    lettureAtt: _mapDouble(j['lettureAtt']),
    stato: StatoBolletta.values.firstWhere(
      (e) => e.name == j['stato'],
      orElse: () => StatoBolletta.bozza,
    ),
    createdAt: asDate(j['createdAt']),
    note: j['note'] as String? ?? '',
  );
}

Map<String, double> _mapDouble(dynamic raw) {
  if (raw is Map) {
    return raw.map((k, v) => MapEntry(k.toString(), asDouble(v)));
  }
  return {};
}

class RigaRiparto {
  const RigaRiparto({
    required this.unitaId,
    required this.interno,
    required this.proprietario,
    required this.millesimi,
    required this.occupanti,
    required this.sfitto,
    required this.consumoMc,
    required this.quotaFissa,
    required this.quotaConsumo,
    required this.quotaComune,
    required this.quotaExtra,
    required this.totale,
    required this.percentuale,
  });

  final String unitaId;
  final String interno;
  final String proprietario;
  final double millesimi;
  final int occupanti;
  final bool sfitto;
  final double consumoMc;
  final double quotaFissa;
  final double quotaConsumo;
  final double quotaComune;
  final double quotaExtra;
  final double totale;
  final double percentuale;

  Map<String, dynamic> toJson() => {
    'unitaId': unitaId,
    'interno': interno,
    'proprietario': proprietario,
    'millesimi': millesimi,
    'occupanti': occupanti,
    'sfitto': sfitto,
    'consumoMc': consumoMc,
    'quotaFissa': quotaFissa,
    'quotaConsumo': quotaConsumo,
    'quotaComune': quotaComune,
    'quotaExtra': quotaExtra,
    'totale': totale,
    'percentuale': percentuale,
  };

  factory RigaRiparto.fromJson(Map<String, dynamic> j) => RigaRiparto(
    unitaId: j['unitaId'] as String,
    interno: j['interno'] as String? ?? '',
    proprietario: j['proprietario'] as String? ?? '',
    millesimi: asDouble(j['millesimi']),
    occupanti: asInt(j['occupanti']),
    sfitto: j['sfitto'] == true,
    consumoMc: asDouble(j['consumoMc']),
    quotaFissa: asDouble(j['quotaFissa']),
    quotaConsumo: asDouble(j['quotaConsumo']),
    quotaComune: asDouble(j['quotaComune']),
    quotaExtra: asDouble(j['quotaExtra']),
    totale: asDouble(j['totale']),
    percentuale: asDouble(j['percentuale']),
  );
}

class RisultatoRiparto {
  const RisultatoRiparto({
    required this.id,
    required this.bollettaId,
    required this.calcolatoIl,
    required this.righe,
    required this.sommaConsumi,
    required this.consumoComune,
    required this.mcRiferimento,
    required this.prezzoMedioMc,
    required this.totaleFisso,
    required this.totaleConsumo,
    required this.totaleComune,
    required this.totaleExtra,
    required this.totaleGenerale,
    required this.metodo,
    required this.criterioFissa,
    required this.criterioComune,
    this.avvisi = const [],
    this.noteCalcolo = '',
  });

  final String id;
  final String bollettaId;
  final DateTime calcolatoIl;
  final List<RigaRiparto> righe;
  final double sommaConsumi;
  final double consumoComune;
  final double mcRiferimento;
  final double prezzoMedioMc;
  final double totaleFisso;
  final double totaleConsumo;
  final double totaleComune;
  final double totaleExtra;
  final double totaleGenerale;
  final MetodoRiparto metodo;
  final CriterioQuota criterioFissa;
  final CriterioQuota criterioComune;
  final List<String> avvisi;
  final String noteCalcolo;

  Map<String, dynamic> toJson() => {
    'id': id,
    'bollettaId': bollettaId,
    'calcolatoIl': calcolatoIl.toIso8601String(),
    'righe': righe.map((e) => e.toJson()).toList(),
    'sommaConsumi': sommaConsumi,
    'consumoComune': consumoComune,
    'mcRiferimento': mcRiferimento,
    'prezzoMedioMc': prezzoMedioMc,
    'totaleFisso': totaleFisso,
    'totaleConsumo': totaleConsumo,
    'totaleComune': totaleComune,
    'totaleExtra': totaleExtra,
    'totaleGenerale': totaleGenerale,
    'metodo': metodo.name,
    'criterioFissa': criterioFissa.name,
    'criterioComune': criterioComune.name,
    'avvisi': avvisi,
    'noteCalcolo': noteCalcolo,
  };

  factory RisultatoRiparto.fromJson(Map<String, dynamic> j) => RisultatoRiparto(
    id: j['id'] as String,
    bollettaId: j['bollettaId'] as String,
    calcolatoIl: asDate(j['calcolatoIl']),
    righe: (j['righe'] as List? ?? [])
        .map((e) => RigaRiparto.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
    sommaConsumi: asDouble(j['sommaConsumi']),
    consumoComune: asDouble(j['consumoComune']),
    mcRiferimento: asDouble(j['mcRiferimento']),
    prezzoMedioMc: asDouble(j['prezzoMedioMc']),
    totaleFisso: asDouble(j['totaleFisso']),
    totaleConsumo: asDouble(j['totaleConsumo']),
    totaleComune: asDouble(j['totaleComune']),
    totaleExtra: asDouble(j['totaleExtra']),
    totaleGenerale: asDouble(j['totaleGenerale']),
    metodo: MetodoRiparto.values.firstWhere(
      (e) => e.name == j['metodo'],
      orElse: () => MetodoRiparto.contatori,
    ),
    criterioFissa: CriterioQuota.values.firstWhere(
      (e) => e.name == j['criterioFissa'],
      orElse: () => CriterioQuota.partiUguali,
    ),
    criterioComune: CriterioQuota.values.firstWhere(
      (e) => e.name == j['criterioComune'],
      orElse: () => CriterioQuota.millesimi,
    ),
    avvisi: (j['avvisi'] as List? ?? []).map((e) => e.toString()).toList(),
    noteCalcolo: j['noteCalcolo'] as String? ?? '',
  );
}

class ConsumoUnita {
  const ConsumoUnita({
    required this.unitaId,
    this.letturaPrec,
    this.letturaAtt,
    required this.consumo,
    this.dataPrec,
    this.dataAtt,
  });

  final String unitaId;
  final double? letturaPrec;
  final double? letturaAtt;
  final double consumo;
  final DateTime? dataPrec;
  final DateTime? dataAtt;
}
