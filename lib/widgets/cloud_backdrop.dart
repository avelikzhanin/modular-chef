import 'package:flutter/material.dart';

/// Рисованное мягкое тёплое «небо» с облаками (без генерации) для шапок.
/// Несколько размытых овалов поверх тёплого градиента — живописно, не плоско.
class CloudPainter extends CustomPainter {
  const CloudPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    void cloud(double cx, double cy, double rw, double rh, Color c, double blur) {
      final paint = Paint()
        ..color = c
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, cy), width: rw, height: rh),
        paint,
      );
    }

    // акварельные «облака»: тёплые белила + персик/блаш, мягкий свет сверху
    cloud(w * 0.80, h * 0.10, w * 0.85, h * 0.55, const Color(0x59FFF9F2), 26);
    cloud(w * 0.18, h * 0.04, w * 0.70, h * 0.45, const Color(0x40FFFFFF), 24);
    cloud(w * 0.55, h * 0.34, w * 1.00, h * 0.55, const Color(0x26F2C9A8), 30);
    cloud(w * 0.92, h * 0.50, w * 0.55, h * 0.40, const Color(0x21E8A87C), 28);
  }

  @override
  bool shouldRepaint(CloudPainter oldDelegate) => false;
}
