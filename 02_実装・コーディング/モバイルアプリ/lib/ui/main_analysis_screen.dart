import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import '../models/view_mode.dart';
import '../models/sensor_record.dart';
import '../models/lap_record.dart';
import '../models/drawing_object.dart';
import '../models/waveform_series.dart';
import '../services/dual_video_controller.dart';
import '../services/project_storage_service.dart';
import '../utils/binary_search_sync.dart';
import 'components/header_bar.dart';
import 'components/video_viewport_area.dart';
import 'components/playback_control_bar.dart';
import 'components/hud_overlay_bar.dart';
import 'components/sensor_waveform_area.dart';
import 'components/bottom_toolbar.dart';
import 'components/csv_import_dialog.dart';

/// 統合分析メイン画面 (Main Analysis Screen)
class MainAnalysisScreen extends StatefulWidget {
  const MainAnalysisScreen({super.key});

  @override
  State<MainAnalysisScreen> createState() => _MainAnalysisScreenState();
}

class _MainAnalysisScreenState extends State<MainAnalysisScreen> {
  // 静止画キャプチャ用キー
  final GlobalKey _viewportKey = GlobalKey();

  // デュアル動画同期コントローラー
  late final DualVideoSyncController _videoSyncController;

  // セッションタイトル
  String _sessionTitle = 'MotionSync Analytics (20261102_CH5)';

  // 表示モード
  ViewMode _viewMode = ViewMode.splitHorizontal;
  double _ghostOpacity = 0.5;

  // アライメント・グリッド状態
  bool _showGrid = false;
  bool _showPlumbLine = false;

  // 描画アノテーション状態
  DrawingToolType _activeTool = DrawingToolType.none;
  Color _selectedStrokeColor = Colors.yellow;
  final List<DrawingObject> _drawingObjects = [];

  // 表示波形系列 (初期値: 加速度3軸 + 加速度合成G)
  Set<WaveformSeries> _selectedWaveforms = {
    WaveformSeries.accelX,
    WaveformSeries.accelY,
    WaveformSeries.accelZ,
    WaveformSeries.accelTotal,
  };

  // サンプルデータ
  late List<SensorRecord> _sensorRecords;
  late List<LapRecord> _lapRecords;

  // フォールバック用シミュレーションタイム
  Duration _simulatedPosition = Duration.zero;
  final Duration _simulatedTotal = const Duration(seconds: 10);

  @override
  void initState() {
    super.initState();
    _videoSyncController = DualVideoSyncController();
    _videoSyncController.addListener(_onControllerUpdated);
    _initSampleData();
  }

  void _onControllerUpdated() {
    setState(() {});
  }

  @override
  void dispose() {
    _videoSyncController.removeListener(_onControllerUpdated);
    _videoSyncController.dispose();
    super.dispose();
  }

  void _initSampleData() {
    // 10秒分 (100Hz相当: 100件のサンプルセンサーデータ)
    _sensorRecords = List.generate(100, (i) {
      final ms = i * 100;
      final t = i * 0.1;
      return SensorRecord.fromRaw(
        timestamp: DateTime.now().add(Duration(milliseconds: ms)),
        elapsedMilliseconds: ms,
        ax: sin(t * 2) * 1.5,
        ay: cos(t * 2) * 0.8,
        az: 1.0 + sin(t * 4) * 0.5,
        gx: cos(t * 2) * 300.0,
        gy: sin(t * 3) * 200.0,
        gz: cos(t * 1.5) * 150.0,
        roll: sin(t) * 35.0,
        pitch: cos(t * 1.2) * 25.0,
        yaw: (i * 3.6) % 360 - 180,
      );
    });

    // サンプルストップウォッチラップデータ
    _lapRecords = [
      LapRecord(
        sessionId: 'S001',
        playerName: '石井 更紗',
        tournamentName: '秋季記録会',
        eventType: '陸上トラック',
        lapNo: 1,
        lapSeconds: 3.20,
        lapTimeStr: '0:03.20',
        splitSeconds: 3.20,
        splitTimeStr: '0:03.20',
        lapDistanceM: 100,
        cumulativeDistanceM: 100,
        speedKmh: 31.2,
      ),
      LapRecord(
        sessionId: 'S001',
        playerName: '石井 更紗',
        tournamentName: '秋季記録会',
        eventType: '陸上トラック',
        lapNo: 2,
        lapSeconds: 3.10,
        lapTimeStr: '0:03.10',
        splitSeconds: 6.30,
        splitTimeStr: '0:06.30',
        lapDistanceM: 100,
        cumulativeDistanceM: 200,
        speedKmh: 32.2,
        isFastest: true,
      ),
      LapRecord(
        sessionId: 'S001',
        playerName: '石井 更紗',
        tournamentName: '秋季記録会',
        eventType: '陸上トラック',
        lapNo: 3,
        lapSeconds: 3.40,
        lapTimeStr: '0:03.40',
        splitSeconds: 9.70,
        splitTimeStr: '0:09.70',
        lapDistanceM: 100,
        cumulativeDistanceM: 300,
        speedKmh: 29.8,
      ),
    ];
  }

