import 'package:flutter/material.dart';
import '../../models/view_mode.dart';
import '../../models/drawing_object.dart';
import '../../services/dual_video_controller.dart';
import '../theme/app_theme.dart';
import 'annotation_canvas.dart';
import 'video_player_box.dart';

/// 動画表示ビューポートエリア (1画面 / 2画面並列 / 透過ゴースト切替)
class VideoViewportArea extends StatelessWidget {
  final ViewMode viewMode;
  final double ghostOpacity;
  final ValueChanged<double> onGhostOpacityChanged;
  final DrawingToolType activeTool;
  final List<DrawingObject> drawingObjects;
  final Function(DrawingObject) onDrawingAdded;

  // デュアル動画コントローラープロパティ
  final DualVideoSyncController? controller;
  final VoidCallback onLoadVideoA;
  final VoidCallback onLoadVideoB;

  const VideoViewportArea({
    super.key,
    required this.viewMode,
    required this.ghostOpacity,
    required this.onGhostOpacityChanged,
    required this.activeTool,
    required this.drawingObjects,
    required this.onDrawingAdded,
    this.controller,
    required this.onLoadVideoA,
    required this.onLoadVideoB,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. 動画表示レイアウト (下層)
        Positioned.fill(
          child: _buildVideoLayout(context),
        ),

        // 2. 透過ゴーストモード時の不透明度スライダー (右上オーバーレイ)
        if (viewMode == ViewMode.ghostOverlay)
          Positioned(
            top: 10,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.accentPurple, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.opacity, size: 14, color: AppTheme.accentPurple),
                  const SizedBox(width: 4),
                  Text(
                    '透過度: ${(ghostOpacity * 100).toInt()}%',
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

        // 3. 最前面: アノテーション・角度計測キャンバス
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
    final c = controller;

    final boxA = VideoPlayerBox(
      slot: VideoSlot.videoA,
      label: '動画 A (自選手)',
      themeColor: AppTheme.primary,
      videoController: c?.videoControllerA,
      hasVideo: c?.hasVideoA ?? false,
      filePath: c?.filePathA,
      position: c?.positionA ?? Duration.zero,
      isActive: c?.activeSlot == VideoSlot.videoA,
      onTapSelect: () => c?.setActiveSlot(VideoSlot.videoA),
      onLoadFile: onLoadVideoA,
    );

    final boxB = VideoPlayerBox(
      slot: VideoSlot.videoB,
      label: '動画 B (お手本)',
      themeColor: AppTheme.secondary,
      videoController: c?.videoControllerB,
      hasVideo: c?.hasVideoB ?? false,
      filePath: c?.filePathB,
      position: c?.positionB ?? Duration.zero,
      isActive: c?.activeSlot == VideoSlot.videoB,
      onTapSelect: () => c?.setActiveSlot(VideoSlot.videoB),
      onLoadFile: onLoadVideoB,
    );

    switch (viewMode) {
      case ViewMode.single:
        return boxA;

      case ViewMode.splitHorizontal:
        return Row(
          children: [
            Expanded(child: boxA),
            Container(width: 2, color: Colors.white24),
            Expanded(child: boxB),
          ],
        );

      case ViewMode.splitVertical:
        return Column(
          children: [
            Expanded(child: boxA),
            Container(height: 2, color: Colors.white24),
            Expanded(child: boxB),
          ],
        );

      case ViewMode.ghostOverlay:
        return Stack(
          children: [
            Positioned.fill(child: boxA),
            Positioned.fill(
              child: Opacity(
                opacity: ghostOpacity,
                child: VideoPlayerBox(
                  slot: VideoSlot.videoB,
                  label: '動画 B (ゴースト)',
                  themeColor: AppTheme.secondary,
                  videoController: c?.videoControllerB,
                  hasVideo: c?.hasVideoB ?? false,
                  filePath: c?.filePathB,
                  position: c?.positionB ?? Duration.zero,
                  isGhost: true,
                  onTapSelect: () {},
                  onLoadFile: onLoadVideoB,
                ),
              ),
            ),
          ],
        );
    }
  }
}
