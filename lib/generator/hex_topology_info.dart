part of 'world.dart';

/// Stores topology-related information for a hex in the world.
///
/// Contains data about elevation and provides methods to determine
/// if the hex is ocean or land.
class HexTopologyInfo {
  /// The hex this topology information belongs to.
  final Hex hex;

  /// Elevation of this hex in arbitrary units.
  /// Values <= 0.0 represent ocean, while positive values represent land.
  final double elevation;

  /// Creates a new topology info instance with the specified parameters.
  const HexTopologyInfo(this.hex, this.elevation);

  /// Creates a topology info instance representing an ocean hex.
  ///
  /// Ocean hexes have an elevation of 0.0.
  const HexTopologyInfo.emptyOcean(Hex hex)
      : this.hex = hex,
        this.elevation = 0.0;

  /// Returns true if this hex is part of an ocean (elevation <= 0.0).
  bool get isOcean => elevation <= 0.0;

  /// Returns true if this hex is part of land (elevation > 0.0).
  bool get isLand => !isOcean;

  @override
  String toString() {
    return 'HexTopologyInfo{elevation: $elevation}';
  }
}
