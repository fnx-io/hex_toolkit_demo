part of 'world.dart';

/// Configuration settings for Simplex noise-based world generation.
///
/// Controls various aspects of terrain and humidity generation, including
/// frequencies, weights, amplitude, and world size.
/// Implements [WorldGeneratorConfig] to provide the required properties for world generation.
class SimplexBasedConfig implements WorldGeneratorConfig {
  /// Frequency of the primary (large-scale) elevation noise.
  /// Lower values create larger, smoother features.
  final double primaryElevationFrequency;

  /// Frequency of the secondary (medium-scale) elevation noise.
  /// Controls medium-sized terrain features.
  final double secondaryElevationFrequency;

  /// Frequency of the tertiary (small-scale) elevation noise.
  /// Controls fine details in the terrain.
  final double tertiaryElevationFrequency;

  /// Frequency of the humidity noise.
  /// Controls the distribution pattern of humidity.
  final double humidityFrequency;

  /// Weight of the primary elevation noise in the final terrain.
  /// Higher values give more prominence to large-scale features.
  final double primaryElevationWeight;

  /// Weight of the secondary elevation noise in the final terrain.
  /// Higher values give more prominence to medium-scale features.
  final double secondaryElevationWeight;

  /// Weight of the tertiary elevation noise in the final terrain.
  /// Higher values give more prominence to fine details.
  final double tertiaryElevationWeight;

  /// Overall amplitude (height range) of the terrain.
  /// Higher values create more extreme elevation differences.
  final double heightAmplitude;

  /// Seed string for world generation.
  /// Different seeds produce different worlds.
  final String seed;

  /// Hash code of the seed, used for random number generation.
  int get seedHash => seed.hashCode;

  /// Size of the world in hexes (approximate radius).
  final int size;

  /// Threshold value for river formation based on accumulated humidity.
  final double riverTrashold;

  late SimplexBasedProviders _providers;

  /// Creates a new settings instance with the specified parameters.
  ///
  /// All parameters have default values that produce a balanced, natural-looking world.
  /// These can be adjusted to create different types of terrain.
  SimplexBasedConfig({
    this.primaryElevationFrequency = 0.003,
    this.secondaryElevationFrequency = 0.05,
    this.tertiaryElevationFrequency = 0.4,
    this.humidityFrequency = 0.02,
    this.primaryElevationWeight = 0.5,
    this.secondaryElevationWeight = 0.10,
    this.tertiaryElevationWeight = 0.03,
    this.heightAmplitude = 5000.0,
    this.seed = "terra-incognita",
    this.size = 250,
    this.riverTrashold = 20,
  }) {
    _providers = SimplexBasedProviders(this);
  }

  /// Function that determines elevation for each hex.
  ///
  /// Uses a [SimplexBasedProviders] instance to calculate the elevation.
  @override
  HexValueProvider get elevationProvider {
    return _providers.calculateBaseAltitude;
  }

  /// Function that determines humidity for each hex.
  ///
  /// Uses a [SimplexBasedProviders] instance to calculate the humidity.
  @override
  HexValueProvider get humidityProvider {
    return _providers.calculateBaseHumidity;
  }

  /// Creates a settings instance with default values.
  ///
  /// Convenience factory method for creating settings with default parameters.
  static SimplexBasedConfig defaultConfig() {
    return SimplexBasedConfig();
  }

  @override

  /// Returns a string representation of the settings.
  ///
  /// Useful for debugging and logging.
  String toString() {
    return 'SimplexBasedConfig{primaryElevationFrequency: $primaryElevationFrequency, secondaryElevationFrequency: $secondaryElevationFrequency, tertiaryElevationFrequency: $tertiaryElevationFrequency, humidityFrequency: $humidityFrequency, primaryElevationWeight: $primaryElevationWeight, secondaryElevationWeight: $secondaryElevationWeight, tertiaryElevationWeight: $tertiaryElevationWeight, heightAmplitude: $heightAmplitude}';
  }
}
