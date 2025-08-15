import 'package:flutter/material.dart';
import 'package:hex_toolkit/hex_toolkit.dart';
import 'package:hex_toolkit_demo/generator/world.dart';

class SelectedHexInfo extends StatelessWidget {
  final Hex? selectedHex;
  final World world;

  const SelectedHexInfo({
    Key? key,
    required this.selectedHex,
    required this.world,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (selectedHex == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.black26,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Selected Hex Info',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Topology:',
            style: TextStyle(color: Colors.white70),
          ),
          _buildTopologyInfo(selectedHex!),
          const SizedBox(height: 4),
          const Text(
            'Humidity:',
            style: TextStyle(color: Colors.white70),
          ),
          _buildHumidityInfo(selectedHex!),
        ],
      ),
    );
  }

  // Helper method to build topology information widget
  Widget _buildTopologyInfo(Hex hex) {
    final topology = world.getHexTopology(hex);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Elevation: ${topology.elevation.toStringAsFixed(2)}',
          style: const TextStyle(color: Colors.white),
        ),
        Text(
          'Type: ${topology.isOcean ? "Ocean" : "Land"}',
          style: const TextStyle(color: Colors.white),
        ),
      ],
    );
  }

  // Helper method to build humidity information widget
  Widget _buildHumidityInfo(Hex hex) {
    final humidity = world.getHexHumidity(hex);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Humidity: ${humidity.humidity.toStringAsFixed(2)}',
          style: const TextStyle(color: Colors.white),
        ),
        Text(
          'Accumulated: ${humidity.accumulatedHumidity.toStringAsFixed(2)}',
          style: const TextStyle(color: Colors.white),
        ),
        Text(
          'Is River: ${humidity.isRiver ? "Yes" : "No"}',
          style: const TextStyle(color: Colors.white),
        ),
        if (humidity.flowDirection != null)
          Text(
            'Flow Direction: ${humidity.flowDirection.toString()}',
            style: const TextStyle(color: Colors.white),
          ),
      ],
    );
  }
}
