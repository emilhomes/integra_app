import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class SilhouettePainter extends CustomPainter {
  const SilhouettePainter();
  
  static Path getSilhouettePath(Size size) {
    final path = Path();
    final double w = size.width;
    final double h = size.height;

    path.addOval(Rect.fromLTWH(w * 0.41, h * 0.02, w * 0.18, h * 0.10));
    path.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.46, h * 0.11, w * 0.08, h * 0.04),
      const Radius.circular(4),
    ));

    final body = Path();
    body.moveTo(w * 0.46, h * 0.15);
    body.quadraticBezierTo(w * 0.35, h * 0.15, w * 0.30, h * 0.18);
    body.quadraticBezierTo(w * 0.22, h * 0.25, w * 0.22, h * 0.45);
    body.quadraticBezierTo(w * 0.25, h * 0.48, w * 0.28, h * 0.45);
    body.quadraticBezierTo(w * 0.28, h * 0.35, w * 0.35, h * 0.25);
    body.quadraticBezierTo(w * 0.33, h * 0.40, w * 0.34, h * 0.55);
    body.quadraticBezierTo(w * 0.32, h * 0.75, w * 0.30, h * 0.95);
    body.quadraticBezierTo(w * 0.37, h * 0.98, w * 0.45, h * 0.95);
    body.quadraticBezierTo(w * 0.46, h * 0.80, w * 0.50, h * 0.65);
    body.quadraticBezierTo(w * 0.54, h * 0.80, w * 0.55, h * 0.95);
    body.quadraticBezierTo(w * 0.63, h * 0.98, w * 0.70, h * 0.95);
    body.quadraticBezierTo(w * 0.68, h * 0.75, w * 0.66, h * 0.55);
    body.quadraticBezierTo(w * 0.67, h * 0.40, w * 0.65, h * 0.25);
    body.quadraticBezierTo(w * 0.72, h * 0.35, w * 0.72, h * 0.45);
    body.quadraticBezierTo(w * 0.75, h * 0.48, w * 0.78, h * 0.45);
    body.quadraticBezierTo(w * 0.78, h * 0.25, w * 0.70, h * 0.18);
    body.quadraticBezierTo(w * 0.65, h * 0.15, w * 0.54, h * 0.15);
    body.close();
    
    path.addPath(body, Offset.zero);
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = getSilhouettePath(size);
    
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
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
