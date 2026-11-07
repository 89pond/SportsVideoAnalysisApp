import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

/// 制御対象の動画スロット識別子
enum VideoSlot { videoA, videoB }

/// デュアル動画同期コントローラー
class DualVideoSyncController extends ChangeNotifier {
  late final Player playerA;
  late final Player playerB;
  VideoController? videoControllerA;
  VideoController? videoControllerB;

  // 再生状態
  bool _isPlaying = false;
  double _playbackSpeed = 1.0;
  bool _isSyncLocked = true;
  VideoSlot _activeSlot = VideoSlot.videoA;

  // タイムスタンプとオフセット
  Duration _positionA = Duration.zero;
  Duration _positionB = Duration.zero;
  Duration _durationA = Duration.zero;
  Duration _durationB = Duration.zero;
  double _manualOffsetSeconds = 0.0;
  Duration _baseSyncOffset = Duration.zero; // ロック時の (posB - posA)

  String? _filePathA;
  String? _filePathB;

  StreamSubscription? _posSubA;
  StreamSubscription? _posSubB;
  StreamSubscription? _durSubA;
  StreamSubscription? _durSubB;

  // ゲッター
  bool get isPlaying => _isPlaying;
  double get playbackSpeed => _playbackSpeed;
  bool get isSyncLocked => _isSyncLocked;
  VideoSlot get activeSlot => _activeSlot;
  Duration get positionA => _positionA;
  Duration get positionB => _positionB;
  Duration get durationA => _durationA;
  Duration get durationB => _durationB;
  double get manualOffsetSeconds => _manualOffsetSeconds;
  String? get filePathA => _filePathA;
  String? get filePathB => _filePathB;
  bool get hasVideoA => _filePathA != null;
  bool get hasVideoB => _filePathB != null;

  /// 表示・基準となる代表ポジション（動画A優先）
  Duration get currentPosition => _positionA;
  Duration get totalDuration => _durationA > Duration.zero ? _durationA : _durationB;

  DualVideoSyncController() {
    _initPlayers();
  }

  void _initPlayers() {
    playerA = Player();
    playerB = Player();

    videoControllerA = VideoController(playerA);
    videoControllerB = VideoController(playerB);

    _durSubA = playerA.stream.duration.listen((d) {
      _durationA = d;
      notifyListeners();
    });

    _durSubB = playerA.stream.duration.listen((d) {
      _durationB = d;
      notifyListeners();
    });

    _posSubA = playerA.stream.position.listen((pos) {
      _positionA = pos;
      notifyListeners();
    });

    _posSubB = playerB.stream.position.listen((pos) {
      _positionB = pos;
      notifyListeners();
    });
  }

  /// 動画Aの読み込み
  Future<void> loadVideoA(String path) async {
    _filePathA = path;
    await playerA.open(Media(path), play: false);
    notifyListeners();
  }

  /// 動画Bの読み込み
  Future<void> loadVideoB(String path) async {
    _filePathB = path;
    await playerB.open(Media(path), play: false);
    notifyListeners();
  }

  /// アクティブ操作対象スロットの切り替え (個別調整時)
  void setActiveSlot(VideoSlot slot) {
    _activeSlot = slot;
    notifyListeners();
  }

  /// 同期ロック / 個別アンロック の切り替え
  void toggleSyncLock() {
    _isSyncLocked = !_isSyncLocked;
    if (_isSyncLocked) {
      // ロックされた瞬間の基準オフセットを固定
      _baseSyncOffset = _positionB - _positionA;
    }
    notifyListeners();
  }

  /// 手動オフセット微調整 (±0.01s, ±0.05s)
  void setManualOffset(double offsetSec) {
    _manualOffsetSeconds = offsetSec;
    if (_isSyncLocked) {
      _syncPlayerBToA();
    }
    notifyListeners();
  }

  void adjustManualOffset(double deltaSec) {
    setManualOffset(_manualOffsetSeconds + deltaSec);
  }

  /// 再生 / 一時停止 トグル
  Future<void> playOrPause() async {
    if (_isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  /// 再生開始
  Future<void> play() async {
    _isPlaying = true;
    if (_isSyncLocked) {
      _syncPlayerBToA();
      await playerA.setRate(_playbackSpeed);
      await playerB.setRate(_playbackSpeed);
      await playerA.play();
      await playerB.play();
    } else {
      final p = _activeSlot == VideoSlot.videoA ? playerA : playerB;
      await p.setRate(_playbackSpeed);
      await p.play();
    }
    notifyListeners();
  }

  /// 一時停止
  Future<void> pause() async {
    _isPlaying = false;
    await playerA.pause();
    await playerB.pause();
    notifyListeners();
  }

  /// 再生速度の変更 (0.1x〜1.0x)
  Future<void> setSpeed(double speed) async {
    _playbackSpeed = speed;
    await playerA.setRate(speed);
    await playerB.setRate(speed);
    notifyListeners();
  }

  /// 1フレームコマ送り (進む)
  Future<void> stepForward({int frameMs = 33}) async {
    await pause();
    if (_isSyncLocked) {
      await seekRelative(frameMs);
    } else {
      final p = _activeSlot == VideoSlot.videoA ? playerA : playerB;
      final cur = _activeSlot == VideoSlot.videoA ? _positionA : _positionB;
      await p.seek(cur + Duration(milliseconds: frameMs));
    }
  }

  /// 1フレームコマ戻し (戻る)
  Future<void> stepBackward({int frameMs = 33}) async {
    await pause();
    if (_isSyncLocked) {
      await seekRelative(-frameMs);
    } else {
      final p = _activeSlot == VideoSlot.videoA ? playerA : playerB;
      final cur = _activeSlot == VideoSlot.videoA ? _positionA : _positionB;
      final newPos = cur - Duration(milliseconds: frameMs);
      await p.seek(newPos < Duration.zero ? Duration.zero : newPos);
    }
  }

  /// 相対シーク
  Future<void> seekRelative(int deltaMs) async {
    final targetA = _positionA + Duration(milliseconds: deltaMs);
    await seek(targetA < Duration.zero ? Duration.zero : targetA);
  }

  /// 絶対シーク
  Future<void> seek(Duration targetA) async {
    _positionA = targetA;
    await playerA.seek(targetA);

    if (_isSyncLocked) {
      await _syncPlayerBToA();
    }
    notifyListeners();
  }

  /// 動画Aの位置に合わせて動画Bをオフセット同期
  Future<void> _syncPlayerBToA() async {
    final manualMs = (_manualOffsetSeconds * 1000).round();
    final targetBMs = _positionA.inMilliseconds + _baseSyncOffset.inMilliseconds + manualMs;
    final clampedBMs = targetBMs.clamp(0, _durationB.inMilliseconds > 0 ? _durationB.inMilliseconds : 1000000);
    _positionB = Duration(milliseconds: clampedBMs);
    await playerB.seek(_positionB);
  }

  @override
  void dispose() {
    _posSubA?.cancel();
    _posSubB?.cancel();
    _durSubA?.cancel();
    _durSubB?.cancel();
    playerA.dispose();
    playerB.dispose();
    super.dispose();
  }
}
