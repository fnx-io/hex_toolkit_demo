part of 'world.dart';

/// Stores hydrology-related information for a hex in the world.
///
/// Contains data about humidity, water flow, and whether the hex is part of
/// a river or ocean system.
class HexHydrologyInfo {
  /// The hex this hydrology information belongs to.
  final Hex hex;

  /// Base humidity value for this hex.
  final double humidity;

  /// Total accumulated humidity from this hex and upstream hexes.
  final double accumulatedHumidity;

  /// Direction water flows from this hex, or null if it's a sink or ocean.
  final Hex? flowDirection;

  /// Whether this hex is part of a river.
  final bool isRiver;

  /// Whether this hex is part of an ocean.
  final bool isOcean;

  /// Creates a new hydrology info instance with the specified parameters.
  HexHydrologyInfo(this.hex, this.humidity, this.accumulatedHumidity, this.flowDirection, this.isRiver, this.isOcean);

  /// Creates a hydrology info instance representing an ocean hex.
  ///
  /// Ocean hexes have maximum humidity and no flow direction.
  const HexHydrologyInfo.emptyOcean(Hex hex)
      : this.hex = hex,
        this.humidity = double.maxFinite,
        this.accumulatedHumidity = double.maxFinite,
        this.flowDirection = null,
        this.isRiver = false,
        this.isOcean = true;
}
