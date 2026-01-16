class DrawPoint {
  final double x;
  final double y;
  final double nx;
  final double ny;
  final double t;

  DrawPoint({
    required this.x,
    required this.y,
    required this.nx,
    required this.ny,
    required this.t,
  });

  Map<String, dynamic> toJson() => {
        "x": x,
        "y": y,
        "nx": nx,
        "ny": ny,
        "t": t,
      };
}
