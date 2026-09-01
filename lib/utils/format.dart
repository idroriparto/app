import 'package:intl/intl.dart';

final euroFormat = NumberFormat.currency(locale: 'it_IT', symbol: '€');
final euroPlain = NumberFormat.currency(
  locale: 'it_IT',
  symbol: '€',
  decimalDigits: 2,
);
final mcFormat = NumberFormat('#,##0.000', 'it_IT');
final mcShort = NumberFormat('#,##0.##', 'it_IT');
final millFormat = NumberFormat('#,##0.00', 'it_IT');
final pctFormat = NumberFormat('#,##0.0', 'it_IT');
final intIt = NumberFormat.decimalPattern('it_IT');
final dateIt = DateFormat('d MMMM yyyy', 'it_IT');
final dateShort = DateFormat('dd/MM/yyyy', 'it_IT');
final monthYear = DateFormat('MMMM yyyy', 'it_IT');

String euro(num? v) => euroFormat.format(v ?? 0);
String mc(num? v) => '${mcFormat.format(v ?? 0)} m³';
String mcNum(num? v) => mcFormat.format(v ?? 0);
String mill(num? v) => millFormat.format(v ?? 0);
String pct(num? v) => '${pctFormat.format(v ?? 0)} %';

double? parseItNumber(String raw) {
  var s = raw.trim().replaceAll('€', '').replaceAll('m³', '').replaceAll('m3', '');
  s = s.replaceAll('\u00a0', '').replaceAll(' ', '');
  if (s.isEmpty) return null;
  if (s.contains(',') && s.contains('.')) {
    final lastComma = s.lastIndexOf(',');
    final lastDot = s.lastIndexOf('.');
    if (lastComma > lastDot) {
      s = s.replaceAll('.', '').replaceAll(',', '.');
    } else {
      s = s.replaceAll(',', '');
    }
  } else {
    s = s.replaceAll(',', '.');
  }
  return double.tryParse(s);
}

String periodLabel(DateTime dal, DateTime al) {
  if (dal.year == al.year && dal.month == al.month) {
    return toBeginningOfSentenceCase(monthYear.format(dal)) ?? monthYear.format(dal);
  }
  if (dal.year == al.year) {
    final a = DateFormat('d MMM', 'it_IT').format(dal);
    final b = DateFormat('d MMM yyyy', 'it_IT').format(al);
    return '$a – $b';
  }
  return '${dateShort.format(dal)} – ${dateShort.format(al)}';
}

String greetingFor(DateTime now) {
  final h = now.hour;
  if (h < 5) return 'Buona notte';
  if (h < 13) return 'Buongiorno';
  if (h < 18) return 'Buon pomeriggio';
  return 'Buonasera';
}

String fileSafe(String name) {
  return name
      .replaceAll(RegExp(r'[^\w\s\-àèéìòù]+', caseSensitive: false), '')
      .trim()
      .replaceAll(RegExp(r'\s+'), '_');
}
