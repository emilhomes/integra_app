import '../../data/models/atendimento_model.dart';
import 'dart:math';

class IntelligenceInsight {
  final String title;
  final String message;
  final InsightLevel level;
  final Map<String, dynamic>? extraData; // Dados para o relatório detalhado

  IntelligenceInsight({required this.title, required this.message, required this.level, this.extraData});
}

enum InsightLevel { info, warning, success }

class ClinicalIntelligenceService {
  
  /// Converte coordenadas X/Y em nomes de regiões anatômicas
  String getRegionName(double x, double y) {
    if (y < 0.12) return 'Cabeça/Pescoço';
    if (y < 0.25) {
      if (x < 0.4) return 'Ombro Esquerdo';
      if (x > 0.6) return 'Ombro Direito';
      return 'Região Torácica Superior';
    }
    if (y < 0.45) {
      if (x < 0.35 || x > 0.65) return 'Braços';
      return 'Região Abdominal/Dorsal Média';
    }
    if (y < 0.65) return 'Região Lombar/Pélvica';
    return 'Membros Inferiores (Pernas/Pés)';
  }
/// Analisa palavras-chave nas queixas principais
Map<String, int> analyzeKeywords(List<AtendimentoModel> atendimentos) {
  final Map<String, int> counts = {};
  final stopWords = {
    'a', 'o', 'e', 'de', 'do', 'da', 'em', 'um', 'para', 'com', 'no', 'na', 'que', 'tem', 'esta', 'estou', 'muito', 'muita', 'está', 'pelo', 'pela', 'mais',
    'cliente', 'informa', 'sentindo', 'paciente', 'apresenta', 'relata', 'refere', 'disse', 'disse que', 'com muita', 'com muito', 'há', 'dia', 'dias'
  };

  for (var a in atendimentos) {
    if (a.queixaPrincipal == null) continue;

    final words = a.queixaPrincipal!
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\sà-úÀ-Ú]'), '')
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 2 && !stopWords.contains(w));

    for (var w in words) {
      // Normalização simples de acentos para contagem (ex: insonia -> insônia)
      // Por agora, vamos apenas limpar para agrupar e depois usar o termo original mais comum
      final normalized = _normalizeWord(w);
      counts[normalized] = (counts[normalized] ?? 0) + 1;
    }
  }

  final sorted = counts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  return Map.fromEntries(sorted.take(10));
}

String _normalizeWord(String word) {
  // Remove acentos apenas para comparação/agrupamento
  const withAccent = 'àáâãäèéêëìíîïòóôõöùúûüç';
  const withoutAccent = 'aaaaaeeeeiiiiooooouuuuc';
  String normalized = word;
  for (int i = 0; i < withAccent.length; i++) {
    normalized = normalized.replaceAll(withAccent[i], withoutAccent[i]);
  }
  // Mapeamento manual de termos comuns para garantir a versão correta
  if (normalized == 'insonia') return 'insônia';
  if (normalized == 'cabeca') return 'cabeça';
  if (normalized == 'tensao') return 'tensão';
  if (normalized == 'coluna') return 'coluna';
  if (normalized == 'lombar') return 'lombar';
  return word; // Retorna original se não for caso especial, mas agrupado por insonia/insônia na lógica se necessário
}

  /// Detecta pontos recorrentes (dor ou tensão)
  List<Map<String, dynamic>> detectRecurrentPoints(List<AtendimentoModel> atendimentos) {
    final List<Map<String, dynamic>> allPoints = [];
    for (var a in atendimentos) {
      if (a.pontosDorTensao == null) continue;
      for (var p in a.pontosDorTensao!) {
        allPoints.add({
          'x': p['x'],
          'y': p['y'],
          'tipo': p['tipo'],
          'data': a.data,
        });
      }
    }

    final List<Map<String, dynamic>> recurrent = [];
    final usedIndices = <int>{};

    for (int i = 0; i < allPoints.length; i++) {
      if (usedIndices.contains(i)) continue;
      
      final current = allPoints[i];
      final List<Map<String, dynamic>> group = [current];
      
      for (int j = i + 1; j < allPoints.length; j++) {
        final other = allPoints[j];
        final dist = sqrt(pow(current['x'] - other['x'], 2) + pow(current['y'] - other['y'], 2));
        
        if (dist < 0.05) { 
          group.add(other);
          usedIndices.add(j);
        }
      }

      if (group.length >= 2) {
        recurrent.add({
          'x': current['x'],
          'y': current['y'],
          'count': group.length,
          'tipo': current['tipo'],
          'region': getRegionName(current['x'], current['y']),
          'dates': group.map((e) => e['data'] as DateTime).toList(),
        });
      }
    }

    return recurrent;
  }

  /// Gera insights baseados nos dados processados
  List<IntelligenceInsight> generateInsights(List<AtendimentoModel> atendimentos) {
    final insights = <IntelligenceInsight>[];
    if (atendimentos.isEmpty) return insights;

    // Insight de Queixas
    final keywords = analyzeKeywords(atendimentos);
    if (keywords.isNotEmpty) {
      final top = keywords.keys.first;
      insights.add(IntelligenceInsight(
        title: 'Recorrência de Queixa',
        message: 'O paciente se queixou de "$top" ${keywords[top]} vezes recentemente.',
        level: InsightLevel.info,
        extraData: {'type': 'keyword', 'word': top, 'count': keywords[top]},
      ));
    }

    // Insight de Pontos Recorrentes
    final recurrent = detectRecurrentPoints(atendimentos);
    if (recurrent.isNotEmpty) {
      final maxRecurrencePoint = recurrent.reduce((a, b) => (a['count'] as int) > (b['count'] as int) ? a : b);
      final count = maxRecurrencePoint['count'] as int;
      final region = maxRecurrencePoint['region'] as String;
      final isDor = maxRecurrencePoint['tipo'] == 'dor';
      
      if (count >= 3) {
        insights.add(IntelligenceInsight(
          title: isDor ? 'Dor Persistente' : 'Tensão Crônica',
          message: 'Detectamos ${isDor ? 'dor' : 'tensão'} na região: $region ($count sessões).',
          level: InsightLevel.warning,
          extraData: {'type': 'recurrence', 'point': maxRecurrencePoint},
        ));
      }
    }

    // Insight de Sinais Vitais
    if (atendimentos.length >= 3) {
      final validFCs = atendimentos
          .where((a) => a.fc != null && double.tryParse(a.fc!) != null)
          .map((a) => double.parse(a.fc!))
          .toList();

      if (validFCs.length >= 3) {
        final last = validFCs.last;
        final avg = validFCs.take(validFCs.length - 1).reduce((a, b) => a + b) / (validFCs.length - 1);
        
        if ((last - avg).abs() > 15) {
          insights.add(IntelligenceInsight(
            title: 'Alerta de Sinais Vitais',
            message: 'A Frequência Cardíaca ($last bpm) variou muito da média (~${avg.toStringAsFixed(0)} bpm).',
            level: InsightLevel.warning,
            extraData: {'type': 'vitals', 'current': last, 'avg': avg},
          ));
        }
      }
    }

    return insights;
  }
}
