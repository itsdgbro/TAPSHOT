import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tapshot/controllers/game_controller.dart';
import 'package:tapshot/models/app_skin.dart';
import 'package:tapshot/models/difficulty.dart';
import 'package:tapshot/models/game_mode.dart';
import 'package:tapshot/models/target_model.dart';
import 'package:tapshot/services/audio_service.dart';
import 'package:tapshot/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StorageService storageService;
  late AudioService audioService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'high_score_endless': 150,
      'high_score_timed_easy': 200,
    });
    storageService = await StorageService.initialize();
    audioService = AudioService(storageService, isTest: true);
  });

  group('StorageService Unit Tests', () {
    test('Load initial high scores correctly', () {
      expect(storageService.getEndlessHighScore(), equals(150));
      expect(storageService.getTimedHighScore(Difficulty.easy), equals(200));
      expect(storageService.getTimedHighScore(Difficulty.hard), equals(0));
    });

    test('Save higher score updates storage', () async {
      final updated = await storageService.setEndlessHighScore(300);
      expect(updated, isTrue);
      expect(storageService.getEndlessHighScore(), equals(300));

      final rejected = await storageService.setEndlessHighScore(250);
      expect(rejected, isFalse);
      expect(storageService.getEndlessHighScore(), equals(300));
    });

    test('Unlockable skins check according to high scores', () {
      expect(storageService.isSkinUnlocked(AppSkin.volt), isTrue);
      expect(storageService.isSkinUnlocked(AppSkin.cyberpunk), isFalse); // req 300 pts, current high is 200
    });
  });

  group('TargetModel & Physics Tests', () {
    test('Contains tap within radius', () {
      final target = TargetModel(
        id: 't1',
        position: const Offset(100, 100),
        radius: 30,
        velocity: Offset.zero,
        createdAt: DateTime.now(),
        lifetime: const Duration(seconds: 2),
      );

      expect(target.contains(const Offset(100, 100)), isTrue);
      expect(target.contains(const Offset(125, 100)), isTrue);
      expect(target.contains(const Offset(160, 100)), isFalse);
    });

    test('Bounces off bounding box correctly', () {
      final target = TargetModel(
        id: 't2',
        position: const Offset(5, 50),
        radius: 10,
        velocity: const Offset(-100, 0), // Moving left towards edge
        createdAt: DateTime.now(),
        lifetime: const Duration(seconds: 2),
        isMoving: true,
      );

      const bounds = Rect.fromLTWH(0, 0, 200, 200);
      target.updatePosition(0.1, bounds);

      expect(target.velocity.dx, greaterThan(0));
      expect(
        target.position.dx,
        greaterThanOrEqualTo(bounds.left + target.radius),
      );
    });
  });

  group('GameController Gameplay Mechanics Tests', () {
    test('Endless mode starts with 3 lives and spawns target', () {
      final controller = GameController(
        mode: GameMode.endless,
        storageService: storageService,
        audioService: audioService,
      );

      controller.initPlayableArea(const Rect.fromLTWH(0, 0, 300, 600));
      controller.startGame(skipCountdown: true);

      expect(controller.stats.livesRemaining, equals(3));
      expect(controller.stats.score, equals(0));
      expect(controller.stats.combo, equals(0));
      expect(controller.activeTarget, isNotNull);

      controller.dispose();
    });

    test('Tapping active target adds score, reaction time, and increases combo', () {
      final controller = GameController(
        mode: GameMode.endless,
        storageService: storageService,
        audioService: audioService,
      );

      controller.initPlayableArea(const Rect.fromLTWH(0, 0, 300, 600));
      controller.startGame(skipCountdown: true);

      final targetPos = controller.activeTarget!.position;
      controller.handleTap(targetPos);

      expect(controller.stats.hits, equals(1));
      expect(controller.stats.combo, equals(1));
      expect(controller.stats.score, greaterThan(0));
      expect(controller.stats.accuracyPercentage, equals(100));
      expect(controller.stats.averageReactionTimeMs, greaterThanOrEqualTo(0));

      controller.dispose();
    });

    test('Missing decreases lives and resets combo in endless mode', () {
      final controller = GameController(
        mode: GameMode.endless,
        storageService: storageService,
        audioService: audioService,
      );

      controller.initPlayableArea(const Rect.fromLTWH(0, 0, 300, 600));
      controller.startGame(skipCountdown: true);

      // Tap far outside target
      controller.handleTap(const Offset(-100, -100));

      expect(controller.stats.misses, equals(1));
      expect(controller.stats.combo, equals(0));
      expect(controller.stats.livesRemaining, equals(2));

      controller.dispose();
    });
  });
}
