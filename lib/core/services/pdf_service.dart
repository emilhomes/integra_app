import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

class PdfService {
  /// Gera um PDF para o Relatório Clínico.
  Future<String> gerarRelatorioClinico({
    required String pacienteNome,
    required String dorRecorrente,
    required String bemEstar,
    required List<Map<String, String>> atendimentos,
  }) async {
    final pdf = pw.Document();
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader('RELATÓRIO CLÍNICO'),
              pw.SizedBox(height: 20),
              pw.Text('Paciente: $pacienteNome'),
              pw.Text('Data de Geração: $dateStr'),
              pw.SizedBox(height: 20),
              pw.Text('Indicadores Atuais:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Bullet(text: 'Dor Recorrente: $dorRecorrente'),
              pw.Bullet(text: 'Bem-Estar Geral: $bemEstar'),
              pw.SizedBox(height: 20),
              pw.Text('Últimos Atendimentos:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.TableHelper.fromTextArray(
                headers: ['Data', 'Terapia', 'Observação'],
                data: atendimentos.map((a) => [a['data'], a['terapia'], a['obs']]).toList(),
              ),
              pw.Spacer(),
              pw.Divider(),
              pw.Align(
                alignment: pw.Alignment.center,
                child: pw.Text('ÍNTEGRA - Universidade do Estado do Rio Grande do Norte (UERN)', style: const pw.TextStyle(fontSize: 10)),
              ),
            ],
          );
        },
      ),
    );

    return _savePdf('relatorio_clinico_${DateTime.now().millisecondsSinceEpoch}.pdf', pdf);
  }

  /// Gera um PDF para o Relatório de Estágio.
  Future<String> gerarRelatorioEstagio({
    required String estagiarioNome,
    required String periodo,
    required String totalAtendimentos,
    required Map<String, int> contagemPorTerapia,
    required List<Map<String, String>> atendimentos,
  }) async {
    final pdf = pw.Document();
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader('RELATÓRIO DE ESTÁGIO'),
              pw.SizedBox(height: 20),
              pw.Text('Estagiário: $estagiarioNome'),
              pw.Text('Período: $periodo'),
              pw.Text('Data de Geração: $dateStr'),
              pw.SizedBox(height: 20),
              pw.Text('Resumo do Período:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text('Total de Atendimentos: $totalAtendimentos'),
              pw.SizedBox(height: 10),
              pw.Text('Distribuição por Terapia:'),
              ...contagemPorTerapia.entries.map((e) => pw.Bullet(text: '${e.key}: ${e.value}')),
              pw.SizedBox(height: 20),
              pw.Text('Lista Detalhada:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.TableHelper.fromTextArray(
                headers: ['Data', 'Paciente ID', 'Terapias'],
                data: atendimentos.map((a) => [a['data'], a['paciente'], a['terapias']]).toList(),
              ),
              pw.Spacer(),
              pw.Divider(),
              pw.Align(
                alignment: pw.Alignment.center,
                child: pw.Text('ÍNTEGRA - Universidade do Estado do Rio Grande do Norte (UERN)', style: const pw.TextStyle(fontSize: 10)),
              ),
            ],
          );
        },
      ),
    );

    return _savePdf('relatorio_estagio_${DateTime.now().millisecondsSinceEpoch}.pdf', pdf);
  }

  pw.Widget _buildHeader(String title) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('ÍNTEGRA', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.Text('UERN - Práticas Integrativas', style: const pw.TextStyle(fontSize: 12)),
          ],
        ),
        pw.Text(title, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }

  Future<String> _savePdf(String fileName, pw.Document pdf) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File(p.join(directory.path, fileName));
    await file.writeAsBytes(await pdf.save());
    return file.path;
  }
}
