import 'dart:math';
import 'package:flutter/material.dart';
import '../models/view_mode.dart';
import '../models/sensor_record.dart';
import '../models/lap_record.dart';
import '../models/drawing_object.dart';
import '../models/waveform_series.dart';
import '../utils/binary_search_sync.dart';
import 'components/header_bar.dart';
import 'components/video_viewport_area.dart';
import 'components/playback_control_bar.dart';
import 'components/hud_overlay_bar.dart';
import 'components/sensor_waveform_area.dart';
import 'components/bottom_toolbar.dart';

/// 統合分析メイン画面 (Main Analysis Screen)
class MainAnalysisScreen extends StatefulWidget {
  const MainAnalysisScreen({super.key});

  @override
  State<MainAnalysisScreen> createState() => _MainAnalysisScreenState();
}

class _MainAnalysisScreenState extends State<MainAnalysisScreen> {
  // 表示モード
  ViewMode _viewMode = ViewMode.splitHorizontal;
  double _ghostOpacity = 0.5;

  // 再生制御状態
  bool _isPlaying = false;
  double _playbackSpeed = 0.25;
  bool _isSyncLocked = true;
  Duration _currentPosition = Duration.zero;
  final Duration _totalDuration = const Duration(seconds: 10);

  // 同期オフセット
  double _offsetSeconds = 0.0;

  // 描画アノテーション状態
  DrawingToolType _activeTool = DrawingToolType.none;
  final List<DrawingObject> _drawingObjects = [];

  // 表示波形系列 (初期値: 加速度3軸 + 加速度合成G)
  Set<WaveformSeries> _selectedWaveforms = {
    WaveformSeries.accelX,
    WaveformSeries.accelY,
    WaveformSeries.accelZ,
    WaveformSeries.accelTotal,
  };

  // サンプルデータ
  late final List<SensorRecord> _sensorRecords;
  late final List<LapRecord> _lapRecords;

  @override
  void initState() {
    super.initState();
    _initSampleData();
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
        tournamentName: '記録会',
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
        tournamentName: '記録会',
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
        tournamentName: '記録会',
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

  void _onStepFrame(int deltaMs) {
    setState(() {
      final newMs = (_currentPosition.inMilliseconds + deltaMs)
          .clamp(0, _totalDuration.inMilliseconds);
      _currentPosition = Duration(milliseconds: newMs);
    });
  }

  void _onSeek(double ms) {
    setState(() {
      _currentPosition = Duration(milliseconds: ms.toInt());
    });
  }

  @override
  Widget build(BuildContext context) {
    // 現在位置に対応するセンサーおよびラップデータを二分探索で瞬時抽出
    final syncPosMs = (_currentPosition.inMilliseconds + (_offsetSeconds * 1000).toInt()).clamp(0, 10000);
    final curSensor = BinarySearchSync.findNearestSensorRecord(_sensorRecords, syncPosMs);
    final curLap = BinarySearchSync.findCurrentLapRecord(_lapRecords, syncPosMs);

    return Scaffold(
      appBar: HeaderBar(
        title: 'MotionSync Analytics (20261102_CH5)',
        currentViewMode: _viewMode,
        onViewModeChanged: (mode) => setState(() => _viewMode = mode),
        onExportImage: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('現在フレームの静止画 (PNG) を書き出しました')),
          );
        },
        onExportVideo: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('合成動画 (MP4) のエンコードを開始しました')),
          );
        },
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. 動画ビューポートエリア (上部)
            Expanded(
              flex: 5,
              child: VideoViewportArea(
                viewMode: _viewMode,
                ghostOpacity: _ghostOpacity,
                onGhostOpacityChanged: (val) => setState(() => _ghostOpacity = val),
                activeTool: _activeTool,
                drawingObjects: _drawingObjects,
                onDrawingAdded: (obj) => setState(() => _drawingObjects.add(obj)),
              ),
            ),

            // 2. 再生制御バー
            PlaybackControlBar(
              isPlaying: _isPlaying,
              playbackSpeed: _playbackSpeed,
              isSyncLocked: _isSyncLocked,
              currentPosition: _currentPosition,
              totalDuration: _totalDuration,
              onPlayPause: () => setState(() => _isPlaying = !_isPlaying),
              onStepBackward: () => _onStepFrame(-33), // 1フレーム (約30fps: 33ms) 戻し
              onStepForward: () => _onStepFrame(33),   // 1フレーム 送り
              onSpeedChanged: (speed) => setState(() => _playbackSpeed = speed),
              onToggleSyncLock: () => setState(() => _isSyncLocked = !_isSyncLocked),
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
                currentPosition: _currentPosition,
                totalDuration: _totalDuration,
                selectedSeries: _selectedWaveforms,
                onSelectedSeriesChanged: (newSet) => setState(() => _selectedWaveforms = newSet),
                onSeek: _onSeek,
              ),
            ),

            // 5. 画面下部ツールバー (オフセット調整・描画パレット)
            BottomToolbar(
              offsetSeconds: _offsetSeconds,
              onOffsetChanged: (offset) => setState(() => _offsetSeconds = offset),
              activeTool: _activeTool,
              onToolChanged: (tool) => setState(() => _activeTool = tool),
              onClearDrawings: () => setState(() => _drawingObjects.clear()),
            ),
          ],
        ),
      ),
    );
  }
}
