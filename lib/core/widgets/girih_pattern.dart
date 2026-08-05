import 'dart:math' as math;

import 'package:flutter/material.dart';

/// زخرفة هندسية إسلامية (نجمة ثمانية متشابكة) تُرسم برمجياً.
///
/// **لماذا رسم لا صورة:** الصورة تحتاج ملفاً وذاكرة وفكّ ترميز عند كل عرض،
/// أما المسار الهندسي فيُبنى مرة ويُرسم على الـGPU بتكلفة تكاد لا تُذكر.
/// وهي داخل [RepaintBoundary] فلا يُعاد رسمها مع كل إطار.
///
/// تُستخدم بشفافية منخفضة جداً كعلامة مائية خلف كارت المبلغ الكلي: العين
/// لا تراها بوضوح لكنها تكسر فراغ السطح المسطّح وتمنح الكارت إحساس
/// السطح المصنوع بدل المستطيل الفارغ.
class GirihPattern extends StatelessWidget {
  const GirihPattern({
    super.key,
    this.color = Colors.white,
    this.opacity = 0.045,
    this.cell = 62,
    this.strokeWidth = 1.0,
  });

  final Color color;
  final double opacity;

  /// طول ضلع الوحدة المتكررة بالبكسل
  final double cell;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _GirihPainter(
          color: color.withValues(alpha: opacity),
          cell: cell,
          strokeWidth: strokeWidth,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _GirihPainter extends CustomPainter {
  _GirihPainter({
    required this.color,
    required this.cell,
    required this.strokeWidth,
  });

  final Color color;
  final double cell;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..isAntiAlias = true;

    final path = Path();
    final cols = (size.width / cell).ceil() + 1;
    final rows = (size.height / cell).ceil() + 1;

    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final cx = c * cell;
        final cy = r * cell;
        _addOctagram(path, Offset(cx, cy), cell * 0.5);
        // نجمة صغيرة في مركز كل أربع نجوم فتتكوّن شبكة متشابكة
        _addOctagram(
          path,
          Offset(cx + cell / 2, cy + cell / 2),
          cell * 0.22,
        );
      }
    }
    canvas.drawPath(path, paint);
  }

  /// نجمة ثمانية: مضلّعان مربّعان متراكبان بزاوية ٤٥ درجة
  void _addOctagram(Path path, Offset center, double radius) {
    const points = 8;
    for (var k = 0; k < 2; k++) {
      final rotation = k * math.pi / points;
      for (var i = 0; i <= 4; i++) {
        final angle = rotation + i * (2 * math.pi / 4);
        final p = Offset(
          center.dx + radius * math.cos(angle),
          center.dy + radius * math.sin(angle),
        );
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      path.close();
    }
  }

  @override
  bool shouldRepaint(_GirihPainter old) =>
      old.color != color || old.cell != cell || old.strokeWidth != strokeWidth;
}
