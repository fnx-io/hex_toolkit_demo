import 'package:hex_toolkit/hex_toolkit.dart';
import 'package:hex_toolkit_demo/world/hex_data.dart';

class World {
  final WorldData _data;

  World(this._data);

  HexTopologyInfo getHexTopology(Hex hex, {bool depressionSolving = true}) {
    return _data.topology[hex] ??= HexTopologyInfo.emptyOcean(hex);
  }

  HexHumidityInfo getHexHumidity(Hex hex) {
    return _data.humidity[hex] ??= HexHumidityInfo.empty(hex);
  }
}

class WorldData {
  final Map<Hex, HexTopologyInfo> topology;
  final Map<Hex, HexHumidityInfo> humidity;

  WorldData(this.topology, this.humidity);
}
