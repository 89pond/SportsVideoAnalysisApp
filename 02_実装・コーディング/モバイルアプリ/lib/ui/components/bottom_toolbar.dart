import 'package:flutter/material.dart';
import '../../models/view_mode.dart';
import '../theme/app_theme.dart';

/// 画面下部ツールバー: 同期オフセット微調整 ＆ 描画ツールパレット
class BottomToolbar extends StatelessWidget {
  final double offsetSeconds;
  final ValueChanged<double> onOffsetChanged;
  final DrawingToolType activeTool;
  final ValueChanged<DrawingToolType> onToolChanged;
  final VoidCallback onClearDrawings;

  const BottomToolbar({
    super.key,
    required this.offsetSeconds,
    required this.onOffsetChanged,
    required this.activeTool,
    required this.onToolChanged,
    required this.onClearDrawings,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 上段: 同期オフセット微調整
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.sync, size: 16, color: AppTheme.primary),
                  SizedBox(width: 4),
                  Text('同期オフセット:', style: TextStyle(fontSize: 11, color: Colors.white70)),
                ],
              ),
              Row(
                children: [
                  _offsetBtn('-0.05s', () => onOffsetChanged(offsetSeconds - 0.05)),
                  _offsetBtn('-0.01s', () => onOffsetChanged(offsetSeconds - 0.01)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.cardColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${offsetSeconds >= 0 ? '+' : ''}${offsetSeconds.toStringAsFixed(2)}s',
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        color: AppTheme.accentYellow,
                      ),
                    ),
                  ),
                  _offsetBtn('+0.01s', () => onOffsetChanged(offsetSeconds + 0.01)),
                  _offsetBtn('+0.05s', () => onOffsetChanged(offsetSeconds + 0.05)),
                  IconButton(
                    onPressed: () => onOffsetChanged(0.0),
                    icon: const Icon(Icons.restart_alt, size: 18),
                    tooltip: 'オフセットリセット',
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ],
          ),

          const Divider(height: 8, color: Colors.white12),

          // 下段: 描画ツールパレット
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _toolBtn(Icons.pan_tool_alt_outlined, DrawingToolType.none, '選択'),
              _toolBtn(Icons.edit, DrawingToolType.freehand, 'ペン'),
              _toolBtn(Icons.horizontal_rule, DrawingToolType.line, '直線'),
              _toolBtn(Icons.arrow_right_alt, DrawingToolType.arrow, '矢印'),
              _toolBtn(Icons.circle_outlined, DrawingToolType.circle, '円'),
              _toolBtn(Icons.architecture, DrawingToolType.angleGoniometer, '角度'),
              IconButton(
                onPressed: onClearDrawings,
                icon: const Icon(Icons.delete_outline, color: AppTheme.secondary, size: 20),
                tooltip: '全消去',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _offsetBtn(String label, VoidCallback onPressed) {
    return SizedBox(
      height: 24,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          visualDensity: VisualDensity.compact,
          side: const BorderSide(color: Colors.white24),
        ),
        child: Text(label, style: const TextStyle(fontSize: 10, color: Colors.white)),
      ),
    );
  }

  Widget _toolBtn(IconData icon, DrawingToolType tool, String tooltip) {
    final isSelected = activeTool == tool;
    return IconButton(
      onPressed: () => onToolChanged(tool),
      icon: Icon(icon, size: 20),
      color: isSelected ? AppTheme.accentYellow : Colors.white60,
      style: isSelected
          ? IconButton.styleFrom(backgroundColor: AppTheme.cardColor)
          : null,
      tooltip: tooltip,
    );
  }
}
