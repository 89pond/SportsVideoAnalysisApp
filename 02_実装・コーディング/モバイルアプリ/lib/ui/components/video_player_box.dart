import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../../services/dual_video_controller.dart';
import '../theme/app_theme.dart';

/// 個別動画プレイヤーボックス (ピンチズーム・パン・ファイルローダー対応)
class VideoPlayerBox extends StatelessWidget {
  final VideoSlot slot;
  final String label;
  final Color themeColor;
  final VideoController? videoController;
  final bool hasVideo;
  final String? filePath;
  final Duration position;
  final bool isActive;
  final bool isGhost;
  final VoidCallback onTapSelect;
  final VoidCallback onLoadFile;

  const VideoPlayerBox({
    super.key,
    required this.slot,
    required this.label,
    required this.themeColor,
    this.videoController,
    required this.hasVideo,
    this.filePath,
    required this.position,
    this.isActive = false,
    this.isGhost = false,
    required this.onTapSelect,
    required this.onLoadFile,
  });

  String _formatPosition(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final ms = (d.inMilliseconds.remainder(1000) ~/ 10).toString().padLeft(2, '0');
    return '$m:$s.$ms';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTapSelect,
      child: Container(
        decoration: BoxDecoration(
          color: isGhost ? Colors.transparent : const Color(0xFF14171E),
          border: isActive && !isGhost
              ? Border.all(color: themeColor, width: 2)
              : Border.all(color: Colors.white12, width: 1),
        ),
        child: Stack(
          children: [
            // 1. 動画レンダラー または 未読み込みプレースホルダー (ピンチズーム・パン内包)
            Positioned.fill(
              child: InteractiveViewer(
                minScale: 1.0,
                maxScale: 5.0,
                child: Center(
                  child: hasVideo && videoController != null
                      ? Video(controller: videoController!)
                      : _buildPlaceholder(context),
                ),
              ),
            ),

            // 2. 上部ヘッダーバッジ (ラベル・タイムコード)
            Positioned(
              top: 6,
              left: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.75),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: themeColor.withOpacity(0.6), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(color: themeColor, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      label,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: themeColor),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatPosition(position),
                      style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),

            // 3. 動画読み込みボタン (右上)
            if (!isGhost)
              Positioned(
                top: 4,
                right: 4,
                child: IconButton(
                  onPressed: onLoadFile,
                  icon: const Icon(Icons.file_open_outlined, size: 16),
                  color: Colors.white70,
                  tooltip: '$label ファイルを開く',
                  visualDensity: VisualDensity.compact,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.video_library_outlined, size: 36, color: themeColor.withOpacity(0.4)),
        const SizedBox(height: 6),
        Text(
          filePath != null ? filePath!.split(r'[\/]').last : '$label 未設定',
          style: TextStyle(fontSize: 11, color: themeColor.withOpacity(0.8), fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 26,
          child: OutlinedButton.icon(
            onPressed: onLoadFile,
            icon: const Icon(Icons.add, size: 14),
            label: const Text('動画を選択', style: TextStyle(fontSize: 10)),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(color: themeColor.withOpacity(0.5)),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              visualDensity: VisualDensity.compact,
            ),
          ),
        ),
      ],
    );
  }
}