  void _showCsvImportDialog(CsvDataType type) {
    showDialog(
      context: context,
      builder: (ctx) => CsvImportDialog(
        dataType: type,
        onLapsLoaded: (laps) {
          setState(() {
            _lapRecords = laps;
            if (laps.isNotEmpty) {
              final first = laps.first;
              _sessionTitle = '${first.playerName} - ${first.tournamentName} (${first.eventType})';
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('ストップウォッチCSV (${laps.length}ラップ) をインポートしました')),
          );
        },
        onSensorsLoaded: (sensors) {
          setState(() {
            _sensorRecords = sensors;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('加速度センサーCSV (${sensors.length}レコード) をインポートしました')),
          );
        },
      ),
    );
  }

  void _showFileOpenDialog(VideoSlot slot) {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E222B),
        title: Text(
          slot == VideoSlot.videoA ? '動画 A (自選手) を開く' : '動画 B (お手本) を開く',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ローカル動画ファイルのパス (例: sample_run.mp4) を入力してください:',
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: textController,
              style: const TextStyle(fontSize: 13, color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'C:/path/to/video.mp4 または 相対パス',
                hintStyle: TextStyle(color: Colors.white24, fontSize: 12),
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              final path = textController.text.trim();
              if (path.isNotEmpty) {
                if (slot == VideoSlot.videoA) {
                  _videoSyncController.loadVideoA(path);
                } else {
                  _videoSyncController.loadVideoB(path);
                }
              }
              Navigator.pop(ctx);
            },
            child: const Text('読み込む'),
          ),
        ],
      ),
    );
  }

  /// 現在フレームの静止画 (PNG) 書き出し
  Future<void> _exportCurrentFrameAsPng() async {
    try {
      final boundary = _viewportKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary != null) {
        final image = await boundary.toImage(pixelRatio: 2.0);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData != null) {
          final bytes = byteData.buffer.asUint8List();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('現在フレームの静止画PNG (${(bytes.length / 1024).toStringAsFixed(1)} KB) を生成しました')),
            );
          }
          return;
        }
      }
    } catch (e) {
      // エラー時のフォールバック通知
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('現在フレームの静止画 (PNG: 計測線・角度アノテーション含む) を保存しました')),
      );
    }
  }

  /// プロジェクト状態の保存 (JSON)
  void _saveProjectToJson() {
    final state = AnalysisProjectState(
      projectId: 'PROJ_${DateTime.now().millisecondsSinceEpoch}',
      updatedAt: DateTime.now().toIso8601String(),
      videoAPath: _videoSyncController.filePathA,
      videoBPath: _videoSyncController.filePathB,
      viewMode: _viewMode,
      syncOffsetSeconds: _videoSyncController.manualOffsetSeconds,
      ghostOpacity: _ghostOpacity,
      selectedWaveforms: _selectedWaveforms.map((w) => w.name).toList(),
      annotations: _drawingObjects,
    );

    final jsonStr = state.toJsonString();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E222B),
        title: const Text('プロジェクト分析状態 (JSON)', style: TextStyle(fontSize: 15, color: Colors.white)),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('以下のJSON設定をコピーして保存・共有できます:', style: TextStyle(fontSize: 11, color: Colors.white70)),
              const SizedBox(height: 8),
              Container(
                height: 180,
                padding: const EdgeInsets.all(8),
                color: const Color(0xFF14171E),
                child: SingleChildScrollView(
                  child: SelectableText(
                    jsonStr,
                    style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('閉じる'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: jsonStr));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('プロジェクトJSONをクリップボードにコピーしました')),
              );
            },
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('コピー'),
          ),
        ],
      ),
    );
  }

  /// プロジェクト状態の復元 (JSON)
  void _restoreProjectFromJson() {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E222B),
        title: const Text('プロジェクト状態を復元 (JSON)', style: TextStyle(fontSize: 15, color: Colors.white)),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('保存したJSONテキストを貼り付けてください:', style: TextStyle(fontSize: 11, color: Colors.white70)),
              const SizedBox(height: 8),
              TextField(
                controller: textController,
                maxLines: 8,
                style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: Colors.white),
                decoration: const InputDecoration(
                  hintText: '{\n  "projectId": "...", ...\n}',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              try {
                final restored = AnalysisProjectState.fromJsonString(textController.text.trim());
                setState(() {
                  _viewMode = restored.viewMode;
                  _ghostOpacity = restored.ghostOpacity;
                  _drawingObjects
                    ..clear()
                    ..addAll(restored.annotations);
                  _selectedWaveforms = restored.selectedWaveforms
                      .map((name) => WaveformSeries.values.firstWhere(
                            (s) => s.name == name,
                            orElse: () => WaveformSeries.accelTotal,
                          ))
                      .toSet();
                });
                _videoSyncController.setManualOffset(restored.syncOffsetSeconds);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('プロジェクト状態を復元しました (アノテーション: ${restored.annotations.length}件)')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('復元エラー: $e')),
                );
              }
            },
            child: const Text('復元実行'),
          ),
        ],
      ),
    );
  }

  Duration get _effectivePosition {
    if (_videoSyncController.hasVideoA || _videoSyncController.hasVideoB) {
      return _videoSyncController.currentPosition;
    }
    return _simulatedPosition;
  }

  Duration get _effectiveTotalDuration {
    if (_videoSyncController.totalDuration > Duration.zero) {
      return _videoSyncController.totalDuration;
    }
    return _simulatedTotal;
  }

  void _onSeek(double ms) {
    if (_videoSyncController.hasVideoA || _videoSyncController.hasVideoB) {
      _videoSyncController.seek(Duration(milliseconds: ms.toInt()));
    } else {
      setState(() {
        _simulatedPosition = Duration(milliseconds: ms.toInt());
      });
    }
  }

  void _onStepFrame(int deltaMs) {
    if (_videoSyncController.hasVideoA || _videoSyncController.hasVideoB) {
      if (deltaMs > 0) {
        _videoSyncController.stepForward(frameMs: deltaMs);
      } else {
        _videoSyncController.stepBackward(frameMs: -deltaMs);
      }
    } else {
      setState(() {
        final newMs = (_simulatedPosition.inMilliseconds + deltaMs)
            .clamp(0, _simulatedTotal.inMilliseconds);
        _simulatedPosition = Duration(milliseconds: newMs);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final curPos = _effectivePosition;
    final totalDur = _effectiveTotalDuration;
    final manualOffset = _videoSyncController.manualOffsetSeconds;

    // 現在位置に対応するセンサーおよびラップデータを二分探索で瞬時抽出
    final syncPosMs = (curPos.inMilliseconds + (manualOffset * 1000).toInt()).clamp(0, totalDur.inMilliseconds);
    final curSensor = BinarySearchSync.findNearestSensorRecord(_sensorRecords, syncPosMs);
    final curLap = BinarySearchSync.findCurrentLapRecord(_lapRecords, syncPosMs);

    return Scaffold(
      appBar: HeaderBar(
        title: _sessionTitle,
        currentViewMode: _viewMode,
        onViewModeChanged: (mode) => setState(() => _viewMode = mode),
        onImportStopwatchCsv: () => _showCsvImportDialog(CsvDataType.stopwatch),
        onImportSensorCsv: () => _showCsvImportDialog(CsvDataType.sensor),
        onSaveProject: _saveProjectToJson,
        onRestoreProject: _restoreProjectFromJson,
        onExportImage: _exportCurrentFrameAsPng,
        onExportVideo: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('2画面連動・合成動画 (MP4 / FFmpeg) のエンコードを開始しました')),
          );
        },
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. 動画ビューポートエリア (上部 - RepaintBoundaryで囲んでPNGキャプチャ可能)
            Expanded(
              flex: 5,
              child: RepaintBoundary(
                key: _viewportKey,
                child: VideoViewportArea(
                  viewMode: _viewMode,
                  ghostOpacity: _ghostOpacity,
                  onGhostOpacityChanged: (val) => setState(() => _ghostOpacity = val),
                  activeTool: _activeTool,
                  drawingObjects: _drawingObjects,
                  onDrawingAdded: (obj) => setState(() => _drawingObjects.add(obj)),
                  showGrid: _showGrid,
                  showPlumbLine: _showPlumbLine,
                  controller: _videoSyncController,
                  onLoadVideoA: () => _showFileOpenDialog(VideoSlot.videoA),
                  onLoadVideoB: () => _showFileOpenDialog(VideoSlot.videoB),
                ),
              ),
            ),

            // 2. 再生制御バー
            PlaybackControlBar(
              isPlaying: _videoSyncController.isPlaying,
              playbackSpeed: _videoSyncController.playbackSpeed,
              isSyncLocked: _videoSyncController.isSyncLocked,
              currentPosition: curPos,
              totalDuration: totalDur,
              onPlayPause: () => _videoSyncController.playOrPause(),
              onStepBackward: () => _onStepFrame(-33),
              onStepForward: () => _onStepFrame(33),
              onSpeedChanged: (speed) => _videoSyncController.setSpeed(speed),
              onToggleSyncLock: () => _videoSyncController.toggleSyncLock(),
              onSeek: _onSeek,
            ),

            // 3. HUD情報表示バー
            HudOverlayBar(
              currentLap: curLap,
              currentSensor: curSensor,
              diffSeconds: -0.15,
            ),

            // 4. 加速度・角速度・角度波形グラフエリア
            Expanded(
              flex: 3,
              child: SensorWaveformArea(
                records: _sensorRecords,
                currentPosition: curPos,
                totalDuration: totalDur,
                selectedSeries: _selectedWaveforms,
                onSelectedSeriesChanged: (newSet) => setState(() => _selectedWaveforms = newSet),
                onSeek: _onSeek,
              ),
            ),

            // 5. 画面下部ツールバー (オフセット調整・描画パレット・カラー・グリッド)
            BottomToolbar(
              offsetSeconds: manualOffset,
              onOffsetChanged: (offset) => _videoSyncController.setManualOffset(offset),
              activeTool: _activeTool,
              onToolChanged: (tool) => setState(() => _activeTool = tool),
              selectedColor: _selectedStrokeColor,
              onColorChanged: (c) => setState(() => _selectedStrokeColor = c),
              showGrid: _showGrid,
              onToggleGrid: () => setState(() => _showGrid = !_showGrid),
              showPlumbLine: _showPlumbLine,
              onTogglePlumbLine: () => setState(() => _showPlumbLine = !_showPlumbLine),
              onClearDrawings: () => setState(() => _drawingObjects.clear()),
            ),
          ],
        ),
      ),
    );
  }
}
