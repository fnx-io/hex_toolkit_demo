// Source: https://github.com/creativecreatorormaybenot/funvas/blob/main/open_simplex_2/lib/src/open_simplex_2f.dart

// BSD 3-Clause License
//
// Copyright (c) 2021-2025, creativecreatorormaybenot
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// 1. Redistributions of source code must retain the above copyright notice, this
// list of conditions and the following disclaimer.
//
// 2. Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimer in the documentation
// and/or other materials provided with the distribution.
//
// 3. Neither the name of the copyright holder nor the names of its
// contributors may be used to endorse or promote products derived from
// this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

// The implementation in this file is based on KdotJPG's implementation here: https://github.com/KdotJPG/OpenSimplex2/blob/a186b9bb644747c936d7cba748d11f28b1cee66e/java/OpenSimplex2F.java.

import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';

const _kN2 = 0.01001634121365712;
const _kSize = 2048;
const _kMask = 2047;

/// K.jpg's OpenSimplex 2, faster variant.
///
/// - 2D is standard simplex implemented using a lookup table.
///
/// Multiple versions of each function are provided. See the documentation for
/// each for more info.
class OpenSimplex2F {
  /// Creates a seeded [OpenSimplex2F] that can be used to evaluate noise.
  OpenSimplex2F(int seed) {
    if (!_staticInitialized) {
      _staticInit();
      _staticInitialized = true;
    }

    final source = Int16List(_kSize);
    for (var i = 0; i < _kSize; i++) {
      source[i] = i;
    }
    // KdotJPG's implementation uses Java's long here. Long in Java is a
    // 64-bit two's complement integer. int in Dart is also a 64-bit two's
    // complement integer, however, *only on native* (see https://dart.dev/guides/language/numbers).
    // However, we want to support web, i.e. JavaScript, as well with this
    // package and therefore we have to use the fixnum Int64 type. See
    // https://github.com/dart-lang/sdk/issues/46852#issuecomment-894888740.
    var seed64 = Int64(seed);
    for (int i = _kSize - 1; i >= 0; i--) {
      // KdotJPG's implementation uses long literals here. We can use int
      // literals of this size as well in Dart, however, these are too big for
      // JavaScript and therefore we have to use int.parse instead.
      seed64 = seed64 * Int64.parseInt('6364136223846793005') + Int64.parseInt('1442695040888963407');
      // We know r cannot be bigger than 2047, so we can convert it back to an
      // int.
      var r = ((seed64 + 31) % (i + 1)).toInt();
      if (r < 0) r += i + 1;
      _perm[i] = source[r];
      _permGrad2[i] = _gradients2d[_perm[i]];
      source[r] = source[i];
    }
  }

  final _perm = Int16List(_kSize);
  final _permGrad2 = List.filled(_kSize, const _Grad2(0, 0));

  // Noise evaluators

  /// 2D Simplex noise, standard lattice orientation.
  double noise2(double x, double y) {
    // Get points for A2* lattice
    final s = 0.366025403784439 * (x + y);
    final xs = x + s, ys = y + s;

    return _noise2Base(xs, ys);
  }

  /// 2D Simplex noise, with Y pointing down the main diagonal.
  ///
  /// Might be better for a 2D sandbox style game, where Y is vertical.
  /// Probably slightly less optimal for heightmaps or continent maps.
  double noise2XBeforeY(double x, double y) {
    // Skew transform and rotation baked into one.
    final xx = x * 0.7071067811865476;
    final yy = y * 1.224744871380249;

    return _noise2Base(yy + xx, yy - xx);
  }

  /// 2D Simplex noise base.
  ///
  /// Lookup table implementation inspired by DigitalShadow.
  double _noise2Base(double xs, double ys) {
    double value = 0;

    // Get base points and offsets
    int xsb = xs.floor(), ysb = ys.floor();
    double xsi = xs - xsb, ysi = ys - ysb;

    // Index to point list
    final index = ((ysi - xsi) / 2 + 1).toInt();

    double ssi = (xsi + ysi) * -0.211324865405187;
    double xi = xsi + ssi, yi = ysi + ssi;

    // Point contributions
    for (int i = 0; i < 3; i++) {
      _LatticePoint2D c = _lookup2d[index + i];

      double dx = xi + c.dx, dy = yi + c.dy;
      double attn = 0.5 - dx * dx - dy * dy;
      if (attn <= 0) continue;

      int pxm = (xsb + c.xsv) & _kMask, pym = (ysb + c.ysv) & _kMask;
      _Grad2 grad = _permGrad2[_perm[pxm] ^ pym];
      double extrapolation = grad.dx * dx + grad.dy * dy;

      attn *= attn;
      value += attn * attn * extrapolation;
    }

    return value;
  }

  // Definitions

  static final _lookup2d = const <_LatticePoint2D>[
    _LatticePoint2D(1, 0),
    _LatticePoint2D(0, 0),
    _LatticePoint2D(1, 1),
    _LatticePoint2D(0, 1),
  ];

  static final _gradients2d = <_Grad2>[];

  static var _staticInitialized = false;

  /// Performs the initialization of all static lookup members.
  ///
  /// This function as well as [_staticInitialized] exist because there is
  /// no comparable concept to static blocks (from Java) in Dart.
  static void _staticInit() {
    const grad2 = [
      _Grad2(0.130526192220052, 0.99144486137381),
      _Grad2(0.38268343236509, 0.923879532511287),
      _Grad2(0.608761429008721, 0.793353340291235),
      _Grad2(0.793353340291235, 0.608761429008721),
      _Grad2(0.923879532511287, 0.38268343236509),
      _Grad2(0.99144486137381, 0.130526192220051),
      _Grad2(0.99144486137381, -0.130526192220051),
      _Grad2(0.923879532511287, -0.38268343236509),
      _Grad2(0.793353340291235, -0.60876142900872),
      _Grad2(0.608761429008721, -0.793353340291235),
      _Grad2(0.38268343236509, -0.923879532511287),
      _Grad2(0.130526192220052, -0.99144486137381),
      _Grad2(-0.130526192220052, -0.99144486137381),
      _Grad2(-0.38268343236509, -0.923879532511287),
      _Grad2(-0.608761429008721, -0.793353340291235),
      _Grad2(-0.793353340291235, -0.608761429008721),
      _Grad2(-0.923879532511287, -0.38268343236509),
      _Grad2(-0.99144486137381, -0.130526192220052),
      _Grad2(-0.99144486137381, 0.130526192220051),
      _Grad2(-0.923879532511287, 0.38268343236509),
      _Grad2(-0.793353340291235, 0.608761429008721),
      _Grad2(-0.608761429008721, 0.793353340291235),
      _Grad2(-0.38268343236509, 0.923879532511287),
      _Grad2(-0.130526192220052, 0.99144486137381)
    ];
    final grad2Adjusted = [
      for (final grad in grad2) _Grad2(grad.dx / _kN2, grad.dy / _kN2),
    ];
    for (int i = 0; i < _kSize; i++) {
      _gradients2d.add(grad2Adjusted[i % grad2.length]);
    }
  }
}

class _LatticePoint2D {
  const _LatticePoint2D(this.xsv, this.ysv)
      : dx = -xsv - ((xsv + ysv) * -0.211324865405187),
        dy = -ysv - ((xsv + ysv) * -0.211324865405187);

  final int xsv, ysv;
  final double dx, dy;
}

/// 2-dimensional gradient.
class _Grad2 {
  /// Creates a 2-dimensional gradient from its components.
  const _Grad2(this.dx, this.dy);

  /// The x component of the gradient.
  final double dx;

  /// The y component of the gradient.
  final double dy;
}
