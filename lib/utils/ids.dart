import 'dart:math';

final _rng = Random();

String newId([String prefix = 'id']) {
  final t = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
  final r = _rng.nextInt(0x7fffffff).toRadixString(16);
  return '${prefix}_$t$r';
}
