import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:hex_toolkit_demo/generator/world.dart';

import '../utils/seed_generator.dart';

class MenuComponent extends StatefulWidget {
  final bool permanent;
  final Function(SimplexBasedConfig) onConfigChanged;

  const MenuComponent({
    Key? key,
    this.permanent = false,
    required this.onConfigChanged,
  }) : super(key: key);

  @override
  State<MenuComponent> createState() => _MenuComponentState();
}

class _MenuComponentState extends State<MenuComponent> {
  // Current config values
  late double _primaryElevationFrequency;
  late double _secondaryElevationFrequency;
  late double _tertiaryElevationFrequency;
  late double _humidityFrequency;

  late double _primaryElevationWeight;
  late double _secondaryElevationWeight;
  late double _tertiaryElevationWeight;

  late double _heightAmplitude;

  late double _riverTrashold; // Threshold for river formation

  late String _seed; // Seed for noise generators
  final TextEditingController _seedController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize with default config
    final defaultConfig = SimplexBasedConfig.defaultConfig();
    _primaryElevationFrequency = defaultConfig.primaryElevationFrequency;
    _secondaryElevationFrequency = defaultConfig.secondaryElevationFrequency;
    _tertiaryElevationFrequency = defaultConfig.tertiaryElevationFrequency;
    _humidityFrequency = defaultConfig.humidityFrequency;

    _primaryElevationWeight = defaultConfig.primaryElevationWeight;
    _secondaryElevationWeight = defaultConfig.secondaryElevationWeight;
    _tertiaryElevationWeight = defaultConfig.tertiaryElevationWeight;

    _heightAmplitude = defaultConfig.heightAmplitude;

    _riverTrashold = defaultConfig.riverTrashold;

