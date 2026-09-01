import 'package:flutter_test/flutter_test.dart';
import 'package:idroriparto/models/models.dart';
import 'package:idroriparto/services/riparto_engine.dart';

UnitaImmobiliare u(
  String id,
  String interno,
  double mill, {
  int occ = 1,
  bool sfitto = false,
}) {
  return UnitaImmobiliare(
    id: id,
    interno: interno,
    proprietario: 'P $interno',
    millesimi: mill,
    occupanti: occ,
    sfitto: sfitto,
  );
}

Bolletta bill({
  MetodoRiparto metodo = MetodoRiparto.misto,
  CriterioQuota fissa = CriterioQuota.millesimi,
  CriterioQuota comune = CriterioQuota.millesimi,
  double quotaFissa = 100,
  double variabile = 200,
  double iva = 0,
  double mc = 50,
  Map<String, double> consumi = const {},
}) {
  return Bolletta(
    id: 'b1',
    dataDocumento: DateTime(2026, 7, 1),
    periodoDal: DateTime(2026, 4, 1),
    periodoAl: DateTime(2026, 6, 30),
    quotaFissa: quotaFissa,
    acquedotto: variabile,
    iva: iva,
    mcFatturati: mc,
    metodo: metodo,
    criterioFissa: fissa,
    criterioComune: comune,
    consumi: consumi,
    createdAt: DateTime(2026, 7, 1),
  );
}

void main() {
  final due = [
    u('a', '1', 500, occ: 1),
    u('b', '2', 500, occ: 3),
  ];

  test('millesimi 50/50 sull’intero importo', () {
    final r = RipartoEngine.calcola(
      bolletta: bill(
        metodo: MetodoRiparto.millesimi,
        quotaFissa: 100,
        variabile: 200,
      ),
      unita: due,
    );
    expect(r.righe[0].totale, 150);
    expect(r.righe[1].totale, 150);
    expect(r.totaleGenerale, 300);
  });

  test('consumo 10/30 sull’intero importo', () {
    final r = RipartoEngine.calcola(
      bolletta: bill(
        metodo: MetodoRiparto.consumo,
        quotaFissa: 100,
        variabile: 200,
        mc: 40,
        consumi: {'a': 10, 'b': 30},
      ),
      unita: due,
    );
    expect(r.righe[0].totale, 75);
    expect(r.righe[1].totale, 225);
  });

  test('teste 1/3', () {
    final r = RipartoEngine.calcola(
      bolletta: bill(metodo: MetodoRiparto.teste, quotaFissa: 100, variabile: 200),
      unita: due,
    );
    expect(r.righe[0].totale, 75);
    expect(r.righe[1].totale, 225);
  });

  test('misto: fissa millesimi, consumi 10/30, comune 10 m³', () {
    // variabile 200, mc 50 → 4 €/m³
    // individuale 40 m³ = 160; comune 10 m³ = 40
    // fissa 100 → 50/50
    // comune 40 → 20/20
    // A: 50 + 40 + 20 = 110
    // B: 50 + 120 + 20 = 190
    final r = RipartoEngine.calcola(
      bolletta: bill(
        consumi: {'a': 10, 'b': 30},
      ),
      unita: due,
    );
    expect(r.sommaConsumi, 40);
    expect(r.consumoComune, 10);
    expect(r.righe[0].quotaFissa, 50);
    expect(r.righe[0].quotaConsumo, 40);
    expect(r.righe[0].quotaComune, 20);
    expect(r.righe[0].totale, 110);
    expect(r.righe[1].totale, 190);
    expect(r.totaleGenerale, 300);
  });

  test('la somma delle righe coincide sempre con la bolletta', () {
    final unita = [
      u('a', '1', 138, occ: 3),
      u('b', '2', 112.5, occ: 2),
      u('c', '3', 125, occ: 4),
      u('d', '4', 97.5, occ: 1),
      u('e', '5', 152, occ: 2),
      u('f', '6', 86, occ: 0, sfitto: true),
      u('g', '7', 141, occ: 3),
      u('h', '8', 148, occ: 2),
    ];
    final b = bill(
      quotaFissa: 192,
      variabile: 491.4,
      iva: 68.34,
      mc: 128.2,
      consumi: {
        'a': 18.4,
        'b': 11.2,
        'c': 24.6,
        'd': 7.8,
        'e': 15.3,
        'f': 0.4,
        'g': 19.1,
        'h': 16.7,
      },
    );
    final r = RipartoEngine.calcola(bolletta: b, unita: unita);
    final sum = r.righe.fold<double>(0, (a, x) => a + x.totale);
    expect((sum - b.totale).abs() < 0.001, isTrue);
    expect((r.totaleGenerale - b.totale).abs() < 0.001, isTrue);
    for (final row in r.righe) {
      final parts =
          row.quotaFissa + row.quotaConsumo + row.quotaComune + row.quotaExtra;
      expect((parts - row.totale).abs() < 0.001, isTrue, reason: row.interno);
    }
  });

  test('consumo zero: fallback millesimi', () {
    final r = RipartoEngine.calcola(
      bolletta: bill(metodo: MetodoRiparto.consumo, consumi: {'a': 0, 'b': 0}),
      unita: due,
    );
    expect(r.righe[0].totale, 150);
    expect(r.avvisi.any((a) => a.contains('fallback')), isTrue);
  });

  test('allocateRounded ripartisce i centesimi', () {
    final out = allocateRounded([10.006, 10.004], 20.01);
    expect(out[0] + out[1], closeTo(20.01, 0.0001));
    expect(out.every((x) => ((x * 100).roundToDouble() / 100) == x), isTrue);
  });
}
