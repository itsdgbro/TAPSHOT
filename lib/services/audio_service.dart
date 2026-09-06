import 'dart:math' as math;
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'storage_service.dart';

/// AudioService handles procedural synthetic SFX generation & haptic feedback.
/// Procedural PCM wave synthesis ensures zero external asset dependencies, zero missing audio errors,
/// and instantaneous, low-latency audio response on Android & iOS.
class AudioService {
  final StorageService _storageService;
  final AudioPlayer? _customPlayer;
  AudioPlayer? _player;
  bool _playerInitAttempted = false;

  AudioService(this._storageService, {AudioPlayer? player, bool isTest = false})
      : _customPlayer = player {
    if (isTest) {
      _playerInitAttempted = true;
    }
  }

  AudioPlayer? _getOrCreatePlayer() {
    if (_customPlayer != null) return _customPlayer;
    if (_player != null) return _player;
    if (_playerInitAttempted) return null;

    _playerInitAttempted = true;
    if (WidgetsBinding.instance is! WidgetsFlutterBinding) {
      return null;
    }

    try {
      final p = AudioPlayer();
      p.setReleaseMode(ReleaseMode.stop);
      _player = p;
      return _player;
    } catch (_) {
      return null;
    }
  }

  /// Synthesizes a snappy high-frequency PCM WAV beep/click for target hits
  static final Uint8List _hitWav = _generateBeepWav(frequency: 880, durationMs: 45, volume: 0.6);

  /// Synthesizes an amplified combo milestone chord
  static final Uint8List _comboWav = _generateChordWav(freqs: [660, 880, 1100], durationMs: 90, volume: 0.7);

  /// Synthesizes a low-pitch dull thump for misses
  static final Uint8List _missWav = _generateBeepWav(frequency: 180, durationMs: 90, volume: 0.5);

  /// Synthesizes an end game fanfare/buzzer
  static final Uint8List _gameOverWav = _generateChordWav(freqs: [440, 370, 310, 220], durationMs: 250, volume: 0.8);

  /// Synthesizes a new high score victory chime
  static final Uint8List _highScoreWav = _generateArpeggioWav(freqs: [523, 659, 784, 1046], durationMs: 350, volume: 0.85);

  /// Plays hit sound & light haptic pulse
  Future<void> playHit({int combo = 1}) async {
    if (_storageService.isHapticsEnabled()) {
      try {
        HapticFeedback.lightImpact();
      } catch (_) {}
    }
    if (_storageService.isSoundEnabled()) {
      final p = _getOrCreatePlayer();
      if (p != null) {
        try {
          if (combo > 1 && combo % 5 == 0) {
            await p.play(BytesSource(_comboWav));
          } else {
            await p.play(BytesSource(_hitWav));
          }
        } catch (_) {}
      }
    }
  }

  /// Plays miss feedback & medium/heavy haptic pulse
  Future<void> playMiss() async {
    if (_storageService.isHapticsEnabled()) {
      try {
        HapticFeedback.mediumImpact();
      } catch (_) {}
    }
    if (_storageService.isSoundEnabled()) {
      final p = _getOrCreatePlayer();
      if (p != null) {
        try {
          await p.play(BytesSource(_missWav));
        } catch (_) {}
      }
    }
  }

  /// Plays Game Over audio & heavy haptic feedback
  Future<void> playGameOver({bool isHighScore = false}) async {
    if (_storageService.isHapticsEnabled()) {
      try {
        HapticFeedback.heavyImpact();
      } catch (_) {}
    }
    if (_storageService.isSoundEnabled()) {
      final p = _getOrCreatePlayer();
      if (p != null) {
        try {
          if (isHighScore) {
            await p.play(BytesSource(_highScoreWav));
          } else {
            await p.play(BytesSource(_gameOverWav));
          }
        } catch (_) {}
      }
    }
  }

  /// UI Click sound & selection haptic
  Future<void> playUiClick() async {
    if (_storageService.isHapticsEnabled()) {
      try {
        HapticFeedback.selectionClick();
      } catch (_) {}
    }
    if (_storageService.isSoundEnabled()) {
      final p = _getOrCreatePlayer();
      if (p != null) {
        try {
          await p.play(BytesSource(_hitWav));
        } catch (_) {}
      }
    }
  }

  void dispose() {
    _player?.dispose();
    _customPlayer?.dispose();
  }

  // --- Procedural PCM Wave Synthesizer (16-bit 22050Hz Mono WAV) ---

