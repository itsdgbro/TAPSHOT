import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/app_skin.dart';
import '../models/difficulty.dart';
import '../models/game_mode.dart';
import '../models/game_stats.dart';
import '../models/target_model.dart';
import '../services/audio_service.dart';
import '../services/storage_service.dart';

/// Event model for floating score feedback and particle effects
class ScorePopup {
  final String id;
  final Offset position;
  final String text;
  final Color color;

  ScorePopup({
    required this.id,
    required this.position,
    required this.text,
    required this.color,
  });
}

class MissPopup {
  final String id;
  final Offset position;

  MissPopup({
    required this.id,
    required this.position,
  });
}

/// GameController drives the active gameplay loop, countdown gate, reaction time tracking,
/// frenzy streaks, physics ticker, dynamic difficulty ramp-up, and game over sequences.
class GameController extends ChangeNotifier {
  final GameMode mode;
  final Difficulty? difficulty;
  final StorageService storageService;
  final AudioService audioService;
  final AppSkin skin;

  GameController({
    required this.mode,
    this.difficulty,
    required this.storageService,
    required this.audioService,
    AppSkin? skin,
  }) : skin = skin ?? storageService.getSelectedSkin();

  // State
  GameStats _stats = const GameStats(mode: GameMode.endless);
  GameStats get stats => _stats;

  TargetModel? _activeTarget;
  TargetModel? get activeTarget => _activeTarget;

  final List<ScorePopup> _scorePopups = [];
  List<ScorePopup> get scorePopups => List.unmodifiable(_scorePopups);

  final List<MissPopup> _missPopups = [];
  List<MissPopup> get missPopups => List.unmodifiable(_missPopups);

  bool _isGameOver = false;
  bool get isGameOver => _isGameOver;

  bool _isPaused = false;
  bool get isPaused => _isPaused;

  int _countdownNumber = 3; // 3, 2, 1, 0 (Started)
  int get countdownNumber => _countdownNumber;
  bool get isCountingDown => _countdownNumber > 0;

  Rect _playableArea = Rect.zero;
  Timer? _countdownTimer;
  Timer? _gameTimer;
  Timer? _ticker;
  final math.Random _random = math.Random();
  int _targetCounter = 0;
  DateTime _lastFrameTime = DateTime.now();

  // Reaction Time tracker metrics
  final List<int> _reactionTimes = [];

  /// Call once when the game arena layout size is established
  void initPlayableArea(Rect area) {
    _playableArea = area;
  }

  /// Starts or restarts a game session with 3-2-1 countdown
  void startGame({bool skipCountdown = false}) {
    _cleanupTimers();

    final previousHigh = mode == GameMode.endless
        ? storageService.getEndlessHighScore()
        : storageService.getTimedHighScore(difficulty ?? Difficulty.medium);

    _stats = GameStats(
      mode: mode,
      difficulty: difficulty,
      score: 0,
      combo: 0,
      maxCombo: 0,
      hits: 0,
      misses: 0,
      livesRemaining: mode == GameMode.endless ? 3 : 0,
      timeRemaining: 30.0,
      isNewHighScore: false,
      previousHighScore: previousHigh,
      averageReactionTimeMs: 0,
      bestReactionTimeMs: 0,
      isFrenzy: false,
    );
    _isGameOver = false;
    _isPaused = false;
    _activeTarget = null;
    _scorePopups.clear();
    _missPopups.clear();
    _reactionTimes.clear();

    if (skipCountdown) {
      _countdownNumber = 0;
      _startActiveGameplay();
    } else {
      _countdownNumber = 3;
      audioService.playUiClick();
      _countdownTimer = Timer.periodic(const Duration(milliseconds: 700), (timer) {
        _countdownNumber--;
        if (_countdownNumber > 0) {
          audioService.playUiClick();
        } else {
          _countdownTimer?.cancel();
          _countdownTimer = null;
          audioService.playHit();
          _startActiveGameplay();
        }
        notifyListeners();
      });
    }

    notifyListeners();
  }

