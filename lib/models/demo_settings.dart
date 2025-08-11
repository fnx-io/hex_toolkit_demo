class DemoSettings {
  final double primaryElevationFrequency;
  final double secondaryElevationFrequency;
  final double tertiaryElevationFrequency;
  final double humidityFrequency;

  final double primaryElevationWeight;
  final double secondaryElevationWeight;
  final double tertiaryElevationWeight;

  final double heightAmplitude;

  final String seed;
  int get seedHash => seed.hashCode;

  final int worldSize;

  DemoSettings({
    this.primaryElevationFrequency = 0.003,
    this.secondaryElevationFrequency = 0.03,
    this.tertiaryElevationFrequency = 0.3,
    this.humidityFrequency = 0.2,
    this.primaryElevationWeight = 0.5,
    this.secondaryElevationWeight = 0.15,
    this.tertiaryElevationWeight = 0.05,
    this.heightAmplitude = 5000.0,
    this.seed = "terra-incognita",
    this.worldSize = 200,
  });

  static DemoSettings defaultSettings() {
    return DemoSettings();
  }

  @override
  String toString() {
    return 'WorldSettings{primaryElevationFrequency: $primaryElevationFrequency, secondaryElevationFrequency: $secondaryElevationFrequency, tertiaryElevationFrequency: $tertiaryElevationFrequency, humidityFrequency: $humidityFrequency, primaryElevationWeight: $primaryElevationWeight, secondaryElevationWeight: $secondaryElevationWeight, tertiaryElevationWeight: $tertiaryElevationWeight, heightAmplitude: $heightAmplitude}';
  }
}
