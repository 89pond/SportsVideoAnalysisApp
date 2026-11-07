import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/view_mode.dart';
import '../models/drawing_object.dart';
import '../models/waveform_series.dart';

/// プロジェクト分析状態モデル (JSON永続化対象)
class AnalysisProjectState {
  final String projectId;
  final String updatedAt;
  final String? videoAPath;
  final String? videoBPath;
  final ViewMode viewMode;
  final double syncOffsetSeconds;
  final double ghostOpacity;
  final List<String> selectedWaveforms;
  final List<DrawingObject> annotations;

  AnalysisProjectState({
    required this.projectId,
    required this.updatedAt,
    this.videoAPath,
    this.videoBPath,
    required this.viewMode,
    required this.syncOffsetSeconds,
    required this.ghostOpacity,
    required this.selectedWaveforms,
    required this.annotations,
  });

  Map<String, dynamic> toJson() {
    return {
      'projectId': projectId,
      'updatedAt': updatedAt,
      'videoAPath': videoAPath,
      'videoBPath': videoBPath,
      'viewMode': viewMode.name,
      'syncOffsetSeconds': syncOffsetSeconds,
      'ghostOpacity': ghostOpacity,
      'selectedWaveforms': selectedWaveforms,
      'annotations': annotations.map((obj) => _drawingObjectToJson(obj)).toList(),
    };
  }

  factory AnalysisProjectState.fromJson(Map<String, dynamic> json) {
    final viewModeStr = json['viewMode'] as String? ?? 'splitHorizontal';
    final viewMode = ViewMode.values.firstWhere(
      (v) => v.name == viewModeStr,
      orElse: () => ViewMode.splitHorizontal,
    );

    final rawAnnotations = json['annotations'] as List<dynamic>? ?? [];
    final annotations = rawAnnotations
        .map((item) => _drawingObjectFromJson(item as Map<String, dynamic>))
        .toList();

    return AnalysisProjectState(
      projectId: json['projectId'] as String? ?? 'PROJ_DEFAULT',
      updatedAt: json['updatedAt'] as String? ?? DateTime.now().toIso8601String(),
      videoAPath: json['videoAPath'] as String?,
      videoBPath: json['videoBPath'] as String?,
      viewMode: viewMode,
      syncOffsetSeconds: (json['syncOffsetSeconds'] as num?)?.toDouble() ?? 0.0,
      ghostOpacity: (json['ghostOpacity'] as num?)?.toDouble() ?? 0.5,
      selectedWaveforms: (json['selectedWaveforms'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          ['accelX', 'accelY', 'accelZ', 'accelTotal'],
      annotations: annotations,
    );
  }

  static Map<String, dynamic> _drawingObjectToJson(DrawingObject obj) {
    return {
      'type': obj.type.name,
      'color': obj.color.value,
      'strokeWidth': obj.strokeWidth,
      'calculatedAngle': obj.calculatedAngle,
      'points': obj.points.map((p) => {'dx': p.dx, 'dy': p.dy}).toList(),
    };
  }

  static DrawingObject _drawingObjectFromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String? ?? 'freehand';
    final type = DrawingToolType.values.firstWhere(
      (t) => t.name == typeStr,
      orElse: () => DrawingToolType.freehand,
    );

    final colorVal = json['color'] as int? ?? Colors.yellow.value;
    final strokeWidth = (json['strokeWidth'] as num?)?.toDouble() ?? 3.0;
    final angle = (json['calculatedAngle'] as num?)?.toDouble();

    final rawPoints = json['points'] as List<dynamic>? ?? [];
    final points = rawPoints.map((p) {
      final map = p as Map<String, dynamic>;
      return Offset(
        (map['dx'] as num).toDouble(),
        (map['dy'] as num).toDouble(),
      );
    }).toList();

    return DrawingObject(
      type: type,
      points: points,
      color: Color(colorVal),
      strokeWidth: strokeWidth,
      calculatedAngle: angle,
    );
  }

  String toJsonString() {
    return const JsonEncoder.withIndent('  ').convert(toJson());
  }

  static AnalysisProjectState fromJsonString(String jsonStr) {
    final map = jsonDecode(jsonStr) as Map<String, dynamic>;
    return AnalysisProjectState.fromJson(map);
  }
}
