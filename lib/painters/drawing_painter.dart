import 'package:flutter/material.dart';
import '../models/point_model.dart';
import 'dart:ui' as ui;


class DrawingPainter extends CustomPainter {
  final List<DrawPoint> points;
  final ui.Image bgImage;

  DrawingPainter(this.points, this.bgImage);

  @override
  void paint(Canvas canvas, Size size) {
    // background
    canvas.drawImageRect(
      bgImage,
      Rect.fromLTWH(0, 0, bgImage.width.toDouble(), bgImage.height.toDouble()),
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint(),
    );

    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < points.length - 1; i++) {
      canvas.drawLine(
        Offset(points[i].x, points[i].y),
        Offset(points[i + 1].x, points[i + 1].y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
