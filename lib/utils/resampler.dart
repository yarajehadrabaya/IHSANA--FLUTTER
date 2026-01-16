import '../models/point_model.dart';

List<DrawPoint> resample(List<DrawPoint> points, double step) {
  if (points.isEmpty) return [];

  List<DrawPoint> result = [];
  double targetT = 0.0;
  int i = 0;
  DrawPoint last = points.first;

  while (targetT <= points.last.t) {
    while (i < points.length - 1 && points[i + 1].t < targetT) {
      i++;
      last = points[i];
    }

    result.add(DrawPoint(
      x: last.x,
      y: last.y,
      nx: last.nx,
      ny: last.ny,
      t: double.parse(targetT.toStringAsFixed(3)),
    ));

    targetT += step;
  }

  return result;
}
