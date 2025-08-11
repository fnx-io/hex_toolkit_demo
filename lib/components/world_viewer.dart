import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:hex_toolkit/hex_toolkit.dart';
import 'package:hex_toolkit_demo/components/color_factory.dart';
import 'package:hex_toolkit_demo/models/demo_settings.dart';
import 'package:hex_toolkit_demo/world/world.dart';

const HEX_SIZE = 12.0;

class WorldViewer extends StatefulWidget {
  final World world;
  final DemoSettings settings;

  const WorldViewer({Key? key, required this.settings, required this.world}) : super(key: key);

  @override
  State<WorldViewer> createState() => _WorldViewerState();
}

class _WorldViewerState extends State<WorldViewer> {
  double x = 0;
  double y = 0;

  double scaleChange = 1.0;
  double currentScale = 1.0;
  double get effectiveScale => (currentScale * scaleChange).clamp(minScale, maxScale);

  // Define min and max scale values as class variables
  final double minScale = 0.5;
  final double maxScale = 5.0;
  World get generator => widget.world;
  final TransformationController _transformationController = TransformationController();

  @override
  void initState() {
    super.initState();
    // Initialize transformation controller with identity matrix
    _transformationController.value = Matrix4.identity();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onScaleUpdate: (details) {
        // Update state during interaction for smoother panning
        setState(() {
          x -= details.focalPointDelta.dx;
          y -= details.focalPointDelta.dy;
          scaleChange = details.scale;
        });
      },
      onScaleEnd: (details) {
        setState(() {
          currentScale = effectiveScale;
          scaleChange = 1.0; // Reset scale change after interaction
        });
      },
      child: CustomPaint(
        painter: WorldPainter(
          widget.settings,
          x,
          y,
          effectiveScale,
          generator,
        ), // Using class variables for consistent scale clamping
        child: Container(),
      ),
    );
  }
}

class WorldPainter extends CustomPainter {
  final DemoSettings settings;
  final double x;
  final double y;
  final double scale;
  final World world;

  WorldPainter(this.settings, this.x, this.y, this.scale, this.world);

  @override
  void paint(Canvas canvas, Size size) {
    double hexSize = HEX_SIZE * scale;
    //if (true) return;

    // Uncomment for debugging
    // print("x: $x, y: $y");

    canvas.save();
    // fill background
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..color = Colors.grey.shade700);
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.translate(-x, -y);

    Offset topLeft = Offset(x, y);
    Offset bottomRight = Offset(x + size.width, y + size.height);

    var topLeftHex = Hex.fromPixelPoint(PixelPoint(topLeft.dx, topLeft.dy), hexSize).cube.toGridOffset();
    var bottomRightHex = Hex.fromPixelPoint(PixelPoint(bottomRight.dx, bottomRight.dy), hexSize).cube.toGridOffset();

    Iterable<Hex> toDraw() sync* {
      for (int hx = topLeftHex.q - 1; hx <= bottomRightHex.q + 1; ++hx) {
        for (int hy = topLeftHex.r - 1; hy <= bottomRightHex.r + 1; ++hy) {
          yield Hex.fromOffset(GridOffset(hx, hy));
        }
      }
    }

    int count = 0;
    for (var hex in toDraw()) {
      count++;
      var hexInfo = world.getHexTopology(hex);
      final paint = Paint()
        ..color = ColorFactory.getHexColor(hexInfo.elevation)
        ..isAntiAlias = false;
      _drawHex(canvas, hex, hexSize, paint);
    }
    for (var hex in toDraw()) {
      var cpaint = Paint()..color = Colors.blue.shade400;
      var hexInfo = world.getHexTopology(hex);
      if (hexInfo.elevation > 0 && false) {
        // HexHumidityInfo humidityInfo = world.getHexHumidity(hex);
        // if (humidityInfo.isRiver) {
        //   final myCenter = asOffset(hex.centerPoint(hexSize));
        //   final flowCenter = asOffset(humidityInfo.flowDirection!.centerPoint(hexSize));
        //   final paint = Paint()
        //     ..color = Colors.blue
        //     ..strokeCap = StrokeCap.round
        //     ..strokeWidth = (humidityInfo.accumulatedHumidity * 0.02 * scale).clamp(1, HEX_SIZE / 2);
        //
        //   canvas.drawLine(myCenter, flowCenter, paint);
        // }
        // //}
      }
    }
    print("Count: $count");
    for (var hex in toDraw()) {
      // var hexInfo = world.getHexTopology(hex);
      // if (hexInfo.elevation > 0) {
      //   var to = world.flowDirectionTarget(hex);
      //   if (to != null) {
      //     _drawArrow(canvas, scale, hex.centerPoint(hexSize), to.centerPoint(hexSize));
      //   }
      // }

      //   var cpaint = Paint()..color = Colors.black;
      //   var vrts = hex.vertices(hexSize, padding: hexSize * 0.5);
      //   canvas.drawVertices(Vertices(VertexMode.triangleFan, vrts.map((e) => Offset(e.x, e.y)).toList()), BlendMode.plus, cpaint);
      // }
      //
      // world.getHexSpecials(hex).forEach((special) {
      //   Iterable<PixelPoint>? vrts;
      //   Paint? paint;
      //   if (special == Special.SWAMP) {
      //     drawSwamp(canvas, _offset(hex.centerPoint(hexSize)), hexSize);
      //   }
      //   if (special == Special.DESERT) {
      //     paint = Paint()..color = ochre;
      //     vrts = hex.vertices(hexSize, padding: 0.6);
      //   }
      //   if (paint != null) {
      //     canvas.drawVertices(Vertices(VertexMode.triangleFan, vrts!.map((e) => Offset(e.x, e.y)).toList()), BlendMode.plus, paint);
      //   }
      // });
    }

