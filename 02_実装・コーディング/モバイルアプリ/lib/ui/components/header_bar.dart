import 'package:flutter/material.dart';
import '../../models/view_mode.dart';
import '../theme/app_theme.dart';

/// アプリ上部ヘッダーバー
class HeaderBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final ViewMode currentViewMode;
  final ValueChanged<ViewMode> onViewModeChanged;
  final VoidCallback onExportImage;
  final VoidCallback onExportVideo;
  final VoidCallback onImportStopwatchCsv;
  final VoidCallback onImportSensorCsv;
  final VoidCallback onSaveProject;
  final VoidCallback onRestoreProject;

  const HeaderBar({
    super.key,
    required this.title,
    required this.currentViewMode,
    required this.onViewModeChanged,
    required this.onExportImage,
    required this.onExportVideo,
    required this.onImportStopwatchCsv,
    required this.onImportSensorCsv,
    required this.onSaveProject,
    required this.onRestoreProject,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56.0);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Row(
        children: [
          const Icon(Icons.analytics_outlined, color: AppTheme.primary, size: 22),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      actions: [
        // 表示モード切り替えボタングループ
        SegmentedButton<ViewMode>(
          segments: const [
            ButtonSegment(
              value: ViewMode.single,
              label: Text('1画面', style: TextStyle(fontSize: 11)),
              icon: Icon(Icons.crop_portrait, size: 14),
            ),
            ButtonSegment(
              value: ViewMode.splitHorizontal,
              label: Text('並列', style: TextStyle(fontSize: 11)),
              icon: Icon(Icons.splitscreen, size: 14),
            ),
            ButtonSegment(
              value: ViewMode.ghostOverlay,
              label: Text('ゴースト', style: TextStyle(fontSize: 11)),
              icon: Icon(Icons.layers, size: 14),
            ),
          ],
          selected: {currentViewMode},
          onSelectionChanged: (Set<ViewMode> selected) {
            onViewModeChanged(selected.first);
          },
          style: ButtonStyle(
            visualDensity: VisualDensity.compact,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        const SizedBox(width: 8),

        // データ読み込み＆エクスポートメニュー
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: AppTheme.primary),
          tooltip: 'メニュー',
          onSelected: (value) {
            if (value == 'png') {
              onExportImage();
            } else if (value == 'mp4') {
              onExportVideo();
            } else if (value == 'csv_sw') {
              onImportStopwatchCsv();
            } else if (value == 'csv_sensor') {
              onImportSensorCsv();
            } else if (value == 'project_save') {
              onSaveProject();
            } else if (value == 'project_restore') {
              onRestoreProject();
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'project_save',
              child: Row(
                children: [
                  Icon(Icons.save_outlined, size: 18, color: AppTheme.accentYellow),
                  SizedBox(width: 8),
                  Text('プロジェクト分析状態を保存 (JSON)'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'project_restore',
              child: Row(
                children: [
                  Icon(Icons.restore_page_outlined, size: 18, color: AppTheme.accentYellow),
                  SizedBox(width: 8),
                  Text('プロジェクト分析状態を復元 (JSON)'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'csv_sw',
              child: Row(
                children: [
                  Icon(Icons.timer_outlined, size: 18, color: AppTheme.accentGreen),
                  SizedBox(width: 8),
                  Text('ストップウォッチCSV読み込み (LinkLog)'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'csv_sensor',
              child: Row(
                children: [
                  Icon(Icons.show_chart, size: 18, color: AppTheme.primary),
                  SizedBox(width: 8),
                  Text('加速度センサーCSV読み込み (WITMOTION)'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'png',
              child: Row(
                children: [
                  Icon(Icons.image, size: 18),
                  SizedBox(width: 8),
                  Text('静止画PNG保存 (計測線・角度含む)'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'mp4',
              child: Row(
                children: [
                  Icon(Icons.video_file, size: 18),
                  SizedBox(width: 8),
                  Text('合成動画MP4出力 (HUD・2画面連動)'),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}
