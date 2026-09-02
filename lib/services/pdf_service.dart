import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/models.dart';
import '../utils/format.dart';

class PdfService {
  static Future<pw.Font> _regular() async {
    final data = await rootBundle.load('assets/fonts/NimbusSansL-Regular.ttf');
    return pw.Font.ttf(data);
  }

  static Future<pw.Font> _bold() async {
    final data = await rootBundle.load('assets/fonts/NimbusSansL-Bold.ttf');
    return pw.Font.ttf(data);
  }

  static Future<void> shareRiparto({
    required Condominio condominio,
    required Bolletta bolletta,
    required RisultatoRiparto riparto,
  }) async {
    final bytes = await buildRiparto(
      condominio: condominio,
      bolletta: bolletta,
      riparto: riparto,
    );
    final name =
        'Riparto_acqua_${fileSafe(condominio.nome)}_'
        '${dateShort.format(bolletta.periodoDal)}_'
        '${dateShort.format(bolletta.periodoAl)}.pdf';
    await Printing.sharePdf(bytes: bytes, filename: name);
  }

  static Future<void> printRiparto({
    required Condominio condominio,
    required Bolletta bolletta,
    required RisultatoRiparto riparto,
  }) async {
    await Printing.layoutPdf(
      onLayout: (_) => buildRiparto(
        condominio: condominio,
        bolletta: bolletta,
        riparto: riparto,
      ),
    );
  }

