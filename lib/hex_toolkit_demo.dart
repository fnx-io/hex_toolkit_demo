import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hex_toolkit_demo/components/height_analysis_component.dart';
import 'package:hex_toolkit_demo/components/world_viewer.dart';
import 'package:hex_toolkit_demo/generator/world_generator.dart';
import 'package:hex_toolkit_demo/models/demo_settings.dart';
import 'package:hex_toolkit_demo/world/world.dart';

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
  DemoSettings _worldSettings = DemoSettings.defaultSettings();
  WorldGenerator _worldGenerator = WorldGenerator.fromSettings(DemoSettings.defaultSettings());
  World _world = WorldGenerator.fromSettings(DemoSettings.defaultSettings()).generateWorldPreview();

  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    // Generate world asynchronously on init
    _generateWorldAsync(_worldSettings);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _handleSettingsChanged(DemoSettings settings) {
    setState(() {
      _worldSettings = settings;
      _worldGenerator = WorldGenerator.fromSettings(settings);
      _world = _worldGenerator.generateWorldPreview();
    });

    // Debounce the world generation
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _generateWorldAsync(settings);
    });

    print('Settings updated: $_worldSettings');
  }

  // Function to generate world asynchronously using compute
  Future<void> _generateWorldAsync(DemoSettings settings) async {
    // Generate world in a separate isolate
    final world = await compute(_generateWorld, _worldGenerator);
    if (settings != _worldSettings) {
      // If settings have changed while the world was being generated, ignore the result
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
      drawer: !isLargeScreen
          ? MenuComponent(
              onSettingsChanged: _handleSettingsChanged,
            )
          : null,
      body: Stack(
        children: [
          // Main content spanning full width
          Row(
            children: [
              // Permanent drawer for large screens
              if (isLargeScreen)
                MenuComponent(
                  permanent: true,
                  onSettingsChanged: _handleSettingsChanged,
                ),
              // Main content area
              Expanded(child: WorldViewer(settings: _worldSettings, world: _world)),
            ],
          ),

          // SizedBox in the bottom right corner
          Positioned(
              right: 10,
              bottom: 10,
              child: Container(
                padding: EdgeInsets.all(8),
                color: Colors.black26,
                child: HeightAnalysisComponent(
                  settings: _worldSettings,
                  world: _world!,
                ),
              )),
        ],
      ),
    );
  }
}
