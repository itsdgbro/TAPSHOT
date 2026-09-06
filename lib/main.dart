import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/home_screen.dart';
import 'services/audio_service.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait orientation for standard mobile aim trainer experience
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set immersive dark system UI overlay
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize storage service
  final storageService = await StorageService.initialize();
  final audioService = AudioService(storageService);

  runApp(
    TapShotApp(storageService: storageService, audioService: audioService),
  );
}

class TapShotApp extends StatelessWidget {
  final StorageService storageService;
  final AudioService audioService;

  const TapShotApp({
    super.key,
    required this.storageService,
    required this.audioService,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TAPSHOT',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.themeData,
      home: HomeScreen(
        storageService: storageService,
        audioService: audioService,
      ),
    );
  }
}
