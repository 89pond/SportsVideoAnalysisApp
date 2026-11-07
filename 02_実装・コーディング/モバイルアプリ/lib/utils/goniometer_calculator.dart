import 'dart:math';
import 'package:flutter/material.dart';

/// ゴニオメーター (関節角度計測) 計算クラス
class GoniometerCalculator {
  /// 3点 (pointA, vertexB, pointC) から頂点Bにおける内角 (0°〜180°) を計算
  /// pointA: 点A (例: 大腿骨頭)
  /// vertexB: 頂点B (例: 膝関節)
  /// pointC: 点C (例: 足首)
  static double calculateAngle(Offset pointA, Offset vertexB, Offset pointC) {
    final v1x = pointA.dx - vertexB.dx;
    final v1y = pointA.dy - vertexB.dy;
    final v2x = pointC.dx - vertexB.dx;
    final v2y = pointC.dy - vertexB.dy;

    final dotProduct = v1x * v2x + v1y * v2y;
    final len1 = sqrt(v1x * v1x + v1y * v1y);
    final len2 = sqrt(v2x * v2x + v2y * v2y);

    if (len1 == 0 || len2 == 0) {
      return 0.0;
    }

    // コサインの範囲 [-1.0, 1.0] にクランプ
    final cosTheta = (dotProduct / (len1 * len2)).clamp(-1.0, 1.0);
    final radians = acos(cosTheta);
    final degrees = radians * (180.0 / pi);

    return double.parse(degrees.toStringAsFixed(1));
  }

  /// 鉛直基準線（プラムライン: Y軸下向き）に対する傾斜角 (0°〜90°) を計算
  static double calculatePlumbLineAngle(Offset topPoint, Offset bottomPoint) {
    final dx = (bottomPoint.dx - topPoint.dx).abs();
    final dy = (bottomPoint.dy - topPoint.dy).abs();
    if (dy == 0) return 90.0;
    final radians = atan(dx / dy);
    final degrees = radians * (180.0 / pi);
    return double.parse(degrees.toStringAsFixed(1));
  }
}
