import 'package:flutter/material.dart';
import 'package:hex_toolkit/hex_toolkit.dart';
import 'package:hex_toolkit_demo/components/color_factory.dart';
import 'package:hex_toolkit_demo/generator/world_generator.dart';
import 'package:hex_toolkit_demo/models/demo_settings.dart';
import 'package:hex_toolkit_demo/world/world.dart';

class HeightAnalysisComponent extends StatefulWidget {
  final DemoSettings settings;
  final World world;
  final double width;
  final double height;

  const HeightAnalysisComponent({
    super.key,
    required this.settings,
    required this.world,
    this.width = 300.0,
    this.height = 150.0,
  });

  @override
  State<HeightAnalysisComponent> createState() => _HeightAnalysisComponentState();
}

class _HeightAnalysisComponentState extends State<HeightAnalysisComponent> {
  List<int> _heightGroups = [];
  double _sum = 0;

  int groupingFactor = 100;

  @override
  void initState() {
    super.initState();
    _calculateHeightAnalysis();
  }

  void _calculateHeightAnalysis() {
    _heightGroups = List.filled(groupingFactor, 0);

    // Get hexagons in a spiral pattern
    final hexes = Hex.zero().spiral(30);

    // Calculate the range for each group
    final double amplitude = widget.settings.heightAmplitude;
    final double groupSize = (2 * amplitude) / groupingFactor;

    // Count hexagons in each height group
    for (final hex in hexes) {
      // Get the elevation for this hexagon
      final elevation = widget.world.getHexTopology(hex).elevation;

      // Calculate which group this elevation belongs to
      int groupIndex = ((elevation + amplitude) / groupSize).floor();

      // Increment the count for this group
      _heightGroups[groupIndex]++;
    }

    // Find the maximum count for scaling
    _sum = _heightGroups.reduce((max, count) => count + max).toDouble();

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      child: _buildHeightAnalysisChart(),
    );
  }

  Widget _buildHeightAnalysisChart() {
    if (_heightGroups.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(groupingFactor, (index) {
        // Calculate bar height based on group index (1px to 100px)
        final barHeight = 1 + ((index + 0.5) / groupingFactor) * widget.height;

        final elevation = ((index + 0.5) * (widget.settings.heightAmplitude * 2) / groupingFactor) - widget.settings.heightAmplitude;
        final color = ColorFactory.getHexColor(elevation);

        // Calculate bar width based on count
        double barWidth = (_heightGroups[index] / _sum) * (widget.width - 5);

        return Container(
          width: barWidth,
          height: barHeight,
          color: color,
        );
      }),
    );
  }
}
