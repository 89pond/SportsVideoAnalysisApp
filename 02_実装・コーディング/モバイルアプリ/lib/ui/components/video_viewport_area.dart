import 'package:flutter/material.dart';
import '../../models/view_mode.dart';
import '../../models/drawing_object.dart';
import '../theme/app_theme.dart';
import 'annotation_canvas.dart';

/// 動画表示ビューポートエリア (1画面 / 2画面並列 / 透過ゴースト切替)
class VideoViewportArea extends StatelessWidget {
  final ViewMode viewMode;
  final double ghostOpacity;
  final ValueChanged<double> onGhostOpacityChanged;
  final DrawingToolType activeTool;
  final List<DrawingObject> drawingObjects;
  final Function(DrawingObject) onDrawingAdded;

  const VideoViewportArea({
    super.key,
    required this.viewMode,
    required this.ghostOpacity,
    required this.onGhostOpacityChanged,
    required this.activeTool,
    required this.drawingObjects,
    required this.onDrawingAdded,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 背景: 動画表示レイアウト
        Positioned.fill(
          child: _buildVideoLayout(context),
        ),

        // 透過ゴーストモード時の不透明度スライダー
        if (viewMode == ViewMode.ghostOverlay)
          Positioned(
            top: 10,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.accentPurple, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.opacity, size: 14, color: AppTheme.accentPurple),
                  const SizedBox(width: 4),
                  Text(
                    'ゴースト透過: ${(ghostOpacity * 100).toInt()}%',
                    style: const TextStyle(fontSize: 11, color: Colors.white),
                  ),
                  SizedBox(
                    width: 100,
                    child: Slider(
                      value: ghostOpacity,
                      min: 0.0,
                      max: 1.0,
                      activeColor: AppTheme.accentPurple,
                      onChanged: onGhostOpacityChanged,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // 最前面: アノテーション・角度計測キャンバス
        Positioned.fill(
          child: AnnotationCanvas(
            activeTool: activeTool,
            objects: drawingObjects,
            onObjectAdded: onDrawingAdded,
          ),
        ),
      ],
    );
  }

  Widget _buildVideoLayout(BuildContext context) {
    switch (viewMode) {
      case ViewMode.single:
        return _videoContainer(label: '動画 A (メイン)', color: AppTheme.primary, isGhost: false);

      case ViewMode.splitHorizontal:
        return Row(
          children: [
            Expanded(child: _videoContainer(label: '動画 A (自選手)', color: AppTheme.primary, isGhost: false)),
            Container(width: 2, color: Colors.white24),
            Expanded(child: _videoContainer(label: '動画 B (お手本)', color: AppTheme.secondary, isGhost: false)),
          ],
        );

      case ViewMode.splitVertical:
        return Column(
          children: [
            Expanded(child: _videoContainer(label: '動画 A (自選手)', color: AppTheme.primary, isGhost: false)),
            Container(height: 2, color: Colors.white24),
            Expanded(child: _videoContainer(label: '動画 B (お手本)', color: AppTheme.secondary, isGhost: false)),
          ],
        );

      case ViewMode.ghostOverlay:
        return Stack(
          children: [
            Positioned.fill(
              child: _videoContainer(label: '動画 A (ベース)', color: AppTheme.primary, isGhost: false),
            ),
            Positioned.fill(
              child: Opacity(
                opacity: ghostOpacity,
                child: _videoContainer(label: '動画 B (ゴースト)', color: AppTheme.secondary, isGhost: true),
              ),
            ),
          ],
        );
    }
  }

  Widget _videoContainer({required String label, required Color color, required bool isGhost}) {
    return Container(
      color: isGhost ? Colors.transparent : const Color(0xFF161920),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.movie_outlined, size: 48, color: color.withOpacity(0.4)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: color.withOpacity(0.5)),
              ),
              child: Text(
                label,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
