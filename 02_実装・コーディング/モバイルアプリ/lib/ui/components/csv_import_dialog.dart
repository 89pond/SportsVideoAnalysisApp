import 'package:flutter/material.dart';
import '../../services/csv_parse_service.dart';
import '../../models/lap_record.dart';
import '../../models/sensor_record.dart';
import '../theme/app_theme.dart';

enum CsvDataType { stopwatch, sensor }

/// CSVファイル読み込み・インポートダイアログ
class CsvImportDialog extends StatefulWidget {
  final CsvDataType dataType;
  final Function(List<LapRecord>)? onLapsLoaded;
  final Function(List<SensorRecord>)? onSensorsLoaded;

  const CsvImportDialog({
    super.key,
    required this.dataType,
    this.onLapsLoaded,
    this.onSensorsLoaded,
  });

  @override
  State<CsvImportDialog> createState() => _CsvImportDialogState();
}

class _CsvImportDialogState extends State<CsvImportDialog> {
  final _textController = TextEditingController();
  String? _errorMessage;

  void _onImport() {
    final content = _textController.text.trim();
    if (content.isEmpty) {
      setState(() => _errorMessage = 'CSV内容またはファイルパスを入力してください');
      return;
    }

    try {
      if (widget.dataType == CsvDataType.stopwatch) {
        final laps = CsvParseService.parseStopWatchLinkLogCsv(content);
        if (laps.isEmpty) {
          setState(() => _errorMessage = '有効なストップウォッチラップデータを検出できませんでした');
          return;
        }
        widget.onLapsLoaded?.call(laps);
      } else {
        final sensors = CsvParseService.parseWitmotionSensorCsv(content);
        if (sensors.isEmpty) {
          setState(() => _errorMessage = '有効なセンサー加速度データを検出できませんでした');
          return;
        }
        widget.onSensorsLoaded?.call(sensors);
      }
      Navigator.pop(context);
    } catch (e) {
      setState(() => _errorMessage = 'パースエラー: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isStopwatch = widget.dataType == CsvDataType.stopwatch;
    final title = isStopwatch ? 'ストップウォッチ計測CSV (LinkLog)' : '加速度センサーCSV (WITMOTION)';
    final hint = isStopwatch
        ? 'session_id,player_name,...\n"20261102_CH5","石井 更紗",...'
        : 'Time,Device name,Chip Time(),Acceleration X(g),...\n\t2026-11-07 12:00:00.000,,0.012,0.984,...';

    return AlertDialog(
      backgroundColor: AppTheme.surface,
      title: Row(
        children: [
          Icon(
            isStopwatch ? Icons.timer_outlined : Icons.show_chart,
            color: isStopwatch ? AppTheme.accentGreen : AppTheme.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$title をインポート',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isStopwatch
                  ? 'LinkLog形式の全22カラムCSVテキストを入力または貼り付けてください:'
                  : '31列構成のWITMOTION加速度・角速度CSVテキストを入力してください:',
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _textController,
              maxLines: 6,
              style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Colors.white),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: Colors.white24, fontSize: 10),
                border: const OutlineInputBorder(),
                isDense: true,
                filled: true,
                fillColor: AppTheme.cardColor,
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: const TextStyle(fontSize: 11, color: AppTheme.secondary),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
        ElevatedButton(
          onPressed: _onImport,
          style: ElevatedButton.styleFrom(
            backgroundColor: isStopwatch ? AppTheme.accentGreen : AppTheme.primary,
            foregroundColor: Colors.black,
          ),
          child: const Text('インポート実行'),
        ),
      ],
    );
  }
}
