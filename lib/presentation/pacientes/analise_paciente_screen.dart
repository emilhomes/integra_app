import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import '../../core/constants/app_colors.dart';
import '../../core/services/clinical_intelligence_service.dart';
import '../../data/models/atendimento_model.dart';
import '../shared/silhouette_painter.dart';

class AnalisePacienteScreen extends StatelessWidget {
  final String pacienteId;
  final List<AtendimentoModel> atendimentos;

  const AnalisePacienteScreen({
    super.key, 
    required this.pacienteId, 
    required this.atendimentos
  });

  @override
  Widget build(BuildContext context) {
    final service = ClinicalIntelligenceService();
    final keywords = service.analyzeKeywords(atendimentos);
    final recurrentPain = service.detectRecurrentPoints(atendimentos);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Análise Preditiva', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Tendência de Queixas', Icons.psychology_outlined),
            _buildKeywordCloud(keywords),
            const SizedBox(height: 32),

            _buildSectionTitle('Mapa de Recorrência (Calor)', Icons.local_fire_department_outlined),
            _buildHeatmap(recurrentPain),
            const SizedBox(height: 32),

            _buildSectionTitle('Frequência Cardíaca', Icons.favorite_border),
            _buildVitalsChart((a) => double.tryParse(a.fc ?? '')),
            const SizedBox(height: 32),

            _buildSectionTitle('Pressão Arterial', Icons.speed_outlined),
            _buildPAChart(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(width: 12),
          Text(
            title,
            style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildKeywordCloud(Map<String, int> keywords) {
    if (keywords.isEmpty) return const Text('Dados insuficientes para análise.');
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: keywords.entries.map((e) {
          final double size = 14.0 + (e.value * 4.0).clamp(0, 20);
          return Chip(
            label: Text(
              e.key.toUpperCase(),
              style: GoogleFonts.outfit(
                fontSize: size, 
                fontWeight: FontWeight.bold,
                color: AppColors.primary.withValues(alpha: 0.6 + (e.value * 0.1).clamp(0, 0.4)),
              ),
            ),
            backgroundColor: AppColors.primary.withValues(alpha: 0.05),
            side: BorderSide.none,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHeatmap(List<Map<String, dynamic>> points) {
    return Container(
      height: 400,
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: 0.6,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final size = Size(constraints.maxWidth, constraints.maxHeight);
                  return CustomPaint(
                    size: size,
                    painter: AggregatedHeatmapPainter(points),
                  );
                },
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildLegendItem(Colors.red, 'Recorrência Alta'),
                _buildLegendItem(Colors.orange, 'Recorrência Média'),
                _buildLegendItem(AppColors.secondary, 'Tensão/Outros'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: GoogleFonts.outfit(fontSize: 10, color: Colors.grey[600])),
        const SizedBox(width: 8),
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      ],
    );
  }

  Widget _buildVitalsChart(double? Function(AtendimentoModel) getValue) {
    final sortedAtendimentos = List<AtendimentoModel>.from(atendimentos)
      ..sort((a, b) => a.data.compareTo(b.data));

    final spots = <FlSpot>[];
    for (int i = 0; i < sortedAtendimentos.length; i++) {
      final val = getValue(sortedAtendimentos[i]);
      if (val != null) spots.add(FlSpot(i.toDouble(), val));
    }

    if (spots.length < 2) {
      return const Center(child: Text('Dados insuficientes para gerar gráfico.'));
    }

    final minY = spots.map((s) => s.y).reduce(min) - 5;
    final maxY = spots.map((s) => s.y).reduce(max) + 5;

    return Container(
      height: 200,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 24, 24, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: LineChart(
        LineChartData(
          minY: minY,
          maxY: maxY,
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  int idx = value.toInt();
                  if (idx < 0 || idx >= sortedAtendimentos.length) return const Text('');
                  return Text(
                    DateFormat('dd/MM').format(sortedAtendimentos[idx].data),
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppColors.secondary,
              barWidth: 3,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(show: true, color: AppColors.secondary.withValues(alpha: 0.1)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPAChart() {
    final sortedAtendimentos = List<AtendimentoModel>.from(atendimentos)
      ..sort((a, b) => a.data.compareTo(b.data));

    final systolicSpots = <FlSpot>[];
    final diastolicSpots = <FlSpot>[];

    for (int i = 0; i < sortedAtendimentos.length; i++) {
      final pa = sortedAtendimentos[i].pa ?? '';
      final parts = pa.split('/');
      if (parts.length == 2) {
        final s = double.tryParse(parts[0]);
        final d = double.tryParse(parts[1]);
        if (s != null && d != null) {
          systolicSpots.add(FlSpot(i.toDouble(), s));
          diastolicSpots.add(FlSpot(i.toDouble(), d));
        }
      }
    }

    if (systolicSpots.length < 2) {
      return const Center(child: Text('Dados insuficientes para gerar gráfico de PA.'));
    }

    final allY = [...systolicSpots.map((s) => s.y), ...diastolicSpots.map((s) => s.y)];
    final minY = allY.reduce(min) - 10;
    final maxY = allY.reduce(max) + 10;

    return Container(
      height: 200,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 24, 24, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: LineChart(
        LineChartData(
          minY: minY,
          maxY: maxY,
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  int idx = value.toInt();
                  if (idx < 0 || idx >= sortedAtendimentos.length) return const Text('');
                  return Text(
                    DateFormat('dd/MM').format(sortedAtendimentos[idx].data),
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: systolicSpots,
              isCurved: true,
              color: Colors.redAccent,
              barWidth: 3,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(show: false),
            ),
            LineChartBarData(
              spots: diastolicSpots,
              isCurved: true,
              color: Colors.blueAccent,
              barWidth: 3,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(show: false),
            ),
          ],
        ),
      ),
    );
  }
}

class AggregatedHeatmapPainter extends CustomPainter {
  final List<Map<String, dynamic>> points;

  AggregatedHeatmapPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final path = SilhouettePainter.getSilhouettePath(size);
    
    // Desenha a silhueta de fundo
    final strokePaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawPath(path, strokePaint);

    final paint = Paint()..style = PaintingStyle.fill;

    for (var p in points) {
      final center = Offset(p['x'] * size.width, p['y'] * size.height);
      final count = p['count'] as int;
      
      final color = count >= 3 ? Colors.red : (count >= 2 ? Colors.orange : AppColors.secondary);
      final radius = 8.0 + (count * 4.0).clamp(0, 20);

      paint.color = color.withValues(alpha: 0.3);
      canvas.drawCircle(center, radius, paint);
      
      paint.color = color;
      canvas.drawCircle(center, 4, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
