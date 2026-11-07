import 'package:flutter/material.dart';
import 'view_mode.dart';

/// 1つの描画オブジェクト（アノテーション）
class DrawingObject {
  final DrawingToolType type;
  final List<Offset> points;
  final Color color;
  final double strokeWidth;
  final double? calculatedAngle; // ゴニオメーター時の計算角度 (0°〜180°)

  DrawingObject({
    required this.type,
    required this.points,
    this.color = Colors.yellow,
    this.strokeWidth = 3.0,
    this.calculatedAngle,
  });

  DrawingObject copyWith({
    DrawingToolType? type,
    List<Offset>? points,
    Color? color,
    double? strokeWidth,
    double? calculatedAngle,
  }) {
    return DrawingObject(
      type: type ?? this.type,
      points: points ?? this.points,
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      calculatedAngle: calculatedAngle ?? this.calculatedAngle,
    );
  }
}
