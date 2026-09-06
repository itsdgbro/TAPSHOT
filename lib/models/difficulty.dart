/// Difficulty options for 30 Seconds Mode and baseline tuning
enum Difficulty {
  easy,
  medium,
  hard,
}

extension DifficultyExtension on Difficulty {
  String get nameUpper {
    switch (this) {
      case Difficulty.easy:
        return 'EASY';
      case Difficulty.medium:
        return 'MEDIUM';
      case Difficulty.hard:
        return 'HARD';
    }
  }

  String get subtitle {
    switch (this) {
      case Difficulty.easy:
        return 'Large stationary targets, relaxed lifetime.';
      case Difficulty.medium:
        return 'Medium targets, faster pacing, slight target drift.';
      case Difficulty.hard:
        return 'Compact targets, hyper-fast lifetime, active drift.';
    }
  }

  /// Target base radius (in logical pixels)
  double get baseRadius {
    switch (this) {
      case Difficulty.easy:
        return 42.0;
      case Difficulty.medium:
        return 32.0;
      case Difficulty.hard:
        return 24.0;
    }
  }

  /// Maximum target lifetime before expiring (milliseconds)
  int get lifetimeMs {
    switch (this) {
      case Difficulty.easy:
        return 1600;
      case Difficulty.medium:
        return 1100;
      case Difficulty.hard:
        return 750;
    }
  }

  /// Whether targets can drift smoothly across the playable area
  bool get hasMovement {
    switch (this) {
      case Difficulty.easy:
        return false;
      case Difficulty.medium:
        return true;
      case Difficulty.hard:
        return true;
    }
  }

  /// Movement velocity magnitude (pixels/sec)
  double get driftSpeed {
    switch (this) {
      case Difficulty.easy:
        return 0.0;
      case Difficulty.medium:
        return 65.0;
      case Difficulty.hard:
        return 130.0;
    }
  }

  /// Multiplier for score rewards
  double get scoreMultiplier {
    switch (this) {
      case Difficulty.easy:
        return 1.0;
      case Difficulty.medium:
        return 1.5;
      case Difficulty.hard:
        return 2.0;
    }
  }

  String get storageKey => 'high_score_timed_${name.toLowerCase()}';
}
