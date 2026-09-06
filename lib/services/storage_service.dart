import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_skin.dart';
import '../models/difficulty.dart';

/// Performance history record for sparklines and progress tracking
class GameRecord {
  final int score;
  final int accuracy;
  final int avgReactionMs;
  final String modeName;
  final DateTime timestamp;

  GameRecord({
    required this.score,
    required this.accuracy,
    required this.avgReactionMs,
    required this.modeName,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'score': score,
        'accuracy': accuracy,
        'avgReactionMs': avgReactionMs,
        'modeName': modeName,
        'timestamp': timestamp.toIso8601String(),
      };

  factory GameRecord.fromJson(Map<String, dynamic> json) => GameRecord(
        score: json['score'] as int? ?? 0,
        accuracy: json['accuracy'] as int? ?? 0,
        avgReactionMs: json['avgReactionMs'] as int? ?? 0,
        modeName: json['modeName'] as String? ?? 'ENDLESS',
        timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
      );
}

/// StorageService persists high scores, themes, and game records completely offline
class StorageService {
  static const String _keyEndlessHighScore = 'high_score_endless';
  static const String _keySoundEnabled = 'setting_sound_enabled';
  static const String _keyHapticsEnabled = 'setting_haptics_enabled';
  static const String _keySelectedSkin = 'setting_selected_skin';
  static const String _keyGameHistory = 'game_history_records';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  // High Scores
  int getEndlessHighScore() {
    return _prefs.getInt(_keyEndlessHighScore) ?? 0;
  }

  Future<bool> setEndlessHighScore(int score) async {
    final current = getEndlessHighScore();
    if (score > current) {
      await _prefs.setInt(_keyEndlessHighScore, score);
      return true;
    }
    return false;
  }

  int getTimedHighScore(Difficulty difficulty) {
    return _prefs.getInt(difficulty.storageKey) ?? 0;
  }

  Future<bool> setTimedHighScore(Difficulty difficulty, int score) async {
    final current = getTimedHighScore(difficulty);
    if (score > current) {
      await _prefs.setInt(difficulty.storageKey, score);
      return true;
    }
    return false;
  }

  int getBestOverallScore() {
    final endless = getEndlessHighScore();
    final timed = getBestOverallTimedHighScore();
    return endless > timed ? endless : timed;
  }

  int getBestOverallTimedHighScore() {
    final easy = getTimedHighScore(Difficulty.easy);
    final medium = getTimedHighScore(Difficulty.medium);
    final hard = getTimedHighScore(Difficulty.hard);
    return [easy, medium, hard].reduce((curr, next) => curr > next ? curr : next);
  }

  // Active Skin / Theme
  AppSkin getSelectedSkin() {
    final skinIndex = _prefs.getInt(_keySelectedSkin) ?? 0;
    if (skinIndex >= 0 && skinIndex < AppSkin.values.length) {
      return AppSkin.values[skinIndex];
    }
    return AppSkin.volt;
  }

  Future<void> setSelectedSkin(AppSkin skin) async {
    await _prefs.setInt(_keySelectedSkin, skin.index);
  }

  bool isSkinUnlocked(AppSkin skin) {
    final best = getBestOverallScore();
    return best >= skin.unlockScoreRequirement;
  }

  // History Records (Last 10 sessions)
  List<GameRecord> getHistoryRecords() {
    final rawList = _prefs.getStringList(_keyGameHistory) ?? [];
    return rawList
        .map((item) {
          try {
            return GameRecord.fromJson(jsonDecode(item) as Map<String, dynamic>);
          } catch (_) {
            return null;
          }
        })
        .whereType<GameRecord>()
        .toList();
  }

  Future<void> addGameRecord(GameRecord record) async {
    final records = getHistoryRecords();
    records.insert(0, record);
    // Keep last 10 records
    final trimmed = records.take(10).toList();
    final rawList = trimmed.map((r) => jsonEncode(r.toJson())).toList();
    await _prefs.setStringList(_keyGameHistory, rawList);
  }

  // Settings
  bool isSoundEnabled() {
    return _prefs.getBool(_keySoundEnabled) ?? true;
  }

  Future<void> setSoundEnabled(bool enabled) async {
    await _prefs.setBool(_keySoundEnabled, enabled);
  }

  bool isHapticsEnabled() {
    return _prefs.getBool(_keyHapticsEnabled) ?? true;
  }

  Future<void> setHapticsEnabled(bool enabled) async {
    await _prefs.setBool(_keyHapticsEnabled, enabled);
  }

  /// Clears all local high scores and history
  Future<void> resetHighScores() async {
    await _prefs.remove(_keyEndlessHighScore);
    for (final diff in Difficulty.values) {
      await _prefs.remove(diff.storageKey);
    }
    await _prefs.remove(_keyGameHistory);
  }
}
