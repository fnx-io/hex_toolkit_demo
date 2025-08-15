part of 'world.dart';

/// Generates procedural worlds with terrain and hydrology features.
///
/// Uses abstract providers to create natural-looking terrain
/// with mountains, valleys, rivers, and oceans.
class WorldGenerator {
  final WorldGeneratorConfig config;

  /// The size of the world (approximate radius in hexes).
  int get size => config.size;

  /// Function that provides elevation values for hexes, value should be in the range [-1, 1].
  HexValueProvider get elevationProvider => config.elevationProvider;

  /// Function that provides humidity values for hexes, value should be in the range [0, 1].
  HexValueProvider get humidityProvider => config.humidityProvider;

  /// Constant representing an ocean hex, used for boundary conditions.
  static final HexTopologyInfo ocean = HexTopologyInfo.emptyOcean(Hex.zero());

  /// Map storing work-in-progress topology (elevation) information for all generated hexes.
  var _topology = <Hex, HexTopologyInfo>{};

  /// Map storing work-in-progress hydrology (water) information for all generated hexes.
  var _humidity = <Hex, HexHydrologyInfo>{};

  /// Creates a new world generator with the specified configuration.
  ///
  /// [config] provides the world size and functions for determining elevation and humidity.
  WorldGenerator({required this.config});

  /// Returns an iterable of all hexes in the world.
  ///
  /// Generates hexes in a rectangular area that encompasses the world size,
  /// with a small buffer zone around the edges.
  /// Uses a sync* generator to efficiently yield hexes one at a time.
  Iterable<Hex> _allHexes() sync* {
    // Calculate bounds with a small buffer (5 hexes)
    int minx = -size ~/ 2 - 5;
    int maxx = size ~/ 2 + 5;
    int miny = -size ~/ 2 - 5;
    int maxy = size ~/ 2 + 5;

    // Convert to proper hex coordinates
    var topLeftHex = Hex.fromOffset(GridOffset(minx, miny)).cube.toGridOffset();
    var bottomRightHex = Hex.fromOffset(GridOffset(maxx, maxy)).cube.toGridOffset();

    // Iterate through all hexes in the rectangular area
    for (int hx = topLeftHex.q; hx <= bottomRightHex.q; ++hx) {
      for (int hy = topLeftHex.r; hy <= bottomRightHex.r; ++hy) {
        yield Hex.fromOffset(GridOffset(hx, hy));
      }
    }
  }

  /// Generates a quick preview of the world with basic topology.
  ///
  /// This method is faster than [generateWorld] but produces a less detailed world.
  /// It only generates elevation data (no hydrology) and uses a simplified approach
  /// where neighboring hexes share elevation. Good for real-time previews.
  ///
  /// Returns a [World] instance with the generated data.
  World generateWorldPreview() {
    _topology = {};
    _humidity = {};
    for (var hex in _allHexes()) {
      if (_topology[hex] == null) {
        double elevation = elevationProvider(hex);

        // Set elevation for this hex and some of its neighbors
        // to create rough approximation of terrain
        _topology[hex] = HexTopologyInfo(hex, elevation);
        _topology[Hex.fromCube(hex.cube + Cube(1, 0, -1))] ??= HexTopologyInfo(hex, elevation);
        _topology[Hex.fromCube(hex.cube + Cube(0, 1, -1))] ??= HexTopologyInfo(hex, elevation);
        _topology[Hex.fromCube(hex.cube + Cube(-1, 1, 0))] ??= HexTopologyInfo(hex, elevation);
      }
    }
    return World(_WorldData(_topology, _humidity));
  }

  /// Generates a complete world with detailed topology and hydrology. This takes some time, and should be run async.
  ///
  /// This method performs the following steps:
  /// 1. Generates base elevation for all hexes (using the elevationProvider)
  /// 2. Resolves terrain depressions to ensure proper water flow (e.g., raising depressions)
  /// 3. Generates humidity and river systems by evaluating water flow
  ///
  /// Returns a [World] instance with the fully generated data.
  World generateWorld() {
    // Step 1: Generate base elevation for all hexes
    for (var hex in _allHexes()) {
      double elevation = elevationProvider(hex);
      _topology[hex] = HexTopologyInfo(hex, elevation);
    }

    // Step 2: Resolve depressions to ensure proper water flow
    {
      Iterable<Hex> todo = _allHexes();
      while (todo.isNotEmpty) {
        Set<Hex> nextTodo = {};
        for (var hex in todo) {
          nextTodo.addAll(_resolveDepression(hex));
        }
        todo = nextTodo;
      }
    }

    // Verify that all depressions have been resolved
    assert(!_allHexes().any(_isHexDepression));

    // Step 3: Generate rivers and humidity
    {
      for (var hex in _allHexes()) {
        _computeHumidity(hex);
      }
    }

    return World(_WorldData(_topology, _humidity));
  }

  /// Resolves a terrain depression at the specified hex.
  ///
  /// A depression is a hex where water cannot flow out because all neighbors
  /// are at higher elevations. This method raises the hex's elevation slightly
  /// above its lowest neighbor to ensure water can flow.
  ///
  /// Returns a collection of hexes that might need to be checked for depressions
  /// after this resolution (the modified hex and its neighbors).
  /// Returns an empty collection if the hex wasn't a depression.
  Iterable<Hex> _resolveDepression(Hex hex) {
    if (_isHexDepression(hex)) {
      // Find the lowest neighboring hex
      var lowestNeighbor = hex.neighbors().map((h) => _topology[h] ?? ocean).reduce((a, b) {
        return a.elevation < b.elevation ? a : b;
      });

      // Set this hex's elevation slightly higher than the lowest neighbor
      // The 1.01 multiplier ensures a slight slope for water flow
      var newInfo = HexTopologyInfo(hex, lowestNeighbor.elevation * 1.01);
      _topology[hex] = newInfo;

      // Return this hex and all neighbors for further depression checking
      return [hex, ...hex.neighbors()];
    }
    return const Iterable.empty();
  }

