/// Library for procedural hex-based world generation.
///
/// Provides classes and utilities for creating and managing procedurally
/// generated worlds with terrain, hydrology, and other features.
library hex_toolkit_generator;

import 'dart:math';

import 'package:hex_toolkit/hex_toolkit.dart';
import 'package:hex_toolkit_demo/utils/cubic_bezier_easing.dart';
import 'package:hex_toolkit_demo/utils/open_simplex_2f.dart';

part 'hex_hydrology_info.dart';
part 'hex_topology_info.dart';
part 'simplex_based_config.dart';
part 'simplex_based_providers.dart';
part 'world_generator.dart';

/// Configuration interface for world generation.
///
/// Defines the properties required for world generation, including world size
/// and functions for calculating normalized elevation and humidity.
abstract class WorldGeneratorConfig {
  /// Size of the world in hexes (approximate radius).
  int get size;

  /// Function that determines baseline elevation for each hex.
  HexValueProvider get elevationProvider;

  /// Function that determines humidity for each hex.
  HexValueProvider get humidityProvider;

  /// Threshold value for river formation based on accumulated humidity.
  double get riverTrashold;
}

/// Represents a complete procedurally generated world.
///
/// Provides access to topology (elevation) and hydrology (water) information
/// for any hex in the world.
class World {
  /// The underlying data for this world.
  final _WorldData _data;

  /// Creates a new world with the specified data.
  World(this._data);

  /// Gets topology information for the specified hex.
  ///
  /// Returns information about the elevation and land/ocean status.
  /// If the hex doesn't exist in the world data, returns an ocean hex.
  HexTopologyInfo getHexTopology(Hex hex) {
    return _data._topology[hex] ?? HexTopologyInfo.emptyOcean(hex);
  }

  /// Gets hydrology information for the specified hex.
  ///
  /// Returns information about humidity, rivers, and water flow.
  /// If the hex doesn't exist in the world data, returns an ocean hex.
  HexHydrologyInfo getHexHumidity(Hex hex) {
    return _data._humidity[hex] ?? HexHydrologyInfo.emptyOcean(hex);
  }
}

/// Container for the raw data of a generated world.
///
/// Stores mappings from hex coordinates to topology and hydrology information.
class _WorldData {
  /// Map of hex coordinates to topology information.
  final Map<Hex, HexTopologyInfo> _topology;

  /// Map of hex coordinates to hydrology information.
  final Map<Hex, HexHydrologyInfo> _humidity;

  /// Creates a new world data container with the specified maps.
  _WorldData(this._topology, this._humidity);
}
