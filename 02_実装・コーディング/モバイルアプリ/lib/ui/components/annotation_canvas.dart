import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/view_mode.dart';
import '../../models/drawing_object.dart';
import '../../utils/goniometer_calculator.dart';

/// 描画・角度計測オーバーレイキャンバス (グリッド・プラムライン対応)
class AnnotationCanvas extends StatefulWidget {
  final DrawingToolType activeTool;
  final Color strokeColor;
  final double strokeWidth;
  final List<DrawingObject> objects;
  final Function(DrawingObject) onObjectAdded;
  final bool showGrid;
  final bool showPlumbLine;

  const AnnotationCanvas({
    super.key,
    required this.activeTool,
    this.strokeColor = Colors.yellow,
    this.strokeWidth = 3.0,
    required this.objects,
    required this.onObjectAdded,
    this.showGrid = false,
    this.showPlumbLine = false,
  });

  @override
  State<AnnotationCanvas> createState() => _AnnotationCanvasState();
}

class _AnnotationCanvasState extends State<AnnotationCanvas> {
  List<Offset> _currentPoints = [];

  void _onPanStart(DragStartDetails details) {
    if (widget.activeTool == DrawingToolType.none) return;
    setState(() {
      _currentPoints = [details.localPosition];
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (widget.activeTool == DrawingToolType.none) return;
    setState(() {
      if (widget.activeTool == DrawingToolType.freehand) {
        _currentPoints.add(details.localPosition);
      } else if (widget.activeTool == DrawingToolType.line ||
          widget.activeTool == DrawingToolType.arrow ||
          widget.activeTool == DrawingToolType.circle) {
        if (_currentPoints.length > 1) {
          _currentPoints[1] = details.localPosition;
        } else {
          _currentPoints.add(details.localPosition);
        }
      }
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (widget.activeTool == DrawingToolType.none || _currentPoints.isEmpty) return;

    if (widget.activeTool != DrawingToolType.angleGoniometer) {
      widget.onObjectAdded(DrawingObject(
        type: widget.activeTool,
        points: List.from(_currentPoints),
        color: widget.strokeColor,
        strokeWidth: widget.strokeWidth,
      ));
      setState(() {
        _currentPoints = [];
      });
    }
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.activeTool == DrawingToolType.angleGoniometer) {
      setState(() {
        _currentPoints.add(details.localPosition);
        if (_currentPoints.length == 3) {
          final angle = GoniometerCalculator.calculateAngle(
            _currentPoints[0],
            _currentPoints[1],
            _currentPoints[2],
          );
          widget.onObjectAdded(DrawingObject(
            type: DrawingToolType.angleGoniometer,
            points: List.from(_currentPoints),
            color: widget.strokeColor,
            strokeWidth: widget.strokeWidth,
            calculatedAngle: angle,
          ));
          _currentPoints = [];
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: widget.activeTool == DrawingToolType.none
          ? HitTestBehavior.deferToChild
          : HitTestBehavior.opaque,
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      onTapDown: _onTapDown,
      child: CustomPaint(
        size: Size.infinite,
        painter: _AnnotationPainter(
          objects: widget.objects,
          currentTool: widget.activeTool,
          currentPoints: _currentPoints,
          currentColor: widget.strokeColor,
          currentWidth: widget.strokeWidth,
          showGrid: widget.showGrid,
          showPlumbLine: widget.showPlumbLine,
        ),
      ),
    );
  }
}

class _AnnotationPainter extends CustomPainter {
  final List<DrawingObject> objects;
  final DrawingToolType currentTool;
  final List<Offset> currentPoints;
  final Color currentColor;
  final double currentWidth;
  final bool showGrid;
  final bool showPlumbLine;

  _AnnotationPainter({
    required this.objects,
    required this.currentTool,
    required this.currentPoints,
    required this.currentColor,
    required this.currentWidth,
    required this.showGrid,
    required this.showPlumbLine,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. 方眼グリッド描画
    if (showGrid) {
      final gridPaint = Paint()
        ..color = Colors.cyan.withOpacity(0.18)
        ..strokeWidth = 0.8;
      const step = 40.0;
      for (double x = 0; x < size.width; x += step) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
      }
      for (double y = 0; y < size.height; y += step) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
      }
    }

    // 2. 鉛直プラムライン & 水平基準線描画
    if (showPlumbLine) {
      final plumbPaint = Paint()
        ..color = Colors.redAccent.withOpacity(0.65)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke;

      final midX = size.width / 2;
      final midY = size.height / 2;
      // 鉛直垂線
      canvas.drawLine(Offset(midX, 0), Offset(midX, size.height), plumbPaint);
      // 水平線
      canvas.drawLine(Offset(0, midY), Offset(size.width, midY), plumbPaint);
    }

    // 3. 確定済みアノテーションの描画
    for (final obj in objects) {
      _drawObject(canvas, obj.type, obj.points, obj.color, obj.strokeWidth, obj.calculatedAngle);
    }

    // 4. 現在ドラッグ描画中のオブジェクト描画
    if (currentPoints.isNotEmpty) {
      _drawObject(canvas, currentTool, currentPoints, currentColor, currentWidth, null);
    }
  }

  void _drawObject(Canvas canvas, DrawingToolType type, List<Offset> points,
      Color color, double width, double? angle) {
    if (points.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    switch (type) {
      case DrawingToolType.freehand:
        for (int i = 0; i < points.length - 1; i++) {
          canvas.drawLine(points[i], points[i + 1], paint);
        }
        break;

      case DrawingToolType.line:
        if (points.length >= 2) {
          canvas.drawLine(points[0], points[1], paint);
        }
        break;

      case DrawingToolType.arrow:
        if (points.length >= 2) {
          _drawArrow(canvas, points[0], points[1], paint);
        }
        break;

      case DrawingToolType.circle:
        if (points.length >= 2) {
          final rect = Rect.fromPoints(points[0], points[1]);
          canvas.drawOval(rect, paint);
        }
        break;

      case DrawingToolType.angleGoniometer:
        _drawGoniometer(canvas, points, color, width, angle);
        break;

      default:
        break;
    }
  }

  void _drawArrow(Canvas canvas, Offset start, Offset end, Paint paint) {
    canvas.drawLine(start, end, paint);
    const arrowLength = 16.0;
    const arrowAngle = 25.0 * (pi / 180.0);
    final angle = atan2(end.dy - start.dy, end.dx - start.dx);

    final p1 = Offset(
      end.dx - arrowLength * cos(angle - arrowAngle),
      end.dy - arrowLength * sin(angle - arrowAngle),
    );
    final p2 = Offset(
      end.dx - arrowLength * cos(angle + arrowAngle),
      end.dy - arrowLength * sin(angle + arrowAngle),
    );
    canvas.drawLine(end, p1, paint);
    canvas.drawLine(end, p2, paint);
  }

  void _drawGoniometer(Canvas canvas, List<Offset> points, Color color,
      double width, double? angle) {
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (int i = 0; i < points.length; i++) {
      canvas.drawCircle(points[i], 6.0, dotPaint);
      if (i > 0) {
        canvas.drawLine(points[i - 1], points[i], Paint()..color = color..strokeWidth = width);
      }
    }

    if (points.length == 3 && angle != null) {
      final textSpan = TextSpan(
        text: ' $angle° ',
        style: const TextStyle(
          color: Colors.black,
          fontSize: 15,
          fontWeight: FontWeight.bold,
          backgroundColor: Colors.yellow,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, points[1] + const Offset(10, -25));
    }
  }

  @override
  bool shouldRepaint(covariant _AnnotationPainter oldDelegate) => true;
}
