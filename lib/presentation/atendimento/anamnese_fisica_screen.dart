import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../shared/silhouette_painter.dart';

class AnamneseFisicaScreen extends StatefulWidget {
  final String pacienteId;
  final List<Map<String, dynamic>>? pontosIniciais;
  const AnamneseFisicaScreen({super.key, required this.pacienteId, this.pontosIniciais});

  @override
  State<AnamneseFisicaScreen> createState() => _AnamneseFisicaScreenState();
}

class MarcacaoPonto {
  final double x; // Normalizado 0.0 a 1.0
  final double y; // Normalizado 0.0 a 1.0
  final bool isDor; // true = Ponto de Dor, false = Tensão Muscular

  MarcacaoPonto(this.x, this.y, this.isDor);

  Map<String, dynamic> toMap() => {'x': x, 'y': y, 'tipo': isDor ? 'dor' : 'tensao'};
  
  factory MarcacaoPonto.fromMap(Map<String, dynamic> map) {
    return MarcacaoPonto(
      map['x']?.toDouble() ?? 0.0,
      map['y']?.toDouble() ?? 0.0,
      map['tipo'] == 'dor',
    );
  }
}

class _AnamneseFisicaScreenState extends State<AnamneseFisicaScreen> {
  final List<MarcacaoPonto> _pontos = [];
  final List<bool> _tipoSelecionado = [true, false]; // [Dor, Tensão]

  @override
  void initState() {
    super.initState();
    if (widget.pontosIniciais != null) {
      _pontos.addAll(widget.pontosIniciais!.map((m) => MarcacaoPonto.fromMap(m)));
    }
  }

  void _adicionarPonto(Offset localPosition, Size size, Path silhouettePath) {
    if (silhouettePath.contains(localPosition)) {
      setState(() {
        _pontos.add(MarcacaoPonto(
          localPosition.dx / size.width,
          localPosition.dy / size.height,
          _tipoSelecionado[0],
        ));
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Toque dentro da silhueta para marcar.'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Mapa Corporal', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.primary,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Text(
                  'Marcação de Pontos',
                  style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.primary, letterSpacing: 1),
                ),
                const SizedBox(height: 8),
                Text(
                  'Toque na silhueta para marcar pontos de dor ou tensão.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
          ),

          ToggleButtons(
            isSelected: _tipoSelecionado,
            onPressed: (index) {
              setState(() {
                for (int i = 0; i < _tipoSelecionado.length; i++) {
                  _tipoSelecionado[i] = i == index;
                }
              });
            },
            borderRadius: BorderRadius.circular(16),
            selectedColor: Colors.white,
            fillColor: _tipoSelecionado[0] ? Colors.red.withValues(alpha: 0.8) : AppColors.secondary,
            constraints: const BoxConstraints(minHeight: 44, minWidth: 150),
            children: [
              Text('Dor', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
              Text('Tensão', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
            ],
          ),
          
          const SizedBox(height: 32),

          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 0.6,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final size = Size(constraints.maxWidth, constraints.maxHeight);
                    final silhouettePath = SilhouettePainter.getSilhouettePath(size);
                    return GestureDetector(
                      onTapDown: (details) => _adicionarPonto(details.localPosition, size, silhouettePath),
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

          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _pontos.clear()),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text('Limpar', style: GoogleFonts.outfit(color: Colors.grey[600], fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      final maps = _pontos.map((p) => p.toMap()).toList();
                      context.pop(maps);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: Text('Confirmar', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MapaCorporalPainter extends CustomPainter {
  final List<MarcacaoPonto> pontos;

  MapaCorporalPainter(this.pontos);

  @override
  void paint(Canvas canvas, Size size) {
    // Reutiliza SilhouettePainter logicamente
    final path = SilhouettePainter.getSilhouettePath(size);
    
    // Fundo
    final shadowPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.05)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12.0)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path.shift(const Offset(4, 6)), shadowPaint);

    final gradientPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.primary.withValues(alpha: 0.12),
          AppColors.primary.withValues(alpha: 0.05),
        ],
      ).createShader(path.getBounds())
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, gradientPaint);

    final strokePaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawPath(path, strokePaint);

    for (var ponto in pontos) {
      final center = Offset(ponto.x * size.width, ponto.y * size.height);

      if (ponto.isDor) {
        canvas.drawCircle(center, 12, Paint()..color = const Color(0xFFEF4444).withValues(alpha: 0.2)..style = PaintingStyle.fill);
        canvas.drawCircle(center, 6, Paint()..color = const Color(0xFFEF4444)..style = PaintingStyle.fill);
      } else {
        canvas.drawCircle(center, 6, Paint()..color = AppColors.secondary..style = PaintingStyle.fill);
        canvas.drawCircle(center, 9, Paint()..color = AppColors.secondary..style = PaintingStyle.stroke..strokeWidth = 1.5);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
