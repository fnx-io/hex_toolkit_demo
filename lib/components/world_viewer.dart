import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:hex_toolkit/hex_toolkit.dart';
import 'package:hex_toolkit_demo/components/color_factory.dart';
import 'package:hex_toolkit_demo/generator/world.dart';

const basicHexSize = 12.0;
const limitHexSize = basicHexSize * 0.6;

class WorldViewer extends StatefulWidget {
  final World world;
  final SimplexBasedConfig config;
  final Hex? selectedHex;
  final Function(Hex) onHexSelected;
  final Function(double) onScaleChanged;
  final double currentScale;

  const WorldViewer({
    Key? key,
    required this.config,
    required this.world,
    this.selectedHex,
    required this.onHexSelected,
    required this.onScaleChanged,
    this.currentScale = 1.0,
  }) : super(key: key);

  @override
  State<WorldViewer> createState() => _WorldViewerState();
}

class _WorldViewerState extends State<WorldViewer> {
  double x = 0;
  double y = 0;

  // Define min and max scale values as class variables
  final double minScale = 0.5;
  final double maxScale = 5.0;
  World get generator => widget.world;
  final TransformationController _transformationController = TransformationController();

  @override
  void initState() {
    super.initState();
    // Initialize scale with the widget's initialScale
    _transformationController.value = Matrix4.identity();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(WorldViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (event) {
        // Calculate the actual position in the world coordinates
        final worldX = x + event.localPosition.dx;
        final worldY = y + event.localPosition.dy;

        // Convert pixel coordinates to hex
        final hexSize = basicHexSize * widget.currentScale;
        final hoveredHex = Hex.fromPixelPoint(PixelPoint(worldX, worldY), hexSize);

        // Call the callback with the hovered hex
        widget.onHexSelected!(hoveredHex);
      },
      child: GestureDetector(
        onScaleUpdate: (details) {
          // Update state during interaction for smoother panning
          setState(() {
            x -= details.focalPointDelta.dx;
            y -= details.focalPointDelta.dy;
            widget.onScaleChanged(details.scale * widget.currentScale);
            var minMax = WorldPainter.minMaxRect(widget.config.size, widget.currentScale);
            // Clamp x and y to keep the view within bounds
            x = x.clamp(minMax.left, minMax.right - MediaQuery.of(context).size.width);
            y = y.clamp(minMax.top, minMax.bottom - MediaQuery.of(context).size.height);
          });
        },
        child: CustomPaint(
          painter: WorldPainter(
            widget.config,
            x,
            y,
            widget.currentScale,
            generator,
            selectedHex: widget.selectedHex,
          ), // Using class variables for consistent scale clamping
          child: Container(),
        ),
      ),
    );
  }
}

class WorldPainter extends CustomPainter {
  final SimplexBasedConfig config;
  final double x;
  final double y;
  final double scale;
  final World world;
  final Hex? selectedHex;

  WorldPainter(this.config, this.x, this.y, this.scale, this.world, {this.selectedHex});

