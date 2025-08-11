import 'package:hex_toolkit/hex_toolkit.dart';

class HexTopologyInfo {
  final Hex hex;
  final double elevation;

  const HexTopologyInfo(this.hex, this.elevation);

  const HexTopologyInfo.emptyOcean(Hex hex)
      : this.hex = hex,
        this.elevation = 0.0;
}

class HexHumidityInfo {
  final Hex hex;
  final double humidity;
  final double accumulatedHumidity;
  final Hex? flowDirection;
  final bool isRiver;

  const HexHumidityInfo(this.hex, this.humidity, this.accumulatedHumidity, this.flowDirection, this.isRiver);

  const HexHumidityInfo.empty(Hex hex)
      : this.hex = hex,
        this.humidity = 0.0,
        this.accumulatedHumidity = 0.0,
        this.flowDirection = null,
        this.isRiver = false;
}