  static Future<Uint8List> buildRiparto({
    required Condominio condominio,
    required Bolletta bolletta,
    required RisultatoRiparto riparto,
  }) async {
    final regular = await _regular();
    final bold = await _bold();
    final teal = PdfColor.fromHex('2264E2');
    final deep = PdfColor.fromHex('0B1B34');
    final line = PdfColor.fromHex('D5DCE8');
    final paper = PdfColor.fromHex('EEF3FC');
    final muted = PdfColor.fromHex('5A6577');

    final doc = pw.Document(
      title: 'Prospetto riparto acqua — ${condominio.nome}',
      author: 'IdroRiparto',
    );

    pw.TextStyle st(double size, {bool b = false, PdfColor? c}) => pw.TextStyle(
      font: b ? bold : regular,
      fontSize: size,
      color: c ?? deep,
    );

    final headers = [
      'Int.',
      'Intestatario',
      'Mill.',
      'm³',
      'Fissa',
      'Consumo',
      'Comuni',
      'IVA/altro',
      'Totale',
      '%',
    ];

    final data = riparto.righe
        .map(
          (r) => [
            r.interno,
            r.proprietario,
            mill(r.millesimi),
            mcNum(r.consumoMc),
            euro(r.quotaFissa),
            euro(r.quotaConsumo),
            euro(r.quotaComune),
            euro(r.quotaExtra),
            euro(r.totale),
            pctFormat.format(r.percentuale),
          ],
        )
        .toList();

    data.add([
      '',
      'TOTALE',
      mill(riparto.righe.fold<double>(0, (a, r) => a + r.millesimi)),
      mcNum(riparto.sommaConsumi),
      euro(riparto.totaleFisso),
      euro(riparto.totaleConsumo),
      euro(riparto.totaleComune),
      euro(riparto.totaleExtra),
      euro(riparto.totaleGenerale),
      '100',
    ]);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(28, 30, 28, 36),
        header: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: 10,
                  height: 42,
                  decoration: pw.BoxDecoration(
                    color: teal,
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'PROSPETTO DI RIPARTIZIONE',
                        style: st(9, c: muted),
                      ),
                      pw.Text(
                        'Spese idriche condominiali',
                        style: st(16, b: true),
                      ),
                    ],
                  ),
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('IdroRiparto', style: st(11, b: true, c: teal)),
                    pw.Text(
                      'Generato il ${dateIt.format(riparto.calcolatoIl)}',
                      style: st(8, c: muted),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Container(height: 1, color: line),
            pw.SizedBox(height: 12),
          ],
        ),
        footer: (ctx) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 10),
          child: pw.Text(
            'Pagina ${ctx.pageNumber} di ${ctx.pagesCount}  ·  Documento di lavoro interno, non sostituisce la bolletta del gestore.',
            style: st(8, c: muted),
          ),
        ),
        build: (ctx) => [
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: paper,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: _kv(st, [
                    ('Condominio', condominio.nome),
                    ('Indirizzo', condominio.indirizzoCompleto),
                    ('Amministratore', condominio.amministratore),
                    (
                      'Fornitore',
                      bolletta.fornitore.isEmpty
                          ? condominio.fornitore
                          : bolletta.fornitore,
                    ),
                  ]),
                ),
                pw.Expanded(
                  child: _kv(st, [
                    (
                      'Periodo',
                      periodLabel(bolletta.periodoDal, bolletta.periodoAl),
                    ),
                    (
                      'Documento',
                      bolletta.numero.isEmpty ? '—' : bolletta.numero,
                    ),
                    ('Metodo', bolletta.metodo.titolo),
                    (
                      'Criteri',
                      'Fissa: ${bolletta.criterioFissa.label} · Comuni: ${bolletta.criterioComune.label}',
                    ),
                  ]),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 14),
          pw.Text('Sintesi importi', style: st(11, b: true)),
          pw.SizedBox(height: 6),
          pw.TableHelper.fromTextArray(
            headers: ['Voce', 'Importo', 'Note'],
            data: [
              [
                'Quota fissa / canone',
                euro(bolletta.quotaFissa),
                'Ripartita a ${bolletta.criterioFissa.label.toLowerCase()}',
              ],
              ['Acquedotto', euro(bolletta.acquedotto), ''],
              ['Fognatura', euro(bolletta.fognatura), ''],
              ['Depurazione', euro(bolletta.depurazione), ''],
              ['IVA', euro(bolletta.iva), 'Spalmata sul subtotale'],
              ['Altro', euro(bolletta.altro), ''],
              [
                'TOTALE BOLLETTA',
                euro(bolletta.totale),
                '${mcNum(bolletta.mcFatturati)} m³ fatturati',
              ],
            ],
            headerStyle: st(8, b: true, c: PdfColors.white),
            headerDecoration: pw.BoxDecoration(color: deep),
            cellStyle: st(8),
            cellAlignment: pw.Alignment.centerLeft,
            cellAlignments: {1: pw.Alignment.centerRight},
            columnWidths: {
              0: const pw.FlexColumnWidth(2.2),
              1: const pw.FlexColumnWidth(1.2),
              2: const pw.FlexColumnWidth(2.6),
            },
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            'Consumi individuali ${mcNum(riparto.sommaConsumi)} m³  ·  '
            'Parti comuni e perdite ${mcNum(riparto.consumoComune)} m³  ·  '
            'Prezzo medio ${euro(riparto.prezzoMedioMc)} / m³',
            style: st(8, c: muted),
          ),
          pw.SizedBox(height: 4),
          pw.Text(riparto.noteCalcolo, style: st(8, c: muted)),
          if (riparto.avvisi.isNotEmpty) ...[
            pw.SizedBox(height: 8),
            pw.Text('Avvertenze', style: st(10, b: true)),
            for (final a in riparto.avvisi) pw.Text('• $a', style: st(8)),
          ],
          pw.SizedBox(height: 14),
          pw.Text('Riparto per unità immobiliare', style: st(11, b: true)),
          pw.SizedBox(height: 6),
          pw.TableHelper.fromTextArray(
            headers: headers,
            data: data,
            headerStyle: st(7, b: true, c: PdfColors.white),
            headerDecoration: pw.BoxDecoration(color: teal),
            cellStyle: st(7),
            cellAlignments: {
              2: pw.Alignment.centerRight,
              3: pw.Alignment.centerRight,
              4: pw.Alignment.centerRight,
              5: pw.Alignment.centerRight,
              6: pw.Alignment.centerRight,
              7: pw.Alignment.centerRight,
              8: pw.Alignment.centerRight,
              9: pw.Alignment.centerRight,
            },
            rowDecoration: pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: line, width: 0.4)),
            ),
          ),
          pw.SizedBox(height: 18),
          pw.Text(
            'Prospetti individuali (da staccare)',
            style: st(11, b: true),
          ),
          pw.SizedBox(height: 8),
          pw.Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final r in riparto.righe)
                pw.Container(
                  width: 250,
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: line),
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        '${condominio.nome}  ·  int. ${r.interno}',
                        style: st(8, b: true),
                      ),
                      pw.Text(r.proprietario, style: st(8)),
                      pw.Text(
                        'Acqua ${periodLabel(bolletta.periodoDal, bolletta.periodoAl)}',
                        style: st(7, c: muted),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text('Consumo ${mc(r.consumoMc)}', style: st(7)),
                      pw.Text(
                        'Fissa ${euro(r.quotaFissa)}  ·  Consumo ${euro(r.quotaConsumo)}',
                        style: st(7),
                      ),
                      pw.Text(
                        'Comuni ${euro(r.quotaComune)}  ·  IVA/altro ${euro(r.quotaExtra)}',
                        style: st(7),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        'DOVUTO  ${euro(r.totale)}',
                        style: st(9, b: true, c: teal),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          pw.SizedBox(height: 22),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(width: 180, height: 1, color: line),
                  pw.SizedBox(height: 4),
                  pw.Text('L’amministratore', style: st(8, c: muted)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(width: 180, height: 1, color: line),
                  pw.SizedBox(height: 4),
                  pw.Text('Data', style: st(8, c: muted)),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Text(
            'Nota giuridica. In presenza di sottocontatori individuali la prassi e la giurisprudenza '
            'privilegiano il criterio del consumo effettivo. In mancanza si applica l’art. 1123 c.c. '
            '(millesimi), salvo diverso regolamento contrattuale o delibera assembleare. '
            'IdroRiparto è uno strumento di calcolo: verificare sempre il regolamento del condominio.',
            style: st(7, c: muted),
          ),
        ],
      ),
    );

    return doc.save();
  }

  static pw.Widget _kv(
    pw.TextStyle Function(double, {bool b, PdfColor? c}) st,
    List<(String, String)> rows,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        for (final r in rows)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 3),
            child: pw.RichText(
              text: pw.TextSpan(
                children: [
                  pw.TextSpan(text: '${r.$1}: ', style: st(8, b: true)),
                  pw.TextSpan(text: r.$2.isEmpty ? '—' : r.$2, style: st(8)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class CsvService {
  static String ripartoCsv(RisultatoRiparto r) {
    final b = StringBuffer();
    b.writeln(
      'Interno;Proprietario;Millesimi;Occupanti;Sfitto;Consumo_mc;Quota_fissa;Quota_consumo;Quota_comune;IVA_altro;Totale;Percentuale',
    );
    for (final x in r.righe) {
      b.writeln(
        [
          x.interno,
          x.proprietario,
          mill(x.millesimi),
          x.occupanti,
          x.sfitto ? 'sì' : 'no',
          mcNum(x.consumoMc),
          euro(x.quotaFissa),
          euro(x.quotaConsumo),
          euro(x.quotaComune),
          euro(x.quotaExtra),
          euro(x.totale),
          pctFormat.format(x.percentuale),
        ].join(';'),
      );
    }
    return b.toString();
  }
}
