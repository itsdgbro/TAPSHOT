import 'game_mode.dart';
import 'difficulty.dart';

/// GameStats captures all real-time and post-game metrics for the session
class GameStats {
  final GameMode mode;
  final Difficulty? difficulty;
  final int score;
  final int combo;
  final int maxCombo;
  final int hits;
  final int misses;
  final int livesRemaining;
  final double timeRemaining;
  final bool isNewHighScore;
  final int previousHighScore;
  final int averageReactionTimeMs;
  final int bestReactionTimeMs;
  final bool isFrenzy;

  const GameStats({
    required this.mode,
    this.difficulty,
    this.score = 0,
    this.combo = 0,
    this.maxCombo = 0,
    this.hits = 0,
    this.misses = 0,
    this.livesRemaining = 3,
    this.timeRemaining = 30.0,
    this.isNewHighScore = false,
    this.previousHighScore = 0,
    this.averageReactionTimeMs = 0,
    this.bestReactionTimeMs = 0,
    this.isFrenzy = false,
  });

  /// Total tap attempts (hits + misses)
  int get totalAttempts => hits + misses;

  /// Accuracy percentage as integer (0 - 100)
  int get accuracyPercentage {
    if (totalAttempts == 0) return 0;
    return ((hits / totalAttempts) * 100).round();
  }

  GameStats copyWith({
    GameMode? mode,
    Difficulty? difficulty,
    int? score,
    int? combo,
    int? maxCombo,
    int? hits,
    int? misses,
    int? livesRemaining,
    double? timeRemaining,
    bool? isNewHighScore,
    int? previousHighScore,
    int? averageReactionTimeMs,
    int? bestReactionTimeMs,
    bool? isFrenzy,
  }) {
    return GameStats(
      mode: mode ?? this.mode,
      difficulty: difficulty ?? this.difficulty,
      score: score ?? this.score,
      combo: combo ?? this.combo,
      maxCombo: maxCombo ?? this.maxCombo,
      hits: hits ?? this.hits,
      misses: misses ?? this.misses,
      livesRemaining: livesRemaining ?? this.livesRemaining,
      timeRemaining: timeRemaining ?? this.timeRemaining,
      isNewHighScore: isNewHighScore ?? this.isNewHighScore,
      previousHighScore: previousHighScore ?? this.previousHighScore,
      averageReactionTimeMs: averageReactionTimeMs ?? this.averageReactionTimeMs,
      bestReactionTimeMs: bestReactionTimeMs ?? this.bestReactionTimeMs,
      isFrenzy: isFrenzy ?? this.isFrenzy,
    );
  }
}
