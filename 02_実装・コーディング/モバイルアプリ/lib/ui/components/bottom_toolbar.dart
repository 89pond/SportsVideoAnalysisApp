import 'package:flutter/material.dart';
import '../../models/view_mode.dart';
import '../theme/app_theme.dart';

/// 画面下部ツールバー: 同期オフセット微調整 ＆ 描画ツールパレット ＆ グリッド・カラー
class BottomToolbar extends StatelessWidget {
  final double offsetSeconds;
  final ValueChanged<double> onOffsetChanged;
  final DrawingToolType activeTool;
  final ValueChanged<DrawingToolType> onToolChanged;
  final Color selectedColor;
  final ValueChanged<Color> onColorChanged;
  final bool showGrid;
  final VoidCallback onToggleGrid;
  final bool showPlumbLine;
  final VoidCallback onTogglePlumbLine;
  final VoidCallback onClearDrawings;

  const BottomToolbar({
    super.key,
    required this.offsetSeconds,
    required this.onOffsetChanged,
    required this.activeTool,
    required this.onToolChanged,
    required this.selectedColor,
    required this.onColorChanged,
    required this.showGrid,
    required this.onToggleGrid,
    required this.showPlumbLine,
    required this.onTogglePlumbLine,
    required this.onClearDrawings,
  });

  @override
  Widget build(BuildContext context) {
    const availableColors = [
      Colors.yellow,
      Colors.cyanAccent,
      Colors.redAccent,
      Colors.greenAccent,
    ];

    return Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 上段: 同期オフセット微調整 & アライメントトグル
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // アライメント (方眼グリッド・プラムライン)
              Row(
                children: [
                  IconButton(
                    onPressed: onToggleGrid,
                    icon: Icon(
                      Icons.grid_on,
                      size: 18,
                      color: showGrid ? AppTheme.primary : Colors.white38,
                    ),
                    tooltip: '方眼グリッド重畳',
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    onPressed: onTogglePlumbLine,
                    icon: Icon(
                      Icons.straighten,
                      size: 18,
                      color: showPlumbLine ? Colors.redAccent : Colors.white38,
                    ),
                    tooltip: '鉛直プラムライン(垂線)重畳',
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),

              // オフセット微調整
              Row(
                children: [
                  _offsetBtn('-0.05s', () => onOffsetChanged(offsetSeconds - 0.05)),
                  _offsetBtn('-0.01s', () => onOffsetChanged(offsetSeconds - 0.01)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.cardColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${offsetSeconds >= 0 ? '+' : ''}${offsetSeconds.toStringAsFixed(2)}s',
                      style: const TextStyle(
                        fontSize: 11,
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
                    icon: const Icon(Icons.restart_alt, size: 16),
                    tooltip: 'オフセットリセット',
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ],
          ),

          const Divider(height: 6, color: Colors.white12),

          // 下段: 描画ツールパレット & カラーパレット
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 描画ツール群
              Row(
                children: [
                  _toolBtn(Icons.pan_tool_alt_outlined, DrawingToolType.none, '選択'),
                  _toolBtn(Icons.edit, DrawingToolType.freehand, 'ペン'),
                  _toolBtn(Icons.horizontal_rule, DrawingToolType.line, '直線'),
                  _toolBtn(Icons.arrow_right_alt, DrawingToolType.arrow, '矢印'),
                  _toolBtn(Icons.circle_outlined, DrawingToolType.circle, '円'),
                  _toolBtn(Icons.architecture, DrawingToolType.angleGoniometer, '角度'),
                  IconButton(
                    onPressed: onClearDrawings,
                    icon: const Icon(Icons.delete_outline, color: AppTheme.secondary, size: 18),
                    tooltip: '全消去',
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),

              // カラーパレット
              Row(
                children: availableColors.map((c) {
                  final isSelected = selectedColor.value == c.value;
                  return GestureDetector(
                    onTap: () => onColorChanged(c),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _offsetBtn(String label, VoidCallback onPressed) {
    return SizedBox(
      height: 22,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 5),
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
      icon: Icon(icon, size: 18),
      color: isSelected ? AppTheme.accentYellow : Colors.white60,
      style: isSelected ? IconButton.styleFrom(backgroundColor: AppTheme.cardColor) : null,
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
    );
  }
}