  /// Determines if a hex is a terrain depression.
  ///
  /// A depression is:
  /// - A land hex where all neighbors are at higher elevations
  /// - An ocean hex that is completely surrounded by land
  ///
  /// Returns true if the hex is a depression, false otherwise.
  bool _isHexDepression(Hex hex) {
    var my = _topology[hex]!;
    if (my.isOcean) {
      // Ocean is not a depression, unless it is surrounded by land
      return hex.neighbors().every((h) => (_topology[h] ?? ocean).isLand);
    }
    // Land is a depression if all neighbors are at higher elevations
    return hex.neighbors().every((h) => (_topology[h] ?? ocean).elevation >= my.elevation);
  }

  /// Computes hydrology information for the specified hex.
  ///
  /// This method:
  /// 1. Calculates base humidity for the hex
  /// 2. Recursively accumulates humidity from upstream hexes (those that flow into this hex)
  /// 3. Determines if the hex should be part of a river based on accumulated humidity
  /// 4. Creates and caches a HexHydrologyInfo object with the results
  ///
  /// Uses recursion to ensure all upstream hexes are processed first.
  ///
  /// Returns the computed hydrology information for the hex.
  HexHydrologyInfo _computeHumidity(Hex hex) {
    // Return cached result if available
    if (_humidity[hex] != null) return _humidity[hex]!;

    var topo = _topology[hex]!;
    if (topo.isOcean) {
      // Ocean hexes have special hydrology (infinite humidity, no flow)
      var result = HexHydrologyInfo.emptyOcean(hex);
      _humidity[hex] = result;
      return result;
    }

    // Calculate base humidity for this hex
    double humidityValue = humidityProvider(hex);
    assert(humidityValue >= 0 && humidityValue <= 1, "Humidity value for hex $hex is out of bounds: $humidityValue");
    double accumulatedHumidity = humidityValue;

    // Accumulate humidity from upstream hexes (those that flow into this hex)
    bool iAmRiver = false;
    for (var o in hex.neighbors()) {
      Hex? flowDirection = flowDirectionTarget(o);
      if (flowDirection == hex) {
        // This neighbor flows into me, so add its humidity
        // Recursion warning! Recursion warning!
        var parent = _computeHumidity(o);
        accumulatedHumidity += parent.accumulatedHumidity;
        // If an upstream hex is a river, this hex is also a river
        if (parent.isRiver) iAmRiver = true;
      }
    }

    // Determine if this hex should be a river based on accumulated humidity
    // and elevation.
    if (!iAmRiver) {
      if (accumulatedHumidity > config.riverTrashold && topo.elevation < 3000) {
        iAmRiver = true;
      }
    }

    // Verify river hexes have a valid flow direction
    if (iAmRiver) {
      assert(flowDirectionTarget(hex) != null,
          "River hex $hex has no flow direction target, accumulated humidity: $accumulatedHumidity, elevation: ${topo.elevation}");
    }

    // Create and cache the hydrology information
    var result = HexHydrologyInfo(hex, humidityValue, accumulatedHumidity, flowDirectionTarget(hex), iAmRiver, topo.isOcean);
    _humidity[hex] = result;
    return result;
  }

  /// Determines the hex that water flows to from the specified hex.
  ///
  /// Water flows downhill to the neighbor with the lowest elevation.
  /// If multiple neighbors have the same lowest elevation, one is chosen
  /// deterministically based on the hex's hash code.
  ///
  /// Returns the target hex, or null if the hex is an ocean (no flow).
  /// Throws an exception if no valid flow direction can be found, which
  /// should not happen after depression solving.
  Hex? flowDirectionTarget(Hex hex) {
    HexTopologyInfo my = _topology[hex] ?? ocean;
    if (my.isOcean) return null; // No flow from ocean

    // Find all neighbors with lower elevation (potential flow targets)
    var candidates = hex.neighbors().where((h) => (_topology[h] ?? ocean).elevation < my.elevation).toList();

    if (candidates.isEmpty) {
      // This should never happen after depression solving
      print(my.isOcean);
      print(_isHexDepression(hex));
      throw Exception(
          "No flow direction found for hex $hex with elevation ${my.elevation}. Neighbors: ${hex.neighbors().map((h) => _topology[h] ?? ocean)}");
    }

    // If only one candidate, that's our flow direction
    if (candidates.length == 1) return candidates.first;

    // If multiple candidates, choose one deterministically
    // Using the hex's hash code ensures the choice is consistent
    candidates.shuffle(Random(hex.hashCode));
    return candidates.first;
  }

  /// Finds all neighboring hexes that flow into the specified hex.
  ///
  /// These are the "upstream" hexes that contribute to the water
  /// accumulation at this hex.
  ///
  /// Returns a list of hexes that have this hex as their flow direction target.
  List<Hex> flowDirectionSources(Hex hex) {
    List<Hex> sources = [];
    for (var o in hex.neighbors()) {
      Hex? flowDirection = flowDirectionTarget(o);
      if (flowDirection == hex) sources.add(o);
    }
    return sources;
  }
}
