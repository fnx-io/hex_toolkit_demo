part of 'world.dart';

/// Function type for providing hex-based values.
///
/// Used for elevation and humidity calculations.
typedef HexValueProvider = double Function(Hex hex);

/// Provides Simplex noise-based terrain and humidity generation.
///
/// Uses multiple layers of Simplex noise to create natural-looking
/// terrain with various levels of detail.
class SimplexBasedProviders {
  /// Settings that control the noise generation.
  final SimplexBasedConfig settings;

  /// Random number generator seeded with the world seed.
  final Random random;

  /// Rotation value derived from the seed to add variety.
  final int rotation;

  /// Generator for large-scale terrain features (continets).
  final OpenSimplex2F primaryElevationGenerator;

  /// Generator for medium-scale terrain details (mountains, hills).
  final OpenSimplex2F secondaryElevationGenerator;

  /// Generator for fine-scale terrain details (roughness, small variations).
  final OpenSimplex2F tertiaryElevationGenerator;

  /// Generator for humidity distribution.
  final OpenSimplex2F humidityGenerator;

  /// Easing function for noise transformation.
  late CubicBezierEasing bezier;

  /// Creates a new provider with the specified settings.
  ///
  /// Initializes all noise generators with different hash values
  /// derived from the seed to ensure they produce different patterns.
  SimplexBasedProviders(this.settings)
      : primaryElevationGenerator = OpenSimplex2F(settings.seedHash),
        secondaryElevationGenerator = OpenSimplex2F(settings.seedHash ^ 3),
        tertiaryElevationGenerator = OpenSimplex2F(settings.seedHash ^ 7),
        humidityGenerator = OpenSimplex2F(settings.seedHash ^ 5),
        random = Random(settings.seedHash),
        rotation = settings.seedHash % 6;

  /// Calculates the base altitude for a given hex.
  ///
  /// Uses multiple layers of Simplex noise to generate natural-looking terrain:
  /// - Primary noise for large-scale features (continents)
  /// - Secondary noise for medium-scale details (mountains, hills)
  /// - Tertiary noise for fine-scale details (roughness, small variations)
  ///
  /// The noise values are combined with weights and transformed using a bezier curve
  /// to create more interesting terrain distributions.
  ///
  /// Returns the calculated elevation value.
  double calculateBaseAltitude(Hex hex) {
    var bezier = CubicBezierEasing(.39, .68, .31, .27);

    // Apply rotation for variety based on seed
    var hex2 = hex.rotateAround(Hex.zero(), rotation);

    double x = hex2.centerPoint(1).x;
    double y = hex2.centerPoint(1).y;

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

    // Apply bezier transformation for more interesting distribution
    noise = bezier.transformNoise(noise);

    return noise * settings.heightAmplitude;
  }

  /// Calculates the base humidity for a given hex.
  ///
  /// Uses Simplex noise to generate a natural-looking humidity distribution.
  /// The resulting value is normalized to the range [0, 1], where:
  /// - 0 represents completely dry
  /// - 1 represents maximum humidity
  ///
  /// Returns the calculated humidity value.
  double calculateBaseHumidity(Hex hex) {
    double x = hex.centerPoint(1).x;
    double y = hex.centerPoint(1).y;

    // Use OpenSimplex noise for humidity generation
    // Normalize from [-1, 1] to [0, 1] range
    return ((humidityGenerator.noise2(
              x * settings.humidityFrequency,
              y * settings.humidityFrequency,
            ) +
            1) /
        2);
  }
}