    _seed = defaultConfig.seed;
    _seedController.text = _seed;
  }

  @override
  void dispose() {
    _seedController.dispose();
    super.dispose();
  }

  // Update config and notify parent
  void _updateConfig() {
    final config = SimplexBasedConfig(
      primaryElevationFrequency: _primaryElevationFrequency,
      secondaryElevationFrequency: _secondaryElevationFrequency,
      tertiaryElevationFrequency: _tertiaryElevationFrequency,
      humidityFrequency: _humidityFrequency,
      primaryElevationWeight: _primaryElevationWeight,
      secondaryElevationWeight: _secondaryElevationWeight,
      tertiaryElevationWeight: _tertiaryElevationWeight,
      heightAmplitude: _heightAmplitude,
      riverTrashold: _riverTrashold,
      seed: _seed,
    );
    widget.onConfigChanged(config);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.topLeft,
      width: 240, // Reduced from 300 for more condensed UI
      color: Colors.grey[200],
      child: widget.permanent
          ? _buildMenuContent()
          : Drawer(
              child: _buildMenuContent(),
            ),
    );
  }

  Widget _buildMenuContent() {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(4.0), // Reduced from 8.0 for more condensed UI
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          children: [
            // Elevation Frequency Fieldset
            _buildFieldset(
              'Elevation Frequency',
              [
                _buildSlider(
                  'Primary',
                  _primaryElevationFrequency,
                  0.001,
                  0.001 * 20,
                  onChanged: (value) {
                    setState(() {
                      _primaryElevationFrequency = value;
                      _updateConfig();
                    });
                  },
                ),
                _buildSlider(
                  'Secondary',
                  _secondaryElevationFrequency,
                  0.005,
                  0.005 * 20,
                  onChanged: (value) {
                    setState(() {
                      _secondaryElevationFrequency = value;
                      _updateConfig();
                    });
                  },
                ),
                _buildSlider(
                  'Tertiary',
                  _tertiaryElevationFrequency,
                  0.05,
                  0.05 * 20,
                  onChanged: (value) {
                    setState(() {
                      _tertiaryElevationFrequency = value;
                      _updateConfig();
                    });
                  },
                ),
              ],
            ),

            const SizedBox(height: 10), // Reduced from 20 for more condensed UI

            // Elevation Weight Fieldset
            _buildFieldset(
              'Elevation Weight',
              [
                _buildSlider(
                  'Primary',
                  _primaryElevationWeight,
                  0.0,
                  1.0,
                  divisions: 20,
                  onChanged: (value) {
                    setState(() {
                      _primaryElevationWeight = value;
                      _updateConfig();
                    });
                  },
                ),
                _buildSlider(
                  'Secondary',
                  _secondaryElevationWeight,
                  0.0,
                  0.5,
                  divisions: 20,
                  onChanged: (value) {
                    setState(() {
                      _secondaryElevationWeight = value;
                      _updateConfig();
                    });
                  },
                ),
                _buildSlider(
                  'Tertiary',
                  _tertiaryElevationWeight,
                  0.0,
                  0.2,
                  divisions: 20,
                  onChanged: (value) {
                    setState(() {
                      _tertiaryElevationWeight = value;
                      _updateConfig();
                    });
                  },
                ),
              ],
            ),

            const SizedBox(height: 10), // Reduced from 20 for more condensed UI

            // Height Amplitude Fieldset
            _buildFieldset(
              'Height Amplitude',
              [
                _buildSlider(
                  'Height',
                  _heightAmplitude,
                  500.0,
                  500.0 * 20,
                  onChanged: (value) {
                    setState(() {
                      _heightAmplitude = value;
                      _updateConfig();
                    });
                  },
                ),
              ],
            ),

            const SizedBox(height: 10), // Reduced from 20 for more condensed UI

            // River Threshold Fieldset
            _buildFieldset(
              'River Formation',
              [
                _buildSlider(
                  'Threshold',
                  _riverTrashold,
                  5.0,
                  100.0,
                  divisions: 19,
                  onChanged: (value) {
                    setState(() {
                      _riverTrashold = value;
                      _updateConfig();
                    });
                  },
                ),
              ],
            ),

            const SizedBox(height: 10), // Reduced from 20 for more condensed UI

            // Seed Fieldset
            _buildFieldset(
              'Seed',
              [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _seedController,
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          border: OutlineInputBorder(),
                          hintText: 'Enter seed',
                        ),
                        onChanged: (value) {
                          setState(() {
                            _seed = value;
                            _updateConfig();
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.refresh_sharp),
                      tooltip: 'Generate random seed',
                      onPressed: () {
                        final randomSeed = SeedGenerator.generateRandomSeed();
                        setState(() {
                          _seed = randomSeed;
                          _seedController.text = randomSeed;
                          _updateConfig();
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 10), // Reduced from 20 for more condensed UI

            // Reset to Default Button
            ElevatedButton(
              onPressed: () {
                final defaultConfig = SimplexBasedConfig.defaultConfig();
                setState(() {
                  _primaryElevationFrequency = defaultConfig.primaryElevationFrequency;
                  _secondaryElevationFrequency = defaultConfig.secondaryElevationFrequency;
                  _tertiaryElevationFrequency = defaultConfig.tertiaryElevationFrequency;
                  _humidityFrequency = defaultConfig.humidityFrequency;

                  _primaryElevationWeight = defaultConfig.primaryElevationWeight;
                  _secondaryElevationWeight = defaultConfig.secondaryElevationWeight;
                  _tertiaryElevationWeight = defaultConfig.tertiaryElevationWeight;

                  _heightAmplitude = defaultConfig.heightAmplitude;

                  _riverTrashold = defaultConfig.riverTrashold;

                  _seed = defaultConfig.seed;
                  _seedController.text = _seed;

                  _updateConfig();
                });
              },
              child: const Text('Reset to Default Config'),
            ),
          ],
        ),
      ),
    );
  }

  // Reduced spacing for more condensed UI
  Widget _buildFieldset(String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(5),
      ),
      padding: const EdgeInsets.all(6), // Reduced from 10 for more condensed UI
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14, // Reduced from 16 for more condensed UI
            ),
          ),
          const SizedBox(height: 6), // Reduced from 10 for more condensed UI
          ...children,
        ],
      ),
    );
  }

  Widget _buildSlider(
    String label,
    double value,
    double min,
    double max, {
    required Function(double) onChanged,
    int divisions = 19,
  }) {
    // Calculate the number of divisions based on the step size

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text(value.toStringAsFixed(4)),
          ],
        ),
        Slider(
          value: clampDouble(value, min, max),
          min: min, // Adjusted to avoid exact min/max values
          max: max,
          divisions: divisions,
          onChanged: (v) => onChanged(clampDouble(v, min, max)),
        ),
        const SizedBox(height: 4), // Reduced from 10 for more condensed UI
      ],
    );
  }
}