  void _startActiveGameplay() {
    _spawnNextTarget();

    _lastFrameTime = DateTime.now();
    // 60fps high precision game loop
    _ticker = Timer.periodic(const Duration(milliseconds: 16), _onTick);

    // 30s Countdown timer for Timed mode
    if (mode == GameMode.timed) {
      _gameTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
        if (_isGameOver || _isPaused || isCountingDown) return;
        final newTime = math.max(0.0, _stats.timeRemaining - 0.1);
        _stats = _stats.copyWith(timeRemaining: newTime);
        if (newTime <= 0.001) {
          _endGame();
        }
        notifyListeners();
      });
    }
  }

  void _onTick(Timer timer) {
    if (_isGameOver || _isPaused || isCountingDown) return;

    final now = DateTime.now();
    final dtSeconds = (now.difference(_lastFrameTime).inMicroseconds) / 1000000.0;
    _lastFrameTime = now;

    if (_activeTarget != null) {
      // Check target lifetime expiration
      if (_activeTarget!.isExpired(now)) {
        _handleTargetTimeout();
      } else {
        // Drift and bounce physics
        _activeTarget!.updatePosition(dtSeconds, _playableArea);
      }
      notifyListeners();
    }
  }

  /// Calculates dynamic target attributes based on mode & current score/combo
  void _spawnNextTarget() {
    if (_isGameOver || _playableArea.width <= 0 || _playableArea.height <= 0) return;

    _targetCounter++;
    final double radius;
    final int lifetimeMs;
    final bool isMoving;
    final double driftSpeed;

    if (mode == GameMode.timed) {
      final diff = difficulty ?? Difficulty.medium;
      radius = diff.baseRadius;
      lifetimeMs = diff.lifetimeMs;
      isMoving = diff.hasMovement;
      driftSpeed = diff.driftSpeed;
    } else {
      // Dynamic scaling for Endless Mode:
      // Starts generous (r=42, life=1600ms), gradually ramps down to razor precision (r=22, life=700ms)
      final rampFactor = math.min(1.0, _stats.score / 2500.0);
      radius = (42.0 - (rampFactor * 20.0)).clamp(22.0, 42.0);
      lifetimeMs = (1600 - (rampFactor * 900)).round().clamp(700, 1600);

      // Moving targets activate after score reaches 300 or combo >= 5
      isMoving = _stats.score >= 300 || _stats.combo >= 5;
      driftSpeed = isMoving ? (50.0 + (rampFactor * 90.0)) : 0.0;
    }

    // Safe random position within playable bounds
    final minX = _playableArea.left + radius + 10;
    final maxX = _playableArea.right - radius - 10;
    final minY = _playableArea.top + radius + 10;
    final maxY = _playableArea.bottom - radius - 10;

    final posX = minX >= maxX ? (_playableArea.left + _playableArea.width / 2) : minX + _random.nextDouble() * (maxX - minX);
    final posY = minY >= maxY ? (_playableArea.top + _playableArea.height / 2) : minY + _random.nextDouble() * (maxY - minY);

    // Random velocity vector if moving
    Offset velocity = Offset.zero;
    if (isMoving && driftSpeed > 0) {
      final angle = _random.nextDouble() * 2 * math.pi;
      velocity = Offset(math.cos(angle) * driftSpeed, math.sin(angle) * driftSpeed);
    }

    _activeTarget = TargetModel(
      id: 'target_$_targetCounter',
      position: Offset(posX, posY),
      radius: radius,
      velocity: velocity,
      createdAt: DateTime.now(),
      lifetime: Duration(milliseconds: lifetimeMs),
      isMoving: isMoving,
    );

    notifyListeners();
  }

  /// Handles when target expires before player taps it
  void _handleTargetTimeout() {
    if (_activeTarget == null) return;
    final expiredPos = _activeTarget!.position;
    _activeTarget = null;

    final newMisses = _stats.misses + 1;
    final newCombo = 0;
    int newLives = _stats.livesRemaining;

    if (mode == GameMode.endless) {
      newLives = math.max(0, _stats.livesRemaining - 1);
    }

    _missPopups.add(MissPopup(id: 'miss_${DateTime.now().millisecondsSinceEpoch}', position: expiredPos));
    audioService.playMiss();

    _stats = _stats.copyWith(
      misses: newMisses,
      combo: newCombo,
      livesRemaining: newLives,
      isFrenzy: false,
    );

    if (mode == GameMode.endless && newLives <= 0) {
      _endGame();
    } else {
      _spawnNextTarget();
    }
    notifyListeners();
  }

  /// Handles screen tap
  void handleTap(Offset tapPos) {
    if (_isGameOver || _isPaused || isCountingDown) return;

    if (_activeTarget != null && _activeTarget!.contains(tapPos)) {
      _handleHit(_activeTarget!, tapPos);
    } else {
      _handleMiss(tapPos);
    }
  }

  void _handleHit(TargetModel target, Offset tapPos) {
    final now = DateTime.now();
    final targetPos = target.position;
    final reactionMs = now.difference(target.createdAt).inMilliseconds;
    _reactionTimes.add(reactionMs);

    _activeTarget = null;

    final newHits = _stats.hits + 1;
    final newCombo = _stats.combo + 1;
    final newMaxCombo = math.max(_stats.maxCombo, newCombo);
    final isFrenzy = newCombo >= 10;

    // Reaction time calculation
    final avgReaction = (_reactionTimes.reduce((a, b) => a + b) / _reactionTimes.length).round();
    final bestReaction = _reactionTimes.reduce((a, b) => a < b ? a : b);

    // Scoring formula: Base points (10) * combo multiplier * difficulty multiplier * frenzy bonus (2x)
    final diffMultiplier = mode == GameMode.timed ? (difficulty?.scoreMultiplier ?? 1.0) : (1.0 + (_stats.score / 3000.0));
    final comboBonus = (newCombo > 1) ? (newCombo * 5) : 0;
    final frenzyMultiplier = isFrenzy ? 2.0 : 1.0;
    final pointsEarned = (((10 + comboBonus) * diffMultiplier) * frenzyMultiplier).round();
    final newScore = _stats.score + pointsEarned;

    // Floating score animation
    final popupText = isFrenzy
        ? '+$pointsEarned 🔥FRENZY!'
        : (newCombo > 2 ? '+$pointsEarned (×$newCombo)' : '+$pointsEarned');
        
    final popupColor = isFrenzy
        ? const Color(0xFFFF2A4B)
        : (newCombo >= 5 ? skin.secondaryAccent : skin.primaryAccent);
    
    _scorePopups.add(ScorePopup(
      id: 'score_${DateTime.now().millisecondsSinceEpoch}',
      position: targetPos,
      text: popupText,
      color: popupColor,
    ));

    audioService.playHit(combo: newCombo);

    _stats = _stats.copyWith(
      score: newScore,
      hits: newHits,
      combo: newCombo,
      maxCombo: newMaxCombo,
      averageReactionTimeMs: avgReaction,
      bestReactionTimeMs: bestReaction,
      isFrenzy: isFrenzy,
    );

    _spawnNextTarget();
    notifyListeners();
  }

  void _handleMiss(Offset tapPos) {
    final newMisses = _stats.misses + 1;
    final newCombo = 0;
    int newLives = _stats.livesRemaining;

    if (mode == GameMode.endless) {
      newLives = math.max(0, _stats.livesRemaining - 1);
    }

    _missPopups.add(MissPopup(id: 'miss_${DateTime.now().millisecondsSinceEpoch}', position: tapPos));
    audioService.playMiss();

    _stats = _stats.copyWith(
      misses: newMisses,
      combo: newCombo,
      livesRemaining: newLives,
      isFrenzy: false,
    );

    if (mode == GameMode.endless && newLives <= 0) {
      _endGame();
    }
    notifyListeners();
  }

  void removeScorePopup(String id) {
    _scorePopups.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  void removeMissPopup(String id) {
    _missPopups.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  /// Finishes game session, logs performance history, and commits high scores
  Future<void> _endGame() async {
    if (_isGameOver) return;
    _isGameOver = true;
    _cleanupTimers();

    bool isNewHigh = false;
    if (mode == GameMode.endless) {
      isNewHigh = await storageService.setEndlessHighScore(_stats.score);
    } else {
      isNewHigh = await storageService.setTimedHighScore(difficulty ?? Difficulty.medium, _stats.score);
    }

    // Save offline session record
    final record = GameRecord(
      score: _stats.score,
      accuracy: _stats.accuracyPercentage,
      avgReactionMs: _stats.averageReactionTimeMs,
      modeName: mode == GameMode.endless ? 'ENDLESS' : '30s ${(difficulty ?? Difficulty.medium).nameUpper}',
      timestamp: DateTime.now(),
    );
    await storageService.addGameRecord(record);

    _stats = _stats.copyWith(isNewHighScore: isNewHigh);
    audioService.playGameOver(isHighScore: isNewHigh);
    notifyListeners();
  }

  void pauseGame() {
    _isPaused = true;
    notifyListeners();
  }

  void resumeGame() {
    _isPaused = false;
    _lastFrameTime = DateTime.now();
    notifyListeners();
  }

  void _cleanupTimers() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _ticker?.cancel();
    _ticker = null;
    _gameTimer?.cancel();
    _gameTimer = null;
  }

  @override
  void dispose() {
    _cleanupTimers();
    super.dispose();
  }
}
