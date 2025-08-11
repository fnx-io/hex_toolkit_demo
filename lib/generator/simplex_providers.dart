// type: noiseProvider

import 'package:hex_toolkit/hex_toolkit.dart';
import 'package:hex_toolkit_demo/generator/cubic_bezier_easing.dart';
import 'package:hex_toolkit_demo/generator/open_simplex_2f.dart';
import 'package:hex_toolkit_demo/models/demo_settings.dart';

typedef HexValueProvider = double Function(Hex hex);

class SimplexProvider {
  final DemoSettings settings;
  final OpenSimplex2F primaryElevationGenerator;
  final OpenSimplex2F secondaryElevationGenerator;
  final OpenSimplex2F tertiaryElevationGenerator;
  final OpenSimplex2F humidityGenerator;
  late CubicBezierEasing bezier;

  SimplexProvider(this.settings)
      : primaryElevationGenerator = OpenSimplex2F(settings.seedHash),
        secondaryElevationGenerator = OpenSimplex2F(settings.seedHash ^ 3),
        tertiaryElevationGenerator = OpenSimplex2F(settings.seedHash ^ 7),
        humidityGenerator = OpenSimplex2F(settings.seedHash ^ 5);

  double calculateBaseAltitude(Hex hex) {
    var bezier = CubicBezierEasing(.39, .68, .31, .27);
    double x = hex.centerPoint(1).x;
    double y = hex.centerPoint(1).y;

    // Use OpenSimplex noise for more natural terrain generation
    // Primary noise for large features
    double primaryNoise = primaryElevationGenerator.noise2(
      2 * x * settings.primaryElevationFrequency,
      y * settings.primaryElevationFrequency,
    );

    // Secondary noise for smaller details
    double secondaryNoise = secondaryElevationGenerator.noise2(
      2 * x * settings.secondaryElevationFrequency,
      y * settings.secondaryElevationFrequency,
    );

    // Tertiary noise for finest details
    double tertiaryNoise = tertiaryElevationGenerator.noise2(
      x * settings.tertiaryElevationFrequency,
      y * settings.tertiaryElevationFrequency,
    );

    // Combine noise values and scale to desired elevation range
    double noise = (settings.primaryElevationWeight * primaryNoise +
            settings.secondaryElevationWeight * secondaryNoise +
            settings.tertiaryElevationWeight * tertiaryNoise) /
        (settings.primaryElevationWeight + settings.secondaryElevationWeight + settings.tertiaryElevationWeight);

    noise = bezier.transformNoise(noise);

    return noise * settings.heightAmplitude;
  }
}
