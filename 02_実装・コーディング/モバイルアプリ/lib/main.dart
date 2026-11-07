import 'package:flutter/material.dart';
import 'ui/theme/app_theme.dart';
import 'ui/main_analysis_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MotionSyncApp());
}

class MotionSyncApp extends StatelessWidget {
  const MotionSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MotionSync Analytics',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const MainAnalysisScreen(),
    );
  }
}
