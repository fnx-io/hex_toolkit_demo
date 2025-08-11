import 'package:flutter/material.dart';

class ColorFactory {
  static Color getHexColor(double elevation) {
    if (elevation <= 0) return Colors.blue.shade500;
    if (elevation < 1500) return Colors.green.shade400;
    if (elevation > 3500) return Colors.white;

    double slope = (elevation - 1500) / (3500 - 1500.0);
    if (slope < 0.5) {
      return Color.lerp(Colors.green.shade400, Colors.brown.shade300, 2 * slope)!;
    } else {
      return Color.lerp(Colors.brown.shade300, Colors.grey.shade300, 2 * (slope - 0.5))!;
    }
  }
}
