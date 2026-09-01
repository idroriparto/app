import 'package:flutter_test/flutter_test.dart';
import 'package:idroriparto/data/demo_data.dart';
import 'package:idroriparto/models/models.dart';

void main() {
  test('il condominio di esempio ha 1.000 millesimi e due bollette chiuse/calcolate', () {
    final snap = buildDemoSnapshot();
    expect(snap.condominio?.nome, 'Palazzo Solferino');
    expect(snap.unita.length, 8);
    final mill = snap.unita.fold<double>(0, (a, u) => a + u.millesimi);
    expect(mill, closeTo(1000, 0.001));
    expect(snap.bollette.length, 2);
    expect(snap.riparti.length, 2);
    for (final r in snap.riparti) {
      final b = snap.bollette.firstWhere((x) => x.id == r.bollettaId);
      expect(r.totaleGenerale, closeTo(b.totale, 0.001));
      expect(r.metodo, MetodoRiparto.contatori);
    }
  });
}
