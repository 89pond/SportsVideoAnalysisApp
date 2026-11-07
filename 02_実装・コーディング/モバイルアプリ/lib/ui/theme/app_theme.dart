import 'package:flutter/material.dart';

/// スポーツ動作・センサーデータ分析用 高コントラスト ダークテーマ
class AppTheme {
  // カラーパレット
  static const Color background = Color(0xFF121418);
  static const Color surface = Color(0xFF1E222B);
  static const Color cardColor = Color(0xFF262C38);
  
  // アクセントカラー
  static const Color primary = Color(0xFF00E5FF);       // シアン (動画A / メイン操作)
  static const Color secondary = Color(0xFFFF5252);     // レッド (動画B / 比較対象)
  static const Color accentGreen = Color(0xFF00E676);   // グリーン (HUD・最速ラップ)
  static const Color accentYellow = Color(0xFFFFD600);  // イエロー (再生ヘッド・角度)
  static const Color accentPurple = Color(0xFF7C4DFF);  // パープル (ゴーストモード)
  
  // グラフ用波形カラー
  static const Color waveX = Color(0xFFFF5252);         // X軸: 赤
  static const Color waveY = Color(0xFF69F0AE);         // Y軸: 緑
  static const Color waveZ = Color(0xFF40C4FF);         // Z軸: 青
  static const Color waveTotal = Color(0xFFFFD740);     // 合成G: 黄

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      cardColor: surface,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        surface: surface,
        background: background,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: primary,
        inactiveTrackColor: Colors.white24,
        thumbColor: primary,
        overlayColor: Color(0x3300E5FF),
      ),
    );
  }
}
