import 'dart:convert';
import 'dart:ui' as ui;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/point_model.dart';
import '../painters/drawing_painter.dart';
import '../utils/resampler.dart';

class TmtTestPage extends StatefulWidget {
  const TmtTestPage({super.key});

  @override
  State<TmtTestPage> createState() => _TmtTestPageState();
}

class _TmtTestPageState extends State<TmtTestPage> {
  List<DrawPoint> points = [];
  DateTime? startTime;
  ui.Image? bgImage;

  @override
  void initState() {
    super.initState();
    loadImage();
  }

  Future<void> loadImage() async {
    final data = await DefaultAssetBundle.of(context)
        .load('assets/images/moca.png');
    final img = await decodeImageFromList(data.buffer.asUint8List());
    setState(() => bgImage = img);
  }

  void startDraw(Offset pos, Size size) {
    startTime ??= DateTime.now();
    addPoint(pos, size);
  }

  void addPoint(Offset pos, Size size) {
    final t =
        DateTime.now().difference(startTime!).inMilliseconds / 1000.0;

    points.add(DrawPoint(
      x: pos.dx,
      y: pos.dy,
      nx: pos.dx / size.width,
      ny: pos.dy / size.height,
      t: t,
    ));

    setState(() {});
  }

  // 🔥 الدالة الجديدة: حفظ + تنزيل + فتح JSON
 Future<void> saveAndOpenJson(Size canvasSize) async {
  await Permission.storage.request();

  final resampled = resample(points, 0.05);

  final mediaQuery = MediaQuery.of(context);
  final screenWidth = mediaQuery.size.width;
  final screenHeight = mediaQuery.size.height;

  final data = {
    "screenWidth": screenWidth,
    "screenHeight": screenHeight,
    "canvasWidth": canvasSize.width,
    "canvasHeight": canvasSize.height,
    "points": resampled.map((e) => e.toJson()).toList(),
  };

  final file = File(
    '/storage/emulated/0/Download/'
    'trial_${DateTime.now().millisecondsSinceEpoch}_data.json',
  );

  await file.writeAsString(
    const JsonEncoder.withIndent('  ').convert(data),
  );

  await OpenFilex.open(file.path);
}


  @override
  Widget build(BuildContext context) {
    if (bgImage == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("TMT - MoCA")),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final size =
              Size(constraints.maxWidth, constraints.maxHeight * 0.8);

          return Column(
            children: [
              GestureDetector(
                onPanStart: (d) => startDraw(d.localPosition, size),
                onPanUpdate: (d) => addPoint(d.localPosition, size),
                child: CustomPaint(
                  size: size,
                  painter: DrawingPainter(points, bgImage!),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () => setState(() {
                      points.clear();
                      startTime = null;
                    }),
                    child: const Text("إعادة"),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () => saveAndOpenJson(size),
                    child: const Text("حفظ JSON"),
                  ),
                ],
              )
            ],
          );
        },
      ),
    );
  }
}
