import 'dart:math';

/// A class that calculates the cubic-bezier easing for a given time `t`.
///
/// This class mimics the behavior of the CSS `cubic-bezier` function
/// and allows you to specify the control points `p1x`, `p1y`, `p2x`, and `p2y`
/// in the constructor.
class CubicBezierEasing {
  final double _p1x;
  final double _p1y;
  final double _p2x;
  final double _p2y;

  /// Creates a [CubicBezierEasing] instance with the specified control points.
  ///
  /// The values must be between 0 and 1.
  CubicBezierEasing(
    this._p1x,
    this._p1y,
    this._p2x,
    this._p2y,
  );

  double transformNoise(double t) {
    return ((transform((t + 1) / 2) - 0.5) * 2);
  }

  /// Calculates the cubic-bezier easing for a given time `t`.
  ///
  /// The function uses a bisection method to find the `x` value (time)
  /// corresponding to the given `t` (progress).
  double transform(double t) {
    // Find the `u` value for the given `t` (x-axis)
    double u = _findU(t);

    // Return the `y` value for the found `u`
    return _curveY(u);
  }

  /// Helper function for the x-axis curve equation.
  double _curveX(double u) {
    return 3 * u * pow((1 - u), 2) * _p1x + 3 * pow(u, 2) * (1 - u) * _p2x + pow(u, 3);
  }

  /// Helper function for the y-axis curve equation.
  double _curveY(double u) {
    return 3 * u * pow((1 - u), 2) * _p1y + 3 * pow(u, 2) * (1 - u) * _p2y + pow(u, 3);
  }

  /// A helper function using the bisection method to find `u` for a given `t`.
  double _findU(double t) {
    double start = 0.0;
    double end = 1.0;
    double u = t;

    // Bisection method to find the `u` that gives `t`
    for (int i = 0; i < 15; i++) {
      // 15 iterations provide sufficient precision
      double x = _curveX(u);
      if ((x - t).abs() < 0.0001) {
        break;
      }
      if (x < t) {
        start = u;
      } else {
        end = u;
      }
      u = (start + end) / 2.0;
    }
    return u;
  }
}
