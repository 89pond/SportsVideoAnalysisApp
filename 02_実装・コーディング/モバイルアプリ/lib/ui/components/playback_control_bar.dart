import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// 再生制御・コマ送り・同期ロックバー
class PlaybackControlBar extends StatelessWidget {
  final bool isPlaying;
  final double playbackSpeed;
  final bool isSyncLocked;
  final Duration currentPosition;
  final Duration totalDuration;
  final VoidCallback onPlayPause;
  final VoidCallback onStepBackward;
  final VoidCallback onStepForward;
  final ValueChanged<double> onSpeedChanged;
  final VoidCallback onToggleSyncLock;
  final ValueChanged<double> onSeek;

  const PlaybackControlBar({
    super.key,
    required this.isPlaying,
    required this.playbackSpeed,
    required this.isSyncLocked,
    required this.currentPosition,
    required this.totalDuration,
    required this.onPlayPause,
    required this.onStepBackward,
    required this.onStepForward,
    required this.onSpeedChanged,
    required this.onToggleSyncLock,
    required this.onSeek,
  });

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final millis = (d.inMilliseconds.remainder(1000) ~/ 10).toString().padLeft(2, '0');
    return '$minutes:$seconds.$millis';
  }

  @override
  Widget build(BuildContext context) {
    final maxMs = totalDuration.inMilliseconds > 0 ? totalDuration.inMilliseconds.toDouble() : 1.0;
    final curMs = currentPosition.inMilliseconds.toDouble().clamp(0.0, maxMs);

    return Container(
      color: AppTheme.cardColor,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // シークバーとタイムコード
          Row(
            children: [
              Text(
                _formatDuration(currentPosition),
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: AppTheme.primary),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3.0,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
                  ),
                  child: Slider(
                    value: curMs,
                    min: 0.0,
                    max: maxMs,
                    onChanged: onSeek,
                  ),
                ),
              ),
              Text(
                _formatDuration(totalDuration),
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: Colors.white60),
              ),
            ],
          ),

          // 再生ボタングループ
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 同期ロック / 個別アンロック 切り替え
              ElevatedButton.icon(
                onPressed: onToggleSyncLock,
                icon: Icon(
                  isSyncLocked ? Icons.lock : Icons.lock_open,
                  size: 16,
                  color: isSyncLocked ? AppTheme.accentGreen : AppTheme.secondary,
                ),
                label: Text(
                  isSyncLocked ? '同期ロック中' : '個別調整中',
                  style: TextStyle(
                    fontSize: 11,
                    color: isSyncLocked ? AppTheme.accentGreen : AppTheme.secondary,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.surface,
                  visualDensity: VisualDensity.compact,
                ),
              ),

              // 中央コントローラー群 (コマ戻し / 再生停止 / コマ送り)
              Row(
                children: [
                  IconButton(
                    onPressed: onStepBackward,
                    icon: const Icon(Icons.skip_previous, size: 26),
                    tooltip: '1フレームコマ戻し (33ms)',
                  ),
                  IconButton.filled(
                    onPressed: onPlayPause,
                    icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow, size: 28),
                    style: IconButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.black),
                  ),
                  IconButton(
                    onPressed: onStepForward,
                    icon: const Icon(Icons.skip_next, size: 26),
                    tooltip: '1フレームコマ送り (33ms)',
                  ),
                ],
              ),

              // スロー再生速度ドロップダウン
              DropdownButton<double>(
                value: playbackSpeed,
                dropdownColor: AppTheme.surface,
                style: const TextStyle(fontSize: 12, color: Colors.white),
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: 0.1, child: Text('0.10x スロー')),
                  DropdownMenuItem(value: 0.25, child: Text('0.25x スロー')),
                  DropdownMenuItem(value: 0.5, child: Text('0.50x スロー')),
                  DropdownMenuItem(value: 1.0, child: Text('1.00x 通常')),
                ],
                onChanged: (val) {
                  if (val != null) onSpeedChanged(val);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