  static Uint8List _generateBeepWav({
    required double frequency,
    required int durationMs,
    required double volume,
  }) {
    const sampleRate = 22050;
    final numSamples = (sampleRate * (durationMs / 1000.0)).round();
    final dataSize = numSamples * 2;
    final buffer = ByteData(44 + dataSize);

    // RIFF header
    _writeString(buffer, 0, 'RIFF');
    buffer.setUint32(4, 36 + dataSize, Endian.little);
    _writeString(buffer, 8, 'WAVE');
    _writeString(buffer, 12, 'fmt ');
    buffer.setUint32(16, 16, Endian.little); // Subchunk1Size (16 for PCM)
    buffer.setUint16(20, 1, Endian.little);  // AudioFormat (1 for PCM)
    buffer.setUint16(22, 1, Endian.little);  // NumChannels (1 mono)
    buffer.setUint32(24, sampleRate, Endian.little);
    buffer.setUint32(28, sampleRate * 2, Endian.little); // ByteRate
    buffer.setUint16(32, 2, Endian.little);  // BlockAlign
    buffer.setUint16(34, 16, Endian.little); // BitsPerSample
    _writeString(buffer, 36, 'data');
    buffer.setUint32(40, dataSize, Endian.little);

    for (int i = 0; i < numSamples; i++) {
      final t = i / sampleRate;
      // Envelope: quick attack, exponential decay
      final decay = math.exp(-6.0 * (i / numSamples));
      final sample = math.sin(2 * math.pi * frequency * t) * volume * decay;
      final intSample = (sample.clamp(-1.0, 1.0) * 32767).round();
      buffer.setInt16(44 + i * 2, intSample, Endian.little);
    }

    return buffer.buffer.asUint8List();
  }

  static Uint8List _generateChordWav({
    required List<double> freqs,
    required int durationMs,
    required double volume,
  }) {
    const sampleRate = 22050;
    final numSamples = (sampleRate * (durationMs / 1000.0)).round();
    final dataSize = numSamples * 2;
    final buffer = ByteData(44 + dataSize);

    _writeString(buffer, 0, 'RIFF');
    buffer.setUint32(4, 36 + dataSize, Endian.little);
    _writeString(buffer, 8, 'WAVE');
    _writeString(buffer, 12, 'fmt ');
    buffer.setUint32(16, 16, Endian.little);
    buffer.setUint16(20, 1, Endian.little);
    buffer.setUint16(22, 1, Endian.little);
    buffer.setUint32(24, sampleRate, Endian.little);
    buffer.setUint32(28, sampleRate * 2, Endian.little);
    buffer.setUint16(32, 2, Endian.little);
    buffer.setUint16(34, 16, Endian.little);
    _writeString(buffer, 36, 'data');
    buffer.setUint32(40, dataSize, Endian.little);

    for (int i = 0; i < numSamples; i++) {
      final t = i / sampleRate;
      final decay = math.exp(-4.0 * (i / numSamples));
      double sum = 0;
      for (final f in freqs) {
        sum += math.sin(2 * math.pi * f * t);
      }
      final sample = (sum / freqs.length) * volume * decay;
      final intSample = (sample.clamp(-1.0, 1.0) * 32767).round();
      buffer.setInt16(44 + i * 2, intSample, Endian.little);
    }

    return buffer.buffer.asUint8List();
  }

  static Uint8List _generateArpeggioWav({
    required List<double> freqs,
    required int durationMs,
    required double volume,
  }) {
    const sampleRate = 22050;
    final numSamples = (sampleRate * (durationMs / 1000.0)).round();
    final dataSize = numSamples * 2;
    final buffer = ByteData(44 + dataSize);

    _writeString(buffer, 0, 'RIFF');
    buffer.setUint32(4, 36 + dataSize, Endian.little);
    _writeString(buffer, 8, 'WAVE');
    _writeString(buffer, 12, 'fmt ');
    buffer.setUint32(16, 16, Endian.little);
    buffer.setUint16(20, 1, Endian.little);
    buffer.setUint16(22, 1, Endian.little);
    buffer.setUint32(24, sampleRate, Endian.little);
    buffer.setUint32(28, sampleRate * 2, Endian.little);
    buffer.setUint16(32, 2, Endian.little);
    buffer.setUint16(34, 16, Endian.little);
    _writeString(buffer, 36, 'data');
    buffer.setUint32(40, dataSize, Endian.little);

    final samplesPerNote = numSamples ~/ freqs.length;
    for (int i = 0; i < numSamples; i++) {
      final noteIndex = (i ~/ samplesPerNote).clamp(0, freqs.length - 1);
      final freq = freqs[noteIndex];
      final noteSampleIndex = i % samplesPerNote;
      final t = i / sampleRate;
      final decay = math.exp(-3.5 * (noteSampleIndex / samplesPerNote));
      final sample = math.sin(2 * math.pi * freq * t) * volume * decay;
      final intSample = (sample.clamp(-1.0, 1.0) * 32767).round();
      buffer.setInt16(44 + i * 2, intSample, Endian.little);
    }

    return buffer.buffer.asUint8List();
  }

  static void _writeString(ByteData buffer, int offset, String text) {
    for (int i = 0; i < text.length; i++) {
      buffer.setUint8(offset + i, text.codeUnitAt(i));
    }
  }
}
