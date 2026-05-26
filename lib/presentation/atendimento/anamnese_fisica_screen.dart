import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';

class AnamneseFisicaScreen extends StatefulWidget {
  final String pacienteId;
  const AnamneseFisicaScreen({super.key, required this.pacienteId});

  @override
  State<AnamneseFisicaScreen> createState() => _AnamneseFisicaScreenState();
}

class MarcacaoPonto {
  final double x; // Normalizado 0.0 a 1.0
  final double y; // Normalizado 0.0 a 1.0
  final bool isDor; // true = Ponto de Dor, false = Tensão Muscular

  MarcacaoPonto(this.x, this.y, this.isDor);

  Map<String, dynamic> toMap() => {'x': x, 'y': y, 'tipo': isDor ? 'dor' : 'tensao'};
}

class _AnamneseFisicaScreenState extends State<AnamneseFisicaScreen> {
  final List<MarcacaoPonto> _pontos = [];
  final List<bool> _tipoSelecionado = [true, false]; // [Dor, Tensão]

  void _adicionarPonto(Offset localPosition, Size size) {
    setState(() {
      _pontos.add(MarcacaoPonto(
        localPosition.dx / size.width,
        localPosition.dy / size.height,
        _tipoSelecionado[0],
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Anamnese Física')),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  'Mapa Corporal Interativo',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
                SizedBox(height: 8),
                Text(
                  'Toque na silhueta para marcar pontos de dor ou tensão muscular.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),

          // Seletor de Tipo
          ToggleButtons(
            isSelected: _tipoSelecionado,
            onPressed: (index) {
              setState(() {
                for (int i = 0; i < _tipoSelecionado.length; i++) {
                  _tipoSelecionado[i] = i == index;
                }
              });
            },
            borderRadius: BorderRadius.circular(12),
            selectedColor: Colors.white,
            fillColor: _tipoSelecionado[0] ? Colors.red.withValues(alpha: 0.8) : AppColors.secondary,
            constraints: const BoxConstraints(minHeight: 40, minWidth: 150),
            children: const [
              Text('Ponto de Dor'),
              Text('Tensão Muscular'),
            ],
          ),
          
          const SizedBox(height: 24),

          // Mapa Corporal
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 0.6,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final size = Size(constraints.maxWidth, constraints.maxHeight);
                    return GestureDetector(
                      onTapDown: (details) => _adicionarPonto(details.localPosition, size),
                      child: CustomPaint(
                        size: size,
                        painter: MapaCorporalPainter(_pontos),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // Legenda e Ações
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLegendItem(Colors.red, 'Ponto de Dor'),
                    const SizedBox(width: 24),
                    _buildLegendItem(AppColors.secondary, 'Tensão Muscular', isOutline: true),
                  ],
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _pontos.clear()),
                        child: const Text('Limpar Mapa'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () {
                          context.push('/anamnese/social/${widget.pacienteId}');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Próximo: Anamnese Social', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label, {bool isOutline = false}) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: isOutline ? Colors.transparent : color,
            border: isOutline ? Border.all(color: color, width: 2) : null,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class MapaCorporalPainter extends CustomPainter {
  final List<MarcacaoPonto> pontos;

  MapaCorporalPainter(this.pontos);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Desenho simplificado da silhueta humana (Frente)
    final path = Path();
    double w = size.width;
    double h = size.height;

    // Cabeça
    path.addOval(Rect.fromLTWH(w * 0.35, h * 0.02, w * 0.3, h * 0.12));
    
    // Pescoço e Ombros
    path.moveTo(w * 0.45, h * 0.14);
    path.lineTo(w * 0.4, h * 0.15);
    path.lineTo(w * 0.15, h * 0.22); // Ombro esquerdo
    
    // Braço esquerdo
    path.lineTo(w * 0.1, h * 0.45);
    path.lineTo(w * 0.2, h * 0.45);
    path.lineTo(w * 0.25, h * 0.25);
    
    // Tronco
    path.lineTo(w * 0.25, h * 0.55);
    
    // Perna esquerda
    path.lineTo(w * 0.3, h * 0.95);
    path.lineTo(w * 0.45, h * 0.95);
    path.lineTo(w * 0.5, h * 0.65); // Entre-pernas
    
    // Perna direita
    path.lineTo(w * 0.55, h * 0.95);
    path.lineTo(w * 0.7, h * 0.95);
    path.lineTo(w * 0.75, h * 0.55);
    
    // Tronco volta
    path.lineTo(w * 0.75, h * 0.25);
    
    // Braço direito
    path.lineTo(w * 0.8, h * 0.45);
    path.lineTo(w * 0.9, h * 0.45);
    path.lineTo(w * 0.85, h * 0.22); // Ombro direito
    
    path.lineTo(w * 0.6, h * 0.15);
    path.lineTo(w * 0.55, h * 0.14);

    canvas.drawPath(path, paint);

    // Desenhar Pontos marcados
    for (var ponto in pontos) {
      final center = Offset(ponto.x * w, ponto.y * h);
      final pPaint = Paint()
        ..color = ponto.isDor ? const Color(0xFFEF4444) : const Color(0xFF0E9F6E)
        ..style = ponto.isDor ? PaintingStyle.fill : PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawCircle(center, 10, pPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
