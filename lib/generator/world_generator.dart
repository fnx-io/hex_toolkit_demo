import 'package:hex_toolkit/hex_toolkit.dart';
import 'package:hex_toolkit_demo/generator/simplex_providers.dart';
import 'package:hex_toolkit_demo/models/demo_settings.dart';
import 'package:hex_toolkit_demo/world/hex_data.dart';
import 'package:hex_toolkit_demo/world/world.dart';

class WorldGenerator {
  final int size;
  final HexValueProvider elevationProvider;
  final HexValueProvider humidityProvider;
  static final HexTopologyInfo ocean = HexTopologyInfo.emptyOcean(Hex.zero());

  var topology = <Hex, HexTopologyInfo>{};
  var humidity = <Hex, HexHumidityInfo>{};

  WorldGenerator({
    required this.size,
    required this.elevationProvider,
    required this.humidityProvider,
  });

  factory WorldGenerator.fromSettings(DemoSettings settings) {
    SimplexProvider provider = SimplexProvider(settings);
    return WorldGenerator(
      size: settings.worldSize,
      elevationProvider: provider.calculateBaseAltitude,
      humidityProvider: provider.calculateBaseAltitude,
    );
  }

  Iterable<Hex> allHexes() sync* {
    int minx = -size ~/ 2 - 5;
    int maxx = size ~/ 2 + 5;
    int miny = -size ~/ 2 - 5;
    int maxy = size ~/ 2 + 5;

    var topLeftHex = Hex.fromOffset(GridOffset(minx, miny)).cube.toGridOffset();
    var bottomRightHex = Hex.fromOffset(GridOffset(maxx, maxy)).cube.toGridOffset();

    for (int hx = topLeftHex.q; hx <= bottomRightHex.q; ++hx) {
      for (int hy = topLeftHex.r; hy <= bottomRightHex.r; ++hy) {
        yield Hex.fromOffset(GridOffset(hx, hy));
      }
    }
  }

  World generateWorldPreview() {
    topology = {};
    humidity = {};
    int start = DateTime.now().millisecondsSinceEpoch;
    int hit = 0;
    int miss = 0;
    for (var hex in allHexes()) {
      if (topology[hex] == null) {
        miss++;
        double elevation = elevationProvider(hex);
        // me and few my friends
        topology[hex] = HexTopologyInfo(hex, elevation);
        topology[Hex.fromCube(hex.cube + Cube(1, 0, -1))] = HexTopologyInfo(hex, elevation);
        topology[Hex.fromCube(hex.cube + Cube(0, 1, -1))] = HexTopologyInfo(hex, elevation);
        topology[Hex.fromCube(hex.cube + Cube(1, -1, 0))] = HexTopologyInfo(hex, elevation);
      } else {
        hit++;
      }
    }
    print(
        "World preview generated in ${DateTime.now().millisecondsSinceEpoch - start} ms, $hit hits, $miss misses, ${topology.length} hexes in topology");
    return World(WorldData(topology, humidity));
  }

  World generateWorld() {
    for (var hex in allHexes()) {
      double elevation = elevationProvider(hex);
      topology[hex] = HexTopologyInfo(hex, elevation);

      double humidityValue = humidityProvider(hex);
      humidity[hex] = HexHumidityInfo(hex, humidityValue, 0, null, false);
    }

    // Resolve depressions
    Iterable<Hex> todo = allHexes();

    int count = 1;
    while (todo.isNotEmpty) {
      Set<Hex> nextTodo = {};
      for (var hex in todo) {
        nextTodo.addAll(_resolveDepression(hex));
      }
      todo = nextTodo;
      count++;
    }

    // None of the hexes should be a depression at this point
    assert(!allHexes().any(_isHexDepression));

    return World(WorldData(topology, humidity));
  }

