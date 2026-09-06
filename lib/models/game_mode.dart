/// Identifies the game mode in TAPSHOT
enum GameMode {
  endless,
  timed,
}

extension GameModeExtension on GameMode {
  String get title {
    switch (this) {
      case GameMode.endless:
        return 'ENDLESS';
      case GameMode.timed:
        return '30 SECONDS';
    }
  }

  String get description {
    switch (this) {
      case GameMode.endless:
        return '3 Lives. Dynamic speed & size scaling. How long can you survive?';
      case GameMode.timed:
        return '30-second speed test. Tap as many targets as you can before time expires.';
    }
  }

  String get keyPrefix {
    switch (this) {
      case GameMode.endless:
        return 'high_score_endless';
      case GameMode.timed:
        return 'high_score_timed';
    }
  }
}