    // var paint = Paint()
    //   ..color = colors[OCEAN]
    //   ..strokeCap = StrokeCap.round
    //   ..style = PaintingStyle.stroke
    //   ..strokeWidth = 2;
    //
    // world.rivers.forEach((river) {
    //   for (var i = 0; i < river.length - 1; ++i) {
    //     double stroke = min(8, max(2, (i + 6) / 3));
    //     paint.strokeWidth = stroke;
    //     var o = river[i];
    //     var d = river[i + 1];
    //     var op = _offset(o.centerPoint(hexSize));
    //     var dp = _offset(d.centerPoint(hexSize));
    //
    //     final path = Path()..moveTo(op.dx, op.dy);
    //
    //     // Výpočet středního bodu
    //     final midPoint = Offset((op.dx + dp.dx) / 2, (op.dy + dp.dy) / 2);
    //
    //     // Malá odchylka pro mírné zvlnění
    //     final deviation = 2; //(op.dx.round() % 5) + 5.0; // Můžete experimentovat s touto hodnotou
    //
    //     // Vypočet kontrolních bodů
    //     final controlPoint1 = Offset(midPoint.dx - deviation, midPoint.dy - deviation);
    //     final controlPoint2 = Offset(midPoint.dx + deviation, midPoint.dy + deviation);
    //
    //     path.cubicTo(controlPoint1.dx, controlPoint1.dy, controlPoint2.dx, controlPoint2.dy, dp.dx, dp.dy);
    //
    //     canvas.drawPath(path, paint);
    //     // curve line little bit
    //     // canvas.drawLine(op, dp, paint);
    //   }
    // });
    //
    // paint
    //   ..color = Colors.black
    //   ..strokeWidth = 2;
    // world.roads.forEach((road) {
    //   for (var i = 0; i < road.length - 1; ++i) {
    //     var o = road[i];
    //     var d = road[i + 1];
    //     var op = _offset(o.centerPoint(hexSize));
    //     var dp = _offset(d.centerPoint(hexSize));
    //     canvas.drawLine(op, dp, paint);
    //   }
    // });

    canvas.restore();
  }

  void drawSwamp(Canvas c, Offset s, double r) {
    final paint = Paint()
      ..color = Colors.blue.shade600
      ..strokeWidth = 2.0;

    final double maxLength = r * 0.6; // maximální délka čárek

    // Seznam začátků a konců čárek
    List<Offset> starts = [
      Offset(s.dx - maxLength / 2, s.dy - r / 2),
      Offset(s.dx + maxLength / 3, s.dy - r / 3),
      Offset(s.dx - maxLength, s.dy - r / 4),
      Offset(s.dx - maxLength * 1.2, s.dy),
      Offset(s.dx + maxLength / 3, s.dy),
      Offset(s.dx - maxLength, s.dy + r / 4),
      Offset(s.dx + maxLength / 6, s.dy + r / 3),
      Offset(s.dx - maxLength / 2, s.dy + r / 2),
    ];

    for (int i = 0; i < starts.length; i++) {
      Offset start = starts[i];
      c.drawLine(start, Offset(start.dx + maxLength, start.dy), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;

  Offset _offset(PixelPoint p) {
    return Offset(p.x, p.y);
  }

  void _drawArrow(Canvas canvas, double scale, PixelPoint from, PixelPoint to) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1.0;

    final fromOffset = asOffset(from);
    final toOffset = asOffset(to);

    final fromOffsetShort = Offset.lerp(fromOffset, toOffset, 0.2)!;
    final toOffsetShort = Offset.lerp(fromOffset, toOffset, 0.8)!;

    // Draw the line
    canvas.drawLine(fromOffsetShort, toOffsetShort, paint);

    // Calculate the angle of the line
    final angle = (fromOffset - toOffset).direction;

    // Calculate the arrowhead points
    double arrowSize = HEX_SIZE * scale * 0.4;
    final arrowPoint1 = toOffsetShort + Offset.fromDirection(angle + 0.3, arrowSize);
    final arrowPoint2 = toOffsetShort + Offset.fromDirection(angle - 0.3, arrowSize);

    // Draw the arrowhead
    canvas.drawLine(toOffsetShort, arrowPoint1, paint);
    canvas.drawLine(toOffsetShort, arrowPoint2, paint);
  }

  Offset asOffset(PixelPoint p) {
    return Offset(p.x, p.y);
  }

  void _drawHex(Canvas canvas, Hex hex, double hexSize, Paint paint) {
    if (hexSize >= HEX_SIZE) {
      var vrts = hex.vertices(hexSize, padding: 0.6).map(asOffset).toList();
      canvas.drawVertices(Vertices(VertexMode.triangleFan, vrts), BlendMode.plus, paint);
    } else {
      // draw as circle
      var center = hex.centerPoint(hexSize);
      canvas.drawCircle(Offset(center.x, center.y), hexSize - 1, paint);
    }
  }
}