  // HexTopologyInfo getHexTopology(Hex hex, {bool depressionSolving = true}) {
  //   // Check cache first
  //   var info = topology[hex];
  //   if (info == null) {
  //     double baseHeight = _calculateBaseHeight(hex);
  //     double elevation = baseHeight * settings.heightAmplitude;
  //     info = HexTopologyInfo(hex, elevation, baseHeight);
  //     topology[hex] = info;
  //   }
  //   if (depressionSolving && !depressionSolved.containsKey(hex)) {
  //     resolveDepression(hex);
  //     info = topology[hex]!;
  //     depressionSolved[hex] = true;
  //     hex.spiral(3).forEach(resolveDepression);
  //
  //     // go down:
  //     var down = flowDirectionTarget(hex);
  //     if (down != null) getHexTopology(down);
  //     // go up:
  //     flowDirectionSources(hex).forEach(getHexTopology);
  //   }
  //   return info;
  // }

  Iterable<Hex> _resolveDepression(Hex hex) {
    if (_isHexDepression(hex)) {
      var lowestNeighbor = hex.neighbors().map((h) => topology[h] ?? ocean).reduce((a, b) {
        return a.elevation < b.elevation ? a : b;
      });
      var newInfo = HexTopologyInfo(hex, lowestNeighbor.elevation * 1.01);
      topology[hex] = newInfo;
      return [hex, ...hex.neighbors()];
    }
    return const Iterable.empty();
  }

  bool _isHexDepression(Hex hex) {
    var my = topology[hex]!;
    if (my.elevation <= 0) {
      // ocean is not depression, unless it is surrounded by land
      return hex.neighbors().every((h) => (topology[h] ?? ocean).elevation > 0);
    }
    return hex.neighbors().every((h) => (topology[h] ?? ocean).elevation > my.elevation);
  }

  // HexHumidityInfo getHexHumidity(Hex hex) {
  //   // Check cache first
  //   if (humidityCache.containsKey(hex)) {
  //     return humidityCache[hex]!;
  //   }
  //   var topo = getHexTopology(hex);
  //
  //   if (topo.elevation <= 0) {
  //     var empty = HexHumidityInfo(0, 0, null, false);
  //     humidityCache[hex] = empty;
  //     return empty;
  //   }
  //
  //   // Use OpenSimplex noise for humidity generation
  //   double humidity = _calculateBaseHumidity(hex);
  //
  //   // Calculate accumulated humidity and flow direction
  //   double accumulatedHumidity = _resolveAccumulatedHumidity(hex);
  //
  //   var info = HexHumidityInfo(humidity, accumulatedHumidity, flowDirectionTarget(hex)!, accumulatedHumidity > 15);
  //   humidityCache[hex] = info;
  //
  //   if (flowDirectionTarget(info.flowDirection!) == hex) {
  //     print("WTF");
  //   }
  //
  //   if (_isHexDepression(hex)) throw StateError("Hex $hex is a depression, cannot calculate humidity for it.");
  //   return info;
  // }
  //
  // double _resolveAccumulatedHumidity(Hex myself) {
  //   double result = _calculateBaseHumidity(myself);
  //   for (var o in myself.neighbors()) {
  //     Hex? flowDirection = flowDirectionTarget(o);
  //     if (flowDirection == myself) {
  //       result += getHexHumidity(o).accumulatedHumidity;
  //     }
  //   }
  //   return result;
  // }
  //
  // Hex? flowDirectionTarget(Hex hex) {
  //   HexTopologyInfo my = getHexTopology(hex, depressionSolving: false);
  //   if (my.elevation <= 0) return null; // No flow from ocean
  //   var candidates = hex.neighbors().where((h) => getHexTopology(h, depressionSolving: false).elevation < my.elevation).toList();
  //   if (candidates.isEmpty) return null;
  //   if (candidates.length == 1) return candidates.first;
  //   candidates.shuffle(Random(hex.hashCode));
  //   return candidates.first;
  // }
  //
  // List<Hex> flowDirectionSources(Hex hex) {
  //   List<Hex> sources = [];
  //   for (var o in hex.neighbors()) {
  //     Hex? flowDirection = flowDirectionTarget(o);
  //     if (flowDirection == hex) {
  //       sources.add(o);
  //     }
  //   }
  //   return sources;
  // }
  //
  // double _calculateBaseHumidity(Hex hex) {
  //   double x = hex.centerPoint(1).x;
  //   double y = hex.centerPoint(1).y;
  //   double humidityNoise = humidityGenerator.noise2(x * settings.humidityFrequency, y * settings.humidityFrequency);
  //   return (humidityNoise + 1) / 2; // Normalize to [0, 1]
  // }
}