  static Rect minMaxRect(int size, double scale) {
    double hexSize = basicHexSize * scale;
    Hex topLeft = Hex.fromOffset(GridOffset(-size ~/ 2, -size ~/ 2));
    Hex bottomRight = Hex.fromOffset(GridOffset(size ~/ 2, size ~/ 2));
    return Rect.fromPoints(
      Offset(topLeft.centerPoint(hexSize).x, topLeft.centerPoint(hexSize).y),
      Offset(bottomRight.centerPoint(hexSize).x, bottomRight.centerPoint(hexSize).y),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    double hexSize = basicHexSize * scale;
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

    _drawTopology(canvas, hexSize, toDraw());

    _drawRivers(canvas, hexSize, toDraw());

    _drawSelectedHex(canvas, hexSize);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;

  Offset _offset(PixelPoint p) {
    return Offset(p.x, p.y);
  }

  final _waterFlowPaint = Paint()
    ..color = Colors.lightBlue.shade700
    ..strokeWidth = 1.0;

  void _drawWaterFlow(Canvas canvas, double scale, PixelPoint from, PixelPoint to) {
    final fromOffset = asOffset(from);
    final toOffset = asOffset(to);

    final fromOffsetShort = Offset.lerp(fromOffset, toOffset, 0.1)!;
    final toOffsetShort = Offset.lerp(fromOffset, toOffset, 0.9)!;

    // Draw the line
    canvas.drawLine(fromOffsetShort, toOffsetShort, _waterFlowPaint);

    // Calculate the angle of the line
    final angle = (fromOffset - toOffset).direction;

    // Calculate the arrowhead points
    double arrowSize = basicHexSize * scale * 0.5;
    final arrowPoint1 = toOffsetShort + Offset.fromDirection(angle + 0.4, arrowSize);
    final arrowPoint2 = toOffsetShort + Offset.fromDirection(angle - 0.4, arrowSize);

    // Draw the arrowhead
    canvas.drawLine(toOffsetShort, arrowPoint1, _waterFlowPaint);
    canvas.drawLine(toOffsetShort, arrowPoint2, _waterFlowPaint);
  }

  Offset asOffset(PixelPoint p) {
    return Offset(p.x, p.y);
  }

  void _drawTopology(Canvas canvas, double hexSize, Iterable<Hex> toDraw) {
    for (var hex in toDraw) {
      var hexInfo = world.getHexTopology(hex);
      final paint = Paint()
        ..color = ColorFactory.getElevationColor(hexInfo.elevation)
        ..isAntiAlias = true;
      _drawHex(canvas, hex, hexSize, paint);
    }
  }

  void _drawHex(Canvas canvas, Hex hex, double hexSize, Paint paint) {
    if (hexSize >= limitHexSize) {
      var vrts = hex.vertices(hexSize, padding: 0.6).map(asOffset).toList();
      canvas.drawVertices(Vertices(VertexMode.triangleFan, vrts), BlendMode.plus, paint);
    } else {
      // draw as circle
      var center = hex.centerPoint(hexSize);
      canvas.drawCircle(Offset(center.x, center.y), hexSize - 1, paint);
    }
  }

  void _drawRivers(Canvas canvas, double hexSize, Iterable<Hex> toDraw) {
    for (var hex in toDraw) {
      var hexInfo = world.getHexTopology(hex);
      if (!hexInfo.isOcean) {
        HexHydrologyInfo humidityInfo = world.getHexHumidity(hex);
        if (humidityInfo.isRiver) {
          final myCenter = asOffset(hex.centerPoint(hexSize));
          final flowCenter = asOffset(humidityInfo.flowDirection!.centerPoint(hexSize));
          final paint = Paint()
            ..color = Colors.blue
            ..strokeCap = StrokeCap.round
            ..strokeWidth = (humidityInfo.accumulatedHumidity * 0.02 * scale).clamp(1, basicHexSize / 2);
          canvas.drawLine(myCenter, flowCenter, paint);
        }
      }
    }
  }

  final _selectedPaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.0;

  void _drawSelectedHex(Canvas canvas, double hexSize) {
    // Draw selected hex outline if it exists
    if (selectedHex != null) {
      final hexSize = basicHexSize * scale;

      // Draw the outline using the vertices of the selected hex
      final vertices = selectedHex!.vertices(hexSize, padding: 0.6).map(asOffset).toList();

      // Draw the outline by connecting the vertices
      for (int i = 0; i < vertices.length; i++) {
        final start = vertices[i];
        final end = vertices[(i + 1) % vertices.length];
        canvas.drawLine(start, end, _selectedPaint);
      }

      // Draw flowDirection arrows from and to the selected hex
      for (var h in selectedHex!.spiral(2)) {
        var hexHumidity = world.getHexHumidity(h);
        _drawHumidity(canvas, hexHumidity, h.centerPoint(hexSize));
        if (hexHumidity.flowDirection != null) {
          _drawWaterFlow(canvas, scale, h.centerPoint(hexSize), hexHumidity.flowDirection!.centerPoint(hexSize));
        }
      }
    }
  }

  void _drawHumidity(Canvas canvas, HexHydrologyInfo hexHumidity, PixelPoint centerPoint) {
    // Blue circle for humidity
    final humidityPaint = Paint()
      ..color = Colors.lightBlue.shade300.withValues(alpha: 0.5)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.fill;
    final double humidityRadius = (hexHumidity.humidity * scale * basicHexSize).clamp(1, basicHexSize - 1);
    canvas.drawCircle(asOffset(centerPoint), humidityRadius, humidityPaint);
  }
}
