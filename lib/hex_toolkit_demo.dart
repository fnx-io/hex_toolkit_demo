import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hex_toolkit/hex_toolkit.dart';
import 'package:hex_toolkit_demo/components/height_analysis_component.dart';
import 'package:hex_toolkit_demo/components/selected_hex_info.dart';
import 'package:hex_toolkit_demo/components/world_viewer.dart';
import 'package:hex_toolkit_demo/components/zoom_controls.dart';
import 'package:hex_toolkit_demo/generator/world.dart';

import 'components/menu_component.dart';

// Static function to be executed in a separate isolate
World _generateWorld(WorldGenerator generator) {
  return generator.generateWorld();
}

class HexToolkitDemo extends StatefulWidget {
  const HexToolkitDemo({super.key});

  @override
  State<HexToolkitDemo> createState() => _HexToolkitDemoState();
}

class _HexToolkitDemoState extends State<HexToolkitDemo> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  SimplexBasedConfig _worldConfig = SimplexBasedConfig.defaultConfig();
  WorldGenerator _worldGenerator = WorldGenerator(config: SimplexBasedConfig.defaultConfig());
  World _world = WorldGenerator(config: SimplexBasedConfig.defaultConfig()).generateWorldPreview();
  Hex? _selectedHex;

  // Scale value for the WorldViewer
  double _scale = 1.0;

  // Min and max scale values
  final double _minScale = 0.5;
  final double _maxScale = 5.0;

  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    // Generate world asynchronously on init
    _generateWorldAsync(_worldConfig);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _handleHexSelected(Hex hex) {
    setState(() {
      _selectedHex = hex;
    });
  }

  // Handle scale up event (increase by 10%)
  void _handleScaleUp() {
    setState(() {
      _scale = (_scale * 1.1).clamp(_minScale, _maxScale);
    });
  }

  // Handle scale down event (decrease by 10%)
  void _handleScaleDown() {
    setState(() {
      _scale = (_scale * 0.9).clamp(_minScale, _maxScale);
    });
  }

  void handleScaleChanged(double newScale) {
    setState(() {
      _scale = newScale.clamp(_minScale, _maxScale);
    });
  }

  void _handleConfigChanged(SimplexBasedConfig config) {
    setState(() {
      _worldConfig = config;
      _worldGenerator = WorldGenerator(config: config);
      _world = _worldGenerator.generateWorldPreview();
    });

    // Debounce the world generation
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _generateWorldAsync(config);
    });

    print('Config updated: $_worldConfig');
  }

  // Function to generate world asynchronously using compute
  Future<void> _generateWorldAsync(SimplexBasedConfig config) async {
    // Generate world in a separate isolate
    final world = await compute(_generateWorld, _worldGenerator);
    if (config != _worldConfig) {
      // If config have changed while the world was being generated, ignore the result
      return;
    }

    // Update state with the new world
    setState(() {
      _world = world;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Check if the screen is wide enough to show the drawer permanently
    final bool isLargeScreen = MediaQuery.of(context).size.width > 1200;

    return Scaffold(
        key: _scaffoldKey,
        // Show app bar with hamburger menu only on small screens
        appBar: isLargeScreen
            ? null
            : AppBar(
                title: const Text('Hex Toolkit Demo'),
                leading: IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () {
                    _scaffoldKey.currentState!.openDrawer();
                  },
                ),
              ),
        // The drawer that will be shown on small screens
        drawer: !isLargeScreen ? MenuComponent(onConfigChanged: _handleConfigChanged) : null,
        body: Row(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Permanent drawer for large screens
            if (isLargeScreen) MenuComponent(permanent: true, onConfigChanged: _handleConfigChanged),
            Expanded(
                child: Stack(
              children: [
                // Main content spanning full width
                Expanded(
                  child: WorldViewer(
                    config: _worldConfig,
                    world: _world,
                    selectedHex: _selectedHex,
                    onHexSelected: _handleHexSelected,
                    onScaleChanged: handleScaleChanged,
                    currentScale: _scale,
                  ),
                ),
                // SizedBox in the bottom right corner
                Positioned(
                  right: 10,
                  bottom: 10,
                  child: HeightAnalysisComponent(
                    config: _worldConfig,
                    world: _world,
                  ),
                ),

                // Zoom controls in the bottom left corner
                Positioned(
                    left: 10,
                    bottom: 10,
                    child: ZoomControls(
                      onScaleUp: _handleScaleUp,
                      onScaleDown: _handleScaleDown,
                    )),

                // Hex info in the top right corner
                Positioned(
                    right: 10,
                    top: 10,
                    child: SelectedHexInfo(
                      selectedHex: _selectedHex,
                      world: _world,
                    )),
              ],
            ))
          ],
        ));
  }
}
